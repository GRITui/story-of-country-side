extends Node
## Autoload: ToolManager
##
## Per-tool upgrade economy (ENG-23): Copper (free start) -> Iron -> Gold,
## each tier bigger AoE + lower stamina cost. Deliberately NOT quest-gated
## -- re-reading #23 against #24 (Infrastructure Upgrades), Decision C's
## quest-gating (#4) was aimed at automation tiers (sprinklers, auto-
## feeders), which is #24's scope. Gating basic tool progression behind
## quests would be bad pacing and isn't what #23 itself describes -- pure
## gold+ore economy here, same as the genre's own precedent (SDV/HMBtN
## blacksmith upgrades require no quests).
##
## Per-tool, not global -- an AoE upgrade means something different per
## tool (hoe/watering-can vs. axe/pickaxe), matching genre precedent.
##
## Owns a minimal ore ledger sized to its own needs, not a general
## inventory system -- no InventoryManager exists anywhere in this repo
## yet (nothing produces "items you hold," only ShippingBinManager's
## sell-queue). Flagging that gap rather than building a general inventory
## system as unrequested scope; a real InventoryManager, once it exists,
## would likely supersede this local ledger.

signal ore_added(item_id: String, quantity: int, total: int)
signal tool_upgraded(tool_name: String, new_tier: int)

const TIER_COPPER := 0

## Copper's AoE/stamina cost aren't ToolUpgradeTier content since Copper
## has no cost to reach -- every tool starts here for free.
const COPPER_AOE_OFFSETS: Array[Vector2i] = [Vector2i.ZERO]
const COPPER_STAMINA_COST := 5

var _tool_tiers: Dictionary = {}       ## tool_name -> int (current tier, default TIER_COPPER)
var _tier_definitions: Dictionary = {} ## tool_name -> Dictionary[int tier_index -> ToolUpgradeTier]
var _ore_counts: Dictionary = {}       ## item_id -> int

func _ready() -> void:
	_register_default_content()

## Real balance, differentiated per tool -- all four tools share the same
## AoE progression shape (a 5-tile cross at Iron, the full 3x3 at Gold) so
## upgrading always *feels* the same, but the ore/gold price scales with
## how central the tool is to the daily loop and how much a bigger swing
## is worth. Hoe/WateringCan are used every single day, so they stay
## cheapest to keep early-game friction low. Axe costs a bit more (wood
## feeds the Infrastructure track, so a wider AoE compounds in value).
## Pickaxe is priciest -- a bigger mining AoE is the single best ore/gem
## income multiplier in the game (see MiningManager), so it's worth
## charging the most to reach.
func _register_default_content() -> void:
	var cross: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	register_tier("Hoe", _make_tier(1, "iron_ore", 5, 200, cross, 4))
	register_tier("Hoe", _make_tier(2, "gold_ore", 5, 500, _full_3x3_offsets(), 3))
	register_tier("Hoe", _make_tier(3, "diamond", 3, 900, _full_3x3_offsets(), 2))

	register_tier("WateringCan", _make_tier(1, "iron_ore", 4, 150, cross, 4))
	register_tier("WateringCan", _make_tier(2, "gold_ore", 4, 400, _full_3x3_offsets(), 3))
	register_tier("WateringCan", _make_tier(3, "diamond", 2, 750, _full_3x3_offsets(), 2))

	register_tier("Axe", _make_tier(1, "iron_ore", 5, 220, cross, 4))
	register_tier("Axe", _make_tier(2, "gold_ore", 6, 550, _full_3x3_offsets(), 3))
	register_tier("Axe", _make_tier(3, "diamond", 4, 1000, _full_3x3_offsets(), 2))

	register_tier("Pickaxe", _make_tier(1, "iron_ore", 6, 260, cross, 4))
	register_tier("Pickaxe", _make_tier(2, "gold_ore", 7, 650, _full_3x3_offsets(), 3))
	register_tier("Pickaxe", _make_tier(3, "diamond", 5, 1200, _full_3x3_offsets(), 2))
	register_tier("Sickle", _make_tier(1, "iron_ore", 3, 120, cross, 3))
	register_tier("Sickle", _make_tier(2, "gold_ore", 3, 350, _full_3x3_offsets(), 2))

## Hold-to-charge: 0-400ms L1 1x1, 400-800ms L2 1x3/ cross, >800ms L3 3x3 (requires tier)
func get_charge_level(tool_name: String, hold_ms: int) -> int:
	var tier := get_tool_tier(tool_name)
	if hold_ms > 800 and tier >= 2: return 3
	if hold_ms > 400 and tier >= 1: return 2
	return 1

