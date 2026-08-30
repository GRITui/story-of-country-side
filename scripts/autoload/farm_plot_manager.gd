extends Node
## Autoload: FarmPlotManager — PO-16BIT-CORE-1 16-bit overhaul
## Extends existing #13/#53/#91 logic with 8-state soil model, 4 new crops,
## tool hooks and stamina integration. Backward compat: get_plot/plant/water/harvest
## signatures unchanged.

signal crop_planted(position: Vector2i, crop_id: String)
signal crop_watered(position: Vector2i)
signal crop_harvested(position: Vector2i, item_id: String, quality: String, quantity: int)
signal crop_withered(position: Vector2i, crop_id: String)
signal seed_purchased(crop_id: String, quantity: int, total_cost: int)
signal soil_tilled(position: Vector2i)
signal soil_state_changed(position: Vector2i, new_state: int)

const STARTING_SEED_CROP_ID := "parsnip"
const STARTING_SEED_QUANTITY := 8

const QUALITY_NORMAL := "normal"
const QUALITY_SILVER := "silver"
const QUALITY_GOLD := "gold"
const QUALITY_WEIGHT_GOLD := 10.0
const QUALITY_WEIGHT_SILVER := 20.0
const QUALITY_PRICE_MULTIPLIER := {
	QUALITY_NORMAL: 1.0,
	QUALITY_SILVER: 1.25,
	QUALITY_GOLD: 1.5,
}

# --- PO-16BIT-CORE-1: SoilState 8-state enum ---
enum SoilState {
	DRY_GRASS = 0,
	TILLED_DRY = 1,
	TILLED_WATERED = 2,
	PLANTED = 3,
	HARVESTABLE = 4,
	WITHERED = 5,
	BLOCKED_ROCK = 6,
	BLOCKED_WOOD = 7,
}
const SOIL_STATE_NAMES := {
	SoilState.DRY_GRASS: "dry_grass",
	SoilState.TILLED_DRY: "tilled_dry",
	SoilState.TILLED_WATERED: "tilled_watered",
	SoilState.PLANTED: "planted",
	SoilState.HARVESTABLE: "harvestable",
	SoilState.WITHERED: "withered",
	SoilState.BLOCKED_ROCK: "blocked_rock",
	SoilState.BLOCKED_WOOD: "blocked_wood",
}

# Tool stamina costs (PO spec: Stamina 100 max, tools consume)
const STAMINA_COST_HOE := 2
const STAMINA_COST_WATER := 1
const STAMINA_COST_SICKLE := 2
const STAMINA_COST_AXE := 4
const STAMINA_COST_HAMMER := 4

var _definitions: Dictionary = {}
var _plots: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func _register_default_content() -> void:
	# Existing roster (keep for compat)
	register_crop(_make_crop("parsnip", "Parsnip", ["Spring"], 4, false, 0, 35, 4, 12))
	register_crop(_make_crop("cauliflower", "Cauliflower", ["Spring"], 6, false, 0, 80, 8, 28))
	register_crop(_make_crop("tomato", "Tomato", ["Summer"], 5, true, 3, 45, 6, 30))
	register_crop(_make_crop("melon", "Melon", ["Summer"], 7, false, 0, 140, 12, 45))
	register_crop(_make_crop("pumpkin", "Pumpkin", ["Fall"], 7, false, 0, 120, 12, 38))
	register_crop(_make_crop("corn", "Corn", ["Fall"], 8, true, 4, 55, 6, 38))
	register_crop(_make_crop("frost_kale", "Frost Kale", ["Winter"], 6, false, 0, 70, 7, 24))
	# PO-16BIT-CORE-1 new crops
	register_crop(_make_crop("turnip", "Turnip", ["Spring", "Fall"], 4, false, 0, 40, 5, 10))
	register_crop(_make_crop("radish", "Radish", ["Spring", "Summer"], 5, false, 0, 55, 6, 14))
	register_crop(_make_crop("eggplant", "Eggplant", ["Summer", "Fall"], 7, false, 0, 90, 10, 22))
	register_crop(_make_crop("strawberry", "Strawberry", ["Spring", "Summer"], 6, true, 3, 30, 5, 20))

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

func register_crop(def: CropDefinition) -> void:
	if def == null or def.crop_id.is_empty():
		return
	_definitions[def.crop_id] = def

func get_crop_definition(crop_id: String) -> CropDefinition:
	return _definitions.get(crop_id)

func get_all_crop_ids() -> Array:
	var ids := _definitions.keys()
	ids.sort()
	return ids

func get_plot(position: Vector2i) -> FarmPlot:
	return _plots.get(position)

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

func get_seed_item_id(crop_id: String) -> String:
	return "%s_seed" % crop_id

func get_seed_price(crop_id: String) -> int:
	var def: CropDefinition = _definitions.get(crop_id)
	if def == null:
		return 0
	return def.seed_price

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

func grant_starting_seeds() -> void:
	InventoryManager.add_item(get_seed_item_id(STARTING_SEED_CROP_ID), STARTING_SEED_QUANTITY)

