extends Node
## Autoload: MiningManager
##
## Mining (#16), scoped per Decision B (#3, resolved peaceful/no-combat):
## procedurally generated floors, rock-breaking, ore/gem gathering, ladder
## descent between floors. No enemies/HP/weapons -- that branch of #16's
## scope is explicitly dropped per the resolved decision.
##
## Reuses ToolManager's existing "iron_ore"/"gold_ore" item ids for the
## mid/high-tier ore drops (deliberate cross-system consistency: ore mined
## here can go straight into ToolManager.upgrade_tool's cost, no separate
## currency). "copper_ore" and "diamond" are new placeholder ids this PR
## introduces (copper has no consumer yet since ToolManager's Copper tier
## is free-starting with no ore cost; diamond has no consumer anywhere yet
## -- both flagged as gaps, not silently invented scope, matching #23's
## own "no InventoryManager exists yet" honesty pattern).
##
## Consumes InventoryManager + SkillManager.add_xp("Mining", ...) the same
## way every other gathering activity does. Never touches
## ShippingBinManager directly.
##
## Floor generation uses a RandomNumberGenerator with an optional explicit
## seed (generate_floor's second param) so tests can reproduce floor
## layouts deterministically -- real play calls generate_floor(index)
## with no seed, which reseeds from OS entropy via _rng.randomize() in
## _ready().
##
## Persisted through SaveManager (floor_index + per-tile broken/ore
## state) -- unlike FishingManager's stateless casts, a mine floor's
## progress is meaningful player state worth keeping across a save/load,
## same reasoning as FarmPlotManager's planted tiles.
##
## Placeholder floor size, ore table, and drop rates below are MVP
## balance, not final numbers -- same honesty as every other content
## table in this repo.

signal rock_broken(tile: Vector2i, item_id: String, quantity: int)
signal floor_descended(new_floor_index: int)

const FLOOR_WIDTH := 5
const FLOOR_HEIGHT := 5

const STONE_ITEM_ID := "stone"
const STONE_XP := 1
const STONE_QUANTITY := 1
const ORE_QUANTITY := 2

## Probability an individual rock tile carries ore/gem instead of plain
## stone -- placeholder, not final balance.
const ORE_CHANCE := 0.3

var floor_index: int = 1

## Vector2i -> {has_rock: bool, ore_item_id: String, broken: bool}
var _tiles: Dictionary = {}
var _ladder_position: Vector2i = Vector2i.ZERO
var _ore_definitions: Array = [] # Array[OreDefinition]
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_register_default_content()
	generate_floor(floor_index)

## Placeholder ore table: copper is the common floor-1 drop, iron and gold
## reuse ToolManager's exact item ids (see top-of-file docstring), diamond
## is a rare floor-5+ gem with no consumer yet. Not final game balance.
func _register_default_content() -> void:
	register_ore(_make_ore("copper_ore", 1, 50.0, 3))
	register_ore(_make_ore("iron_ore", 1, 30.0, 4))
	register_ore(_make_ore("gold_ore", 3, 15.0, 6))
	register_ore(_make_ore("diamond", 5, 5.0, 10))

func _make_ore(item_id: String, min_floor: int, weight: float, xp_reward: int) -> OreDefinition:
	var def := OreDefinition.new()
	def.item_id = item_id
	def.min_floor = min_floor
	def.weight = weight
	def.xp_reward = xp_reward
	return def

## Appends rather than overwrites by item_id (unlike the other *_manager
## register_* calls) -- ore drops are rolled from the whole table at once,
## not looked up by id, so there's no natural "slot" to overwrite. Content
## authors adding a duplicate item_id get two independently-weighted
## entries; harmless, just double-counts that id's weight.
func register_ore(def: OreDefinition) -> void:
	if def == null or def.item_id.is_empty():
		return
	_ore_definitions.append(def)

func get_floor_size() -> Vector2i:
	return Vector2i(FLOOR_WIDTH, FLOOR_HEIGHT)

func get_ladder_position() -> Vector2i:
	return _ladder_position

func has_rock(tile: Vector2i) -> bool:
	var t: Dictionary = _tiles.get(tile, {})
	return t.get("has_rock", false) and not t.get("broken", true)

