extends Node
## Autoload: FarmPlotManager
##
## Agriculture (#13): seasonal planting/watering/harvesting, growth-cycle
## timers keyed off TimeManager's day clock, regrowth for regrowable
## crops, and a normal/silver/gold quality-tier roll on harvest. Depends
## on the Time & Stamina foundation (TimeManager, already merged).
##
## Harvested items go into InventoryManager (#13's own gap-fill, see that
## autoload's docstring) -- this manager never calls ShippingBinManager
## directly. Selling is "player pulls from inventory, ships it" (see
## InventoryManager.sell_item), not something crop/tile logic shortcuts.
##
## Content pass (#53): a fuller seasonal crop roster replacing the original
## 3-crop MVP placeholder (parsnip/tomato/pumpkin only). Two crops per
## Spring/Summer/Fall plus one Winter-viable crop (Winter is a real season
## per TimeManager.SEASONS, previously unused by Agriculture). Sell prices
## scale with days_to_grow -- roughly 9-13 gold/day for a single-harvest
## crop, with regrowable crops (tomato, corn) priced lower on their first
## harvest but higher on the sustained regrow_days cycle, mirroring SDV's
## own "regrowables trade a slower start for a faster repeat" precedent.
## Quality-tier odds/multipliers below are still placeholder balance (no
## quality economy design exists in the doc) -- content pass leaves those
## untouched, only the crop roster and prices are in scope here.

signal crop_planted(position: Vector2i, crop_id: String)
signal crop_watered(position: Vector2i)
signal crop_harvested(position: Vector2i, item_id: String, quality: String, quantity: int)
signal crop_withered(position: Vector2i, crop_id: String) ## fires when a planted crop's season ends before harvest

const QUALITY_NORMAL := "normal"
const QUALITY_SILVER := "silver"
const QUALITY_GOLD := "gold"

## Placeholder quality odds (percent) and sell-price multipliers -- no
## quality-tier balance exists in the design doc. Mirrors the genre's own
## precedent named in #13 (Stardew Valley: normal/silver/gold at roughly
## 1x/1.25x/1.5x), not a value pulled from this repo's own design work.
const QUALITY_WEIGHT_GOLD := 10.0   # percent chance
const QUALITY_WEIGHT_SILVER := 20.0 # percent chance (remainder is normal)
const QUALITY_PRICE_MULTIPLIER := {
	QUALITY_NORMAL: 1.0,
	QUALITY_SILVER: 1.25,
	QUALITY_GOLD: 1.5,
}

var _definitions: Dictionary = {} # crop_id -> CropDefinition
var _plots: Dictionary = {}       # Vector2i -> FarmPlot
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

## Content pass (#53): 7 crops spanning Spring/Summer/Fall (2 each) plus 1
## Winter crop. parsnip/tomato/pumpkin kept at their original values --
## other systems (CommunityGoalManager's pantry_bundle) reference these
## item_ids by name, so ids and quantities stay stable even in a content
## pass; only newly-added crops are free of that constraint.
func _register_default_content() -> void:
	# Spring
	register_crop(_make_crop("parsnip", "Parsnip", ["Spring"], 4, false, 0, 35, 4))
	register_crop(_make_crop("cauliflower", "Cauliflower", ["Spring"], 6, false, 0, 80, 8))
	# Summer
	register_crop(_make_crop("tomato", "Tomato", ["Summer"], 5, true, 3, 45, 6))
	register_crop(_make_crop("melon", "Melon", ["Summer"], 7, false, 0, 140, 12))
	# Fall
	register_crop(_make_crop("pumpkin", "Pumpkin", ["Fall"], 7, false, 0, 120, 12))
	register_crop(_make_crop("corn", "Corn", ["Fall"], 8, true, 4, 55, 6))
	# Winter (Winter is a real TimeManager season; previously had no crop)
	register_crop(_make_crop("frost_kale", "Frost Kale", ["Winter"], 6, false, 0, 70, 7))

func _make_crop(crop_id: String, display_name: String, seasons: Array[String],
	days_to_grow: int, regrowable: bool, regrow_days: int, sell_price: int, xp: int) -> CropDefinition:
	var def := CropDefinition.new()
	def.crop_id = crop_id
	def.display_name = display_name
	def.valid_seasons = seasons
	def.days_to_grow = days_to_grow
	def.regrowable = regrowable
	def.regrow_days = regrow_days
	def.base_sell_price = sell_price
	def.xp_reward = xp
	return def

## Re-registering the same crop_id is a content overwrite (last write
## wins), same convention as ToolManager.register_tier -- lets a later
## boot's content reload fix balance without a separate "update" API.
func register_crop(def: CropDefinition) -> void:
	if def == null or def.crop_id.is_empty():
		return
	_definitions[def.crop_id] = def

func get_crop_definition(crop_id: String) -> CropDefinition:
	return _definitions.get(crop_id)

func get_plot(position: Vector2i) -> FarmPlot:
	return _plots.get(position)

## Every tile that currently has a FarmPlot entry (planted, watered,
## harvest-ready, or mid-regrow) -- read-only integration point for
## InfrastructureManager's sprinkler automation device, so it can water()
## every plot without reaching into _plots directly.
func get_all_positions() -> Array:
	return _plots.keys()

func is_planted(position: Vector2i) -> bool:
	var plot: FarmPlot = _plots.get(position)
	return plot != null and not plot.is_empty()

func can_plant(position: Vector2i, crop_id: String) -> bool:
	var def: CropDefinition = _definitions.get(crop_id)
	if def == null:
		return false
	if is_planted(position):
		return false
	return def.valid_seasons.has(TimeManager.current_season())