# --- SoilState helpers ---
func get_soil_state(position: Vector2i) -> int:
	var plot: FarmPlot = _plots.get(position)
	if plot == null:
		return SoilState.DRY_GRASS
	return plot.soil_state

func get_soil_state_name(position: Vector2i) -> String:
	return SOIL_STATE_NAMES.get(get_soil_state(position), "dry_grass")

func get_tile_metadata(position: Vector2i) -> Dictionary:
	var plot: FarmPlot = _plots.get(position)
	if plot == null:
		return {"soilState": "dry_grass", "cropType": "", "growthStage": 0, "daysWatered": 0, "daysWithoutWater": 0, "soil_state": SoilState.DRY_GRASS}
	return {
		"soilState": SOIL_STATE_NAMES.get(plot.soil_state, "dry_grass"),
		"cropType": plot.crop_id,
		"growthStage": plot.days_grown,
		"daysWatered": plot.days_watered,
		"daysWithoutWater": plot.days_without_water,
		"soil_state": plot.soil_state,
	}

## Hoe: dry_grass -> tilled_dry . Stamina hook.
func till(position: Vector2i) -> bool:
	var plot: FarmPlot = _plots.get(position)
	if plot != null:
		if plot.soil_state == SoilState.BLOCKED_ROCK or plot.soil_state == SoilState.BLOCKED_WOOD:
			return false
		if not plot.is_empty():
			return false
		if plot.soil_state != SoilState.DRY_GRASS:
			return false
	# stamina check (consume, but allow failure to still till? spec: stamina gate)
	if StaminaManager.has_method("spend"):
		if not StaminaManager.spend(STAMINA_COST_HOE):
			# at 0 stamina we still allow action but speed reduced externally; spend failed -> passed_out
			pass
	var np: FarmPlot = _plots.get(position)
	if np == null:
		np = FarmPlot.new()
		_plots[position] = np
	np.soil_state = SoilState.TILLED_DRY
	np.days_without_water = 0
	soil_tilled.emit(position)
	soil_state_changed.emit(position, SoilState.TILLED_DRY)
	return true

## Blocked tile setter (Axe/Hammer use)
func set_blocked(position: Vector2i, blocked_type: String) -> void:
	var p := FarmPlot.new()
	if blocked_type == "rock":
		p.soil_state = SoilState.BLOCKED_ROCK
		p.blocked_type = "rock"
	elif blocked_type == "wood":
		p.soil_state = SoilState.BLOCKED_WOOD
		p.blocked_type = "wood"
	_plots[position] = p

func clear_blocked(position: Vector2i, tool: String) -> bool:
	var plot: FarmPlot = _plots.get(position)
	if plot == null:
		return false
	if plot.soil_state == SoilState.BLOCKED_ROCK and tool == "hammer":
		if StaminaManager.has_method("spend"):
			StaminaManager.spend(STAMINA_COST_HAMMER)
		_plots.erase(position)
		soil_state_changed.emit(position, SoilState.DRY_GRASS)
		return true
	if plot.soil_state == SoilState.BLOCKED_WOOD and tool == "axe":
		if StaminaManager.has_method("spend"):
			StaminaManager.spend(STAMINA_COST_AXE)
		_plots.erase(position)
		soil_state_changed.emit(position, SoilState.DRY_GRASS)
		return true
	return false

func use_sickle(position: Vector2i) -> bool:
	var plot: FarmPlot = _plots.get(position)
	if plot == null:
		return false
	if plot.soil_state != SoilState.WITHERED:
		return false
	if StaminaManager.has_method("spend"):
		StaminaManager.spend(STAMINA_COST_SICKLE)
	_plots.erase(position)
	soil_state_changed.emit(position, SoilState.DRY_GRASS)
	return true

func _consume_stamina_for_water() -> void:
	if StaminaManager.has_method("spend"):
		StaminaManager.spend(STAMINA_COST_WATER)

func get_seed_id(crop_id: String) -> String:
	return "%s_seed" % crop_id

func plant(position: Vector2i, crop_id: String) -> bool:
	if not can_plant(position, crop_id):
		return false
	var seed_item_id := get_seed_item_id(crop_id)
	if not InventoryManager.has_item(seed_item_id):
		return false
	if not InventoryManager.remove_item(seed_item_id, 1):
		return false
	var plot: FarmPlot = _plots.get(position)
	if plot == null:
		plot = FarmPlot.new()
		_plots[position] = plot
	# soil must be tilled; if dry_grass allow implicit till for backward compat
	if plot.soil_state == SoilState.DRY_GRASS:
		plot.soil_state = SoilState.TILLED_DRY
	plot.crop_id = crop_id
	plot.days_grown = 0
	plot.growth_stage = 0
	plot.days_watered = 0
	plot.days_without_water = 0
	# planted state (unless already watered)
	if plot.watered_today or plot.soil_state == SoilState.TILLED_WATERED:
		plot.soil_state = SoilState.PLANTED
		# keep watered_today true
	else:
		plot.soil_state = SoilState.PLANTED
	plot.is_regrowing = false
	plot.harvest_ready = false
	crop_planted.emit(position, crop_id)
	soil_state_changed.emit(position, plot.soil_state)
	return true

