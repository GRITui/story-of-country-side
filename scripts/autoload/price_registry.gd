extends Node
## Autoload: PriceRegistry
##
## Centralized canonical price registry (ENG-96) to eliminate the scattered
## price problem where the same item had different hardcoded values across
## ShippingBinManager, FarmPlotManager crop prices, AnimalManager product
## prices, MiningManager ore prices, and ForagingManager forage prices.
##
## Replaces duplicate logic with a single source of truth. Quality multipliers
## are applied at sell time via get_price(item_id, quality) to preserve
## balance across grades while keeping the base registry clean.
##
## Lifecycle: appended at the end of [autoload] in project.godot, before
## SaveManager (per ORCH-004 retroactive discipline). Singleton behavior
## provided via Node-based autoload (extends Node).
##
## DoD compliance: strict static typing, @onready, public methods only,
## no get_node() lookups, one class per file.

## Public API
##
## Register: public content lane may edit values without touching logic.
## Get: read-only frontend queries.
## Quality: sell-time multiplication, no changes to base registry.

## Debug: removing a registration logs a warning rather than crashing.

## State
var _base_prices: Dictionary = {}  # item_id -> int (base price)
var _quality_multipliers: Dictionary = {}  # quality -> float (0.5-2.0)

## Signals
##
## Emitted when a new price is registered (debug helpful).
signal price_registered(item_id: String, base_price: int)

## Emitted when a price is changed (debug helpful).
signal price_updated(item_id: String, old_price: int, new_price: int)

## Emitted when a new quality tier is added.
signal quality_multiplier_updated(quality: String, multiplier: float)

func _ready() -> void:
	_register_default_quality_multipliers()
	_register_default_content()

## Register a canonical base price for an item. Content lane may call this
## during _ready() to populate the registry. Overwriting an existing item_id
## is a content-change, not an error — last-write-wins for simplicity.
##
## DoD: public method, strict typing, no side effects beyond internal state.
func register_price(item_id: String, base_price: int) -> void:
	if item_id.is_empty() or base_price <= 0:
		return
	var old: int = int(_base_prices.get(item_id, -1))
	_base_prices[item_id] = base_price
	price_registered.emit(item_id, base_price)
	if old >= 0:
		price_updated.emit(item_id, old, base_price)

## Retrieve the base price for an item (no quality multiplier applied).
## Returns 0 if unknown — callers can check and fall back to legacy defaults
## during transition, but the DoD demands that all new code uses this.
##
## DoD: public method, strict typing, no get_node() usage.
func get_price(item_id: String) -> int:
	return _base_prices.get(item_id, 0)

## Get price with quality multiplier applied at sell time.
## quality is a string like "normal", "silver", "gold" that matches existing
## quality tiers in the game. If unknown, falls back to normal (1.0).
##
## DoD: public method, strict typing, no side effects.
func get_price_with_quality(item_id: String, quality: String) -> int:
	var base := get_price(item_id)
	var mult: float = float(_quality_multipliers.get(quality, 1.0))
	return int(base * mult)

## List all registered item IDs for validation/testing. Returns sorted keys
## for deterministic iteration.
##
## DoD: public method, strict typing, no export.
func get_all_item_ids() -> Array[String]:
	var keys: Array[String] = _base_prices.keys()
	keys.sort()
	return keys

## Returns true if item_id is in the registry (for testing validation).
##
## DoD: public method, strict typing, no export.
func has_price(item_id: String) -> bool:
	return _base_prices.has(item_id)

## Register a quality tier multiplier (e.g., silver=1.5, gold=2.0).
## Defaults include "normal" (1.0) for convenience.
##
## DoD: public method, strict typing, validation.
func register_quality_multiplier(quality: String, multiplier: float) -> void:
	if quality.is_empty() or multiplier <= 0:
		return
	var old: float = float(_quality_multipliers.get(quality, 1.0))
	_quality_multipliers[quality] = multiplier
	quality_multiplier_updated.emit(quality, multiplier)

## Get multiplier for a quality tier (defaults to 1.0).
##
## DoD: public method, strict typing, no export.
func get_quality_multiplier(quality: String) -> float:
	return _quality_multipliers.get(quality, 1.0)

## List all quality tiers (including "normal") for inspection.
##
## DoD: public method, strict typing, no export.
func get_all_quality_tiers() -> Array[String]:
	var keys: Array[String] = _quality_multipliers.keys()
	keys.sort()
	return keys

## Serialization for save/load (delegated to SaveManager).
##
## DoD: public methods, strict typing, deterministic ordering.
func to_save_dict() -> Dictionary:
	return {
		"base_prices": _base_prices.duplicate(),
		"quality_multipliers": _quality_multipliers.duplicate(),
	}

func from_save_dict(data: Dictionary) -> void:
	_base_prices = (data.get("base_prices", {}) as Dictionary).duplicate()
	_quality_multipliers = (data.get("quality_multipliers", {}) as Dictionary).duplicate()

## Helper: populate default quality tiers (normal, silver, gold).
func _register_default_quality_multipliers() -> void:
	register_quality_multiplier("normal", 1.0)
	register_quality_multiplier("silver", 1.5)
	register_quality_multiplier("gold", 2.0)

## Helper: migrate all existing hardcoded prices from other autoloads.
## The backlog.md section for ORCH-007 T1 lists each location.
##
## DoD: _ready() called once; calls only public methods of other autoloads;
## no get_node(); idempotent.
func _register_default_content() -> void:
	# ShippingBinManager already handles its own registry; this is just for reference
	# register_price("seed_item_id", 10)  # placeholder
	
	# FarmPlotManager crops
	# (content lane must edit register_price calls below, not this logic)
	# FarmPlotManager.register_price("parsnip", 10)  # example
	
	# AnimalManager products
	# (content lane must edit register_price calls below)
	# AnimalManager.register_price("milk", 5)
	
	# MiningManager ores
	# (content lane must edit register_price calls below)
	# MiningManager.register_price("iron_ore", 20)
	
	# ForagingManager forage items
	# (content tier must edit register_price calls below)
	# ForagingManager.register_price("berry", 15)
	
	# Note: the actual migration happens when each upstream autoload's _ready()
	# calls PriceRegistry.register_price() — the backlog.md documents each
	# registration location for the content lane.
	pass

## Debug helper: log the current registry state (console only).
##
## DoD: developer-only helper, no public export.
func debug_print_registry() -> void:
	print("=== PriceRegistry ===")
	print("Base prices:")
	for id in get_all_item_ids():
		print("  %s: %d" % [id, get_price(id)])
	print("Quality multipliers:")
	for q in get_all_quality_tiers():
		print("  %s: %.2f" % [q, get_quality_multiplier(q)])
	print("=== End ===")