func plant(position: Vector2i, crop_id: String) -> bool:
	if not can_plant(position, crop_id):
		return false
	var seed_id := get_seed_id(crop_id)
	if not InventoryManager.has_item(seed_id):
		return false
	if not InventoryManager.remove_item(seed_id, 1):
		return false
	var plot := FarmPlot.new()
	plot.crop_id = crop_id
	_plots[position] = plot
	crop_planted.emit(position, crop_id)
	return true

func get_all_crop_ids() -> Array[String]:
	var ids: Array[String] = []
	for crop_id: String in _definitions.keys():
		ids.append(crop_id)
	ids.sort()
	return ids

func get_seed_id(crop_id: String) -> String:
	return "%s_seed" % crop_id
func water(position: Vector2i) -> bool:
	var plot: FarmPlot = _plots.get(position)
	if plot == null or plot.is_empty():
		return false
	if plot.harvest_ready or plot.watered_today:
		return false
	plot.watered_today = true
	crop_watered.emit(position)
	return true

## Harvests a ready plot: rolls (or takes a forced) quality tier, credits
## InventoryManager and Farming XP, and either clears the plot (one-shot
## crop) or resets it into its regrow cycle. Returns {} on any failure
## (no plot, not ready, unknown crop) so callers can check for an empty
## Dictionary instead of a sentinel value.
##
## forced_quality lets callers (tests, debug tools) skip the random roll;
## leave empty for normal random quality.
func harvest(position: Vector2i, forced_quality: String = "") -> Dictionary:
	var plot: FarmPlot = _plots.get(position)
	if plot == null or plot.is_empty() or not plot.harvest_ready:
		return {}
	var def: CropDefinition = _definitions.get(plot.crop_id)
	if def == null:
		return {}

	var crop_id := plot.crop_id
	var quality := forced_quality if not forced_quality.is_empty() else _roll_quality()
	var item_id := get_item_id(crop_id, quality)
	var quantity := 1

	InventoryManager.add_item(item_id, quantity)
	SkillManager.add_xp("Farming", def.xp_reward)

	if def.regrowable:
		plot.is_regrowing = true
		plot.days_grown = 0
		plot.watered_today = false
		plot.harvest_ready = false
	else:
		_plots.erase(position)

	crop_harvested.emit(position, item_id, quality, quantity)
	return {"item_id": item_id, "quality": quality, "quantity": quantity, "crop_id": crop_id}

## Quality tiers are encoded into the inventory item_id itself (e.g.
## "parsnip" vs "parsnip_gold") rather than as separate stack metadata --
## InventoryManager is deliberately a plain id->quantity ledger with no
## per-stack quality field (see its docstring), and ShippingBinManager
## already treats same-item-id-different-price shipments as distinct
## lines, so this needs no changes to either autoload.
func get_item_id(crop_id: String, quality: String) -> String:
	if quality == QUALITY_NORMAL or quality.is_empty():
		return crop_id
	return "%s_%s" % [crop_id, quality]

func get_sell_price(crop_id: String, quality: String) -> int:
	var def: CropDefinition = _definitions.get(crop_id)
	if def == null:
		return 0
	var mult: float = QUALITY_PRICE_MULTIPLIER.get(quality, 1.0)
	return int(round(def.base_sell_price * mult))

func _roll_quality() -> String:
	var r := _rng.randf() * 100.0
	if r < QUALITY_WEIGHT_GOLD:
		return QUALITY_GOLD
	if r < QUALITY_WEIGHT_GOLD + QUALITY_WEIGHT_SILVER:
		return QUALITY_SILVER
	return QUALITY_NORMAL

## Growth-cycle tick, keyed off TimeManager.day_started (ENG-12's day
## clock) -- a plot only advances growth if it was watered during the day
## that just ended; watered_today then resets for the new day regardless,
## matching #13's "watering state reset on day change" requirement. A
## plot whose crop's season has ended withers (cleared, crop_withered
## fires) rather than continuing to grow out of season.
func _on_day_started(_day_in_season: int, season: String, _day_of_week: String) -> void:
	var withered_positions: Array = []
	for position in _plots.keys():
		var plot: FarmPlot = _plots[position]
		if plot.is_empty():
			continue
		var def: CropDefinition = _definitions.get(plot.crop_id)
		if def == null:
			continue
		if not def.valid_seasons.has(season):
			withered_positions.append(position)
			continue
		if not plot.harvest_ready and plot.watered_today:
			plot.days_grown += 1
			var target := def.regrow_days if plot.is_regrowing else def.days_to_grow
			if plot.days_grown >= target:
				plot.harvest_ready = true
		plot.watered_today = false

	for position in withered_positions:
		var plot: FarmPlot = _plots[position]
		var crop_id := plot.crop_id
		_plots.erase(position)
		crop_withered.emit(position, crop_id)

func to_save_dict() -> Dictionary:
	var plots_data := {}
	for position in _plots.keys():
		plots_data["%d,%d" % [position.x, position.y]] = _plots[position].to_dict()
	return {"plots": plots_data}

func from_save_dict(data: Dictionary) -> void:
	_plots.clear()
	var plots_data: Dictionary = data.get("plots", {})
	for key in plots_data.keys():
		var parts: PackedStringArray = (key as String).split(",")
		if parts.size() != 2:
			continue
		var position := Vector2i(int(parts[0]), int(parts[1]))
		_plots[position] = FarmPlot.from_dict(plots_data[key])