func get_aoe_for_charge(tool_name: String, charge_level: int) -> Array[Vector2i]:
	if charge_level == 3: return _full_3x3_offsets()
	if charge_level == 2: return [Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0)] if tool_name in ["Hoe","WateringCan","Sickle"] else [Vector2i(0,0),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	return [Vector2i.ZERO]

func _make_tier(tier_index: int, ore_item_id: String, ore_quantity: int, gold_cost: int,
	aoe_offsets: Array[Vector2i], stamina_cost: int) -> ToolUpgradeTier:
	var t := ToolUpgradeTier.new()
	t.tier_index = tier_index
	t.ore_item_id = ore_item_id
	t.ore_quantity = ore_quantity
	t.gold_cost = gold_cost
	t.aoe_offsets = aoe_offsets
	t.stamina_cost = stamina_cost
	return t

func _full_3x3_offsets() -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			offsets.append(Vector2i(x, y))
	return offsets

## Re-registering the same tool_name/tier_index is a content overwrite
## (last write wins), not additive -- lets a later boot's content reload
## fix balance numbers without needing a separate "update" API.
func register_tier(tool_name: String, tier: ToolUpgradeTier) -> void:
	if tool_name.is_empty() or tier == null:
		return
	if not _tier_definitions.has(tool_name):
		_tier_definitions[tool_name] = {}
	_tier_definitions[tool_name][tier.tier_index] = tier

func get_tool_tier(tool_name: String) -> int:
	return _tool_tiers.get(tool_name, TIER_COPPER)

func add_ore(item_id: String, quantity: int) -> void:
	if quantity <= 0:
		return
	var total: int = get_ore_count(item_id) + quantity
	_ore_counts[item_id] = total
	ore_added.emit(item_id, quantity, total)

func get_ore_count(item_id: String) -> int:
	return _ore_counts.get(item_id, 0)

func can_upgrade(tool_name: String) -> bool:
	var def := _next_tier_def(tool_name)
	if def == null:
		return false
	return get_ore_count(def.ore_item_id) >= def.ore_quantity and ShippingBinManager.gold >= def.gold_cost

## Spends ore and gold and advances the tool's tier on success. On any
## failure (no next tier, insufficient ore, insufficient gold), nothing
## is deducted -- ore is checked before gold is spent, so a failed gold
## spend never leaves ore partially consumed.
func upgrade_tool(tool_name: String) -> bool:
	var def := _next_tier_def(tool_name)
	if def == null:
		return false
	if get_ore_count(def.ore_item_id) < def.ore_quantity:
		return false
	if not ShippingBinManager.spend(def.gold_cost):
		return false
	_ore_counts[def.ore_item_id] = get_ore_count(def.ore_item_id) - def.ore_quantity
	_tool_tiers[tool_name] = def.tier_index
	tool_upgraded.emit(tool_name, def.tier_index)
	return true

func get_aoe_offsets(tool_name: String) -> Array[Vector2i]:
	var tier := get_tool_tier(tool_name)
	if tier == TIER_COPPER:
		return COPPER_AOE_OFFSETS
	var def := _tier_def(tool_name, tier)
	return def.aoe_offsets if def else COPPER_AOE_OFFSETS

func get_stamina_cost(tool_name: String) -> int:
	var tier := get_tool_tier(tool_name)
	if tier == TIER_COPPER:
		return COPPER_STAMINA_COST
	var def := _tier_def(tool_name, tier)
	return def.stamina_cost if def else COPPER_STAMINA_COST

func _next_tier_def(tool_name: String) -> ToolUpgradeTier:
	return _tier_def(tool_name, get_tool_tier(tool_name) + 1)

func _tier_def(tool_name: String, tier_index: int) -> ToolUpgradeTier:
	var tiers: Dictionary = _tier_definitions.get(tool_name, {})
	return tiers.get(tier_index, null)

func to_save_dict() -> Dictionary:
	return {
		"tool_tiers": _tool_tiers.duplicate(),
		"ore_counts": _ore_counts.duplicate(),
	}

func from_save_dict(data: Dictionary) -> void:
	_tool_tiers = (data.get("tool_tiers", {}) as Dictionary).duplicate()
	_ore_counts = (data.get("ore_counts", {}) as Dictionary).duplicate()