## Regenerates the floor grid: every tile starts as an unbroken rock
## except one reserved ladder-down tile (no rock, already "broken").
## seed_value >= 0 pins the RNG for deterministic tests; real play omits
## it and keeps drawing from the RNG seeded in _ready().
func generate_floor(index: int, seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	floor_index = index
	_tiles.clear()

	_ladder_position = Vector2i(_rng.randi_range(0, FLOOR_WIDTH - 1), _rng.randi_range(0, FLOOR_HEIGHT - 1))
	for x in FLOOR_WIDTH:
		for y in FLOOR_HEIGHT:
			var tile := Vector2i(x, y)
			if tile == _ladder_position:
				_tiles[tile] = {"has_rock": false, "ore_item_id": "", "broken": true}
				continue
			var ore_item_id := ""
			if _rng.randf() < ORE_CHANCE:
				ore_item_id = _roll_ore(index)
			_tiles[tile] = {"has_rock": true, "ore_item_id": ore_item_id, "broken": false}

## Weighted roll among ore definitions eligible for floor_idx (min_floor
## <= floor_idx). Returns "" if nothing is eligible (shouldn't happen with
## the default content's floor-1 entries, but a floor with no eligible ore
## just yields plain stone from that roll instead of crashing).
func _roll_ore(floor_idx: int) -> String:
	var eligible: Array = _ore_definitions.filter(func(d: OreDefinition) -> bool: return floor_idx >= d.min_floor)
	if eligible.is_empty():
		return ""
	var total_weight := 0.0
	for def: OreDefinition in eligible:
		total_weight += def.weight
	var roll := _rng.randf() * total_weight
	var accumulated := 0.0
	for def: OreDefinition in eligible:
		accumulated += def.weight
		if roll < accumulated:
			return def.item_id
	return (eligible[-1] as OreDefinition).item_id

func _xp_for_item(item_id: String) -> int:
	for def: OreDefinition in _ore_definitions:
		if def.item_id == item_id:
			return def.xp_reward
	return STONE_XP

## Breaks one rock tile: credits InventoryManager with stone (no ore
## rolled) or the rolled ore/gem, plus matching Mining XP. Returns {} if
## the tile has no intact rock (already broken, the ladder tile, or out
## of bounds) so callers can tell "nothing happened" from a real result.
func break_rock(tile: Vector2i) -> Dictionary:
	var t: Dictionary = _tiles.get(tile, {})
	if not t.get("has_rock", false) or t.get("broken", true):
		return {}

	t["broken"] = true
	var ore_item_id: String = t.get("ore_item_id", "")
	var item_id: String
	var quantity: int
	if ore_item_id.is_empty():
		item_id = STONE_ITEM_ID
		quantity = STONE_QUANTITY
	else:
		item_id = ore_item_id
		quantity = ORE_QUANTITY

	InventoryManager.add_item(item_id, quantity)
	SkillManager.add_xp("Mining", _xp_for_item(item_id))

	rock_broken.emit(tile, item_id, quantity)
	return {"item_id": item_id, "quantity": quantity}

## Descends to the next floor, regenerating it fresh. Always succeeds as
## an action -- gating on "is the player actually standing on the ladder
## tile" is a caller/frontend concern (this autoload has no concept of
## player position, same boundary every other activity manager draws).
func descend_ladder() -> bool:
	generate_floor(floor_index + 1)
	floor_descended.emit(floor_index)
	return true

func to_save_dict() -> Dictionary:
	var tiles_data: Dictionary = {}
	for tile: Vector2i in _tiles.keys():
		tiles_data["%d,%d" % [tile.x, tile.y]] = (_tiles[tile] as Dictionary).duplicate()
	return {
		"floor_index": floor_index,
		"tiles": tiles_data,
		"ladder_x": _ladder_position.x,
		"ladder_y": _ladder_position.y,
	}

## Falls back to a fresh floor 1 when data is empty (new_game()'s reset
## path) rather than leaving _tiles empty -- every other manager's
## from_save_dict({}) similarly lands on a valid fresh-boot state.
func from_save_dict(data: Dictionary) -> void:
	var raw: Dictionary = data.get("tiles", {})
	if raw.is_empty():
		generate_floor(1)
		return
	floor_index = data.get("floor_index", 1)
	_tiles.clear()
	for key: String in raw.keys():
		var parts := key.split(",")
		if parts.size() != 2 or not (parts[0].is_valid_int() and parts[1].is_valid_int()):
			continue
		_tiles[Vector2i(parts[0].to_int(), parts[1].to_int())] = (raw[key] as Dictionary).duplicate()
	_ladder_position = Vector2i(data.get("ladder_x", 0), data.get("ladder_y", 0))
