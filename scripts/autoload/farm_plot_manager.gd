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
##
## Seed economy (#91): plant() used to be free/infinite (no inventory
## check at all). Seeds are now real InventoryManager items under the
## "<crop_id>_seed" convention (get_seed_item_id) -- plant() requires and
## consumes one, buy_seed() is the smallest-viable purchase path (spends
## gold via ShippingBinManager.spend(), credits InventoryManager
## directly), and SaveManager.new_game() calls grant_starting_seeds() so
## day 1 starts with a real (if placeholder-priced) planting decision.

signal crop_planted(position: Vector2i, crop_id: String)
signal crop_watered(position: Vector2i)
signal crop_harvested(position: Vector2i, item_id: String, quality: String, quantity: int)
signal crop_withered(position: Vector2i, crop_id: String) ## fires when a planted crop's season ends before harvest
signal seed_purchased(crop_id: String, quantity: int, total_cost: int) ## #91: buy_seed() succeeded

## #91: starting seed grant applied by SaveManager.new_game() via
## grant_starting_seeds() -- enough for a meaningful first-day choice
## (ship what vs. plant what) without also being a large gold sink,
## matching the issue's "e.g. 8 parsnip seeds" proposal.
const STARTING_SEED_CROP_ID := "parsnip"
const STARTING_SEED_QUANTITY := 8

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
##
## CONTENT-SEED-BALANCE (Sprint 2): seed_price values below replace PR
## #122's flat "~40-55% of base_sell_price" placeholder heuristic with a
## real per-crop pass, grounded in each crop's actual days_to_grow and
## regrow behavior (28-day season, TimeManager.DAYS_PER_SEASON):
## - One-time-harvest crops are priced around 30-35% of base_sell_price --
##   a single harvest must clear the seed cost with real margin left over,
##   but the seed can't be worth more than a modest slice of the one
##   payout it produces. Slower/higher-value crops (melon, pumpkin) sit at
##   the low end of that band since their absolute margin is already
##   large; faster/cheaper crops (parsnip, frost_kale) sit slightly higher
##   since a thin absolute margin still needs to feel worthwhile.
## - Regrowable crops (tomato, corn) are priced much closer to
##   base_sell_price itself (roughly two-thirds) precisely because one
##   seed pays out repeatedly across the season -- see get_seed_price
##   users' math below. Tomato (5-day first grow, 3-day regrow) yields 8
##   harvests off one seed in a 28-day season; corn (8-day first grow,
##   4-day regrow) yields 6. The first harvest alone barely clears the
##   seed cost by design (tomato: 45-30=15g; corn: 55-38=17g) -- every
##   harvest after that is what actually justifies the higher seed price,
##   which is the "regrowable crops can rationally support a higher seed
##   price" reasoning PR #122 flagged but didn't apply.
func _register_default_content() -> void:
	# Spring
	register_crop(_make_crop("parsnip", "Parsnip", ["Spring"], 4, false, 0, 35, 4, 12))
	register_crop(_make_crop("cauliflower", "Cauliflower", ["Spring"], 6, false, 0, 80, 8, 28))
	# Summer
	register_crop(_make_crop("tomato", "Tomato", ["Summer"], 5, true, 3, 45, 6, 30))
	register_crop(_make_crop("melon", "Melon", ["Summer"], 7, false, 0, 140, 12, 45))
	# Fall
	register_crop(_make_crop("pumpkin", "Pumpkin", ["Fall"], 7, false, 0, 120, 12, 38))
	register_crop(_make_crop("corn", "Corn", ["Fall"], 8, true, 4, 55, 6, 38))
	# Winter (Winter is a real TimeManager season; previously had no crop)
	register_crop(_make_crop("frost_kale", "Frost Kale", ["Winter"], 6, false, 0, 70, 7, 24))

func _make_crop(crop_id: String, display_name: String, seasons: Array[String],
	days_to_grow: int, regrowable: bool, regrow_days: int, sell_price: int, xp: int,
	seed_price: int = 5) -> CropDefinition:
	var def := CropDefinition.new()
	def.crop_id = crop_id
	def.display_name = display_name
	def.valid_seasons = seasons
	def.days_to_grow = days_to_grow
	def.regrowable = regrowable
	def.regrow_days = regrow_days
	def.base_sell_price = sell_price
	def.xp_reward = xp
	def.seed_price = seed_price
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

## ENG-LIST-CROP-IDS: every crop_id currently registered via
## _register_default_content() (or any later register_crop() call) --
## the "list every crop_id" getter ShopOverlay's own docstring (PR #125)
## flagged as a backend follow-up, having hardcoded its CROP_IDS const in
## the meantime. Named to match this same file's get_all_positions()
## convention rather than get_crop_definition()'s singular-lookup shape.
## Sorted by crop_id for a deterministic iteration order, same reasoning
## FestivalManager.get_festival_for_date() gives for sorting its own
## Dictionary.keys() before use.
func get_all_crop_ids() -> Array:
	var ids := _definitions.keys()
	ids.sort()
	return ids

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

## #91: quality tiers are encoded into the harvested item_id (see
## get_item_id below); seeds get the same treatment but with their own
## fixed "_seed" suffix on the base crop_id -- a seed has no quality tier
## of its own, so this is a separate convention, not get_item_id reused.
func get_seed_item_id(crop_id: String) -> String:
	return "%s_seed" % crop_id

func get_seed_price(crop_id: String) -> int:
	var def: CropDefinition = _definitions.get(crop_id)
	if def == null:
		return 0
	return def.seed_price

## #91: smallest viable purchase path (per issue #91's proposal) --
## spends gold via ShippingBinManager.spend() and credits seed inventory
## via InventoryManager.add_item(), no separate shop autoload/UI. Fails
## cleanly (no partial spend, no signal) on an unknown crop, a
## non-positive quantity/price, or insufficient gold -- same
## check-before-spend shape as InventoryManager.remove_item/
## ToolManager.upgrade_tool.
func buy_seed(crop_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	var def: CropDefinition = _definitions.get(crop_id)
	if def == null or def.seed_price <= 0:
		return false
	var total_cost := def.seed_price * quantity
	if not ShippingBinManager.spend(total_cost):
		return false
	InventoryManager.add_item(get_seed_item_id(crop_id), quantity)
	seed_purchased.emit(crop_id, quantity, total_cost)
	return true

## #91: SaveManager.new_game() calls this once after resetting Inventory/
## FarmPlotManager to their fresh-boot defaults -- a starting-inventory
## grant is cross-cutting (touches InventoryManager, not just this
## manager's own state) so it isn't folded into from_save_dict({})'s
## per-manager reset the way STARTING_GOLD is.
func grant_starting_seeds() -> void:
	InventoryManager.add_item(get_seed_item_id(STARTING_SEED_CROP_ID), STARTING_SEED_QUANTITY)

## #91: planting now requires + consumes one real seed item instead of
## being free/infinite -- can_plant() above stays season/empty-plot only
## (no inventory side effect) so UI can still preview plantability without
## spending anything; the seed check/consume only happens here, in the
## actual mutating call. Fails cleanly (returns false, no plot mutation,
## no signal, seed not consumed) when the player has no seed on hand --
## same "check before spend" shape as InventoryManager.remove_item.
func plant(position: Vector2i, crop_id: String) -> bool:
	if not can_plant(position, crop_id):
		return false
	var seed_item_id := get_seed_item_id(crop_id)
	if not InventoryManager.has_item(seed_item_id):
		return false
	if not InventoryManager.remove_item(seed_item_id, 1):
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