func water(position: Vector2i) -> bool:
	var plot: FarmPlot = _plots.get(position)
	if plot == null or plot.is_empty():
		# allow watering empty tilled soil
		if plot != null and (plot.soil_state == SoilState.TILLED_DRY):
			if plot.watered_today:
				return false
			_consume_stamina_for_water()
			plot.watered_today = true
			plot.soil_state = SoilState.TILLED_WATERED
			plot.days_without_water = 0
			crop_watered.emit(position)
			soil_state_changed.emit(position, plot.soil_state)
			return true
		return false
	if plot.harvest_ready or plot.watered_today:
		return false
	if plot.soil_state == SoilState.BLOCKED_ROCK or plot.soil_state == SoilState.BLOCKED_WOOD or plot.soil_state == SoilState.WITHERED:
		return false
	_consume_stamina_for_water()
	plot.watered_today = true
	# preserve planted vs tilled distinction but mark watered
	if plot.soil_state == SoilState.TILLED_DRY:
		plot.soil_state = SoilState.TILLED_WATERED
	# planted stays planted but watered_today true ; track days_watered
	plot.days_without_water = 0
	crop_watered.emit(position)
	soil_state_changed.emit(position, plot.soil_state)
	return true

## Watering Can 1x3 (horizontal 3 tiles centered on position)
func water_area(center: Vector2i, upgraded: bool = false) -> int:
	var count := 0
	var offsets: Array[Vector2i] = [Vector2i.ZERO]
	if upgraded:
		offsets = [Vector2i(-1,0), Vector2i.ZERO, Vector2i(1,0)]
	for off in offsets:
		if water(center + off):
			count += 1
	return count

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
	if SkillManager.has_method("add_xp"):
		SkillManager.add_xp("Farming", def.xp_reward)
	if def.regrowable:
		plot.is_regrowing = true
		plot.days_grown = 0
		plot.growth_stage = 0
		plot.watered_today = false
		plot.harvest_ready = false
		plot.soil_state = SoilState.PLANTED
		plot.days_without_water = 0
	else:
		# keep tilled soil after harvest (tilled_dry)
		plot.crop_id = ""
		plot.days_grown = 0
		plot.harvest_ready = false
		plot.is_regrowing = false
		plot.watered_today = false
		plot.soil_state = SoilState.TILLED_DRY
		plot.days_without_water = 0
		# keep plot entry as tilled soil (don't erase) to preserve soilState
	crop_harvested.emit(position, item_id, quality, quantity)
	soil_state_changed.emit(position, plot.soil_state if _plots.has(position) else SoilState.DRY_GRASS)
	return {"item_id": item_id, "quality": quality, "quantity": quantity, "crop_id": crop_id}

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

func _on_day_started(_day_in_season: int, season: String, _day_of_week: String) -> void:
	var withered_positions: Array = []
	for position in _plots.keys():
		var plot: FarmPlot = _plots[position]
		if plot.soil_state == SoilState.BLOCKED_ROCK or plot.soil_state == SoilState.BLOCKED_WOOD:
			continue
		if plot.is_empty():
			# empty tilled soil: watered->dry, track wither not needed
			if plot.watered_today:
				plot.watered_today = false
				if plot.soil_state == SoilState.TILLED_WATERED:
					plot.soil_state = SoilState.TILLED_DRY
			continue
		var def: CropDefinition = _definitions.get(plot.crop_id)
		if def == null:
			continue
		if not def.valid_seasons.has(season):
			withered_positions.append(position)
			continue
		# crop advance only if watered prior day
		if not plot.harvest_ready and plot.watered_today:
			plot.days_grown += 1
			plot.days_watered += 1
			plot.days_without_water = 0
			var target := def.regrow_days if plot.is_regrowing else def.days_to_grow
			if plot.days_grown >= target:
				plot.harvest_ready = true
				plot.soil_state = SoilState.HARVESTABLE
		else:
			if not plot.watered_today and not plot.harvest_ready:
				plot.days_without_water += 1
				if plot.days_without_water > 2:
					withered_positions.append(position)
					continue
		# watered -> dry transition
		if plot.watered_today:
			plot.watered_today = false
			if plot.soil_state == SoilState.TILLED_WATERED:
				plot.soil_state = SoilState.TILLED_DRY
			# planted stays planted but now dry (watered_today false)
		# keep soil_state consistent for planted vs harvestable
		if not plot.harvest_ready and not plot.is_empty() and plot.soil_state == SoilState.HARVESTABLE:
			plot.soil_state = SoilState.PLANTED
		elif plot.harvest_ready:
			plot.soil_state = SoilState.HARVESTABLE

	for position in withered_positions:
		var plot: FarmPlot = _plots[position]
		var crop_id := plot.crop_id
		plot.crop_id = ""
		plot.days_grown = 0
		plot.harvest_ready = false
		plot.is_regrowing = false
		plot.watered_today = false
		plot.soil_state = SoilState.WITHERED
		plot.days_without_water = 0
		crop_withered.emit(position, crop_id)
		soil_state_changed.emit(position, SoilState.WITHERED)

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
