class_name PriceRegistry
extends RefCounted
## Canonical price registry — single source of truth for item base prices.
## Issue #96. Placeholder MVP balance — no final economy design exists.
##
## Other managers (FarmPlotManager, AnimalManager, FishingManager) still
## own their own base_sell_price tables for now; this sprint only creates
## the canonical registry and makes ShippingBinManager delegate to it.
## Future refactors should migrate those tables here.
##
## Usage (static):
##   PriceRegistry.get_price("parsnip", "gold") -> int
##   PriceRegistry.get_base_price("parsnip") -> int
##   PriceRegistry.register_price("parsnip", 35, "crop")

const QUALITY_NORMAL := "normal"
const QUALITY_SILVER := "silver"
const QUALITY_GOLD := "gold"

const QUALITY_PRICE_MULTIPLIER := {
	QUALITY_NORMAL: 1.0,
	QUALITY_SILVER: 1.25,
	QUALITY_GOLD: 1.5,
}

# item_id -> {base_price: int, category: String}
static var _prices: Dictionary = {}
static var _initialized: bool = false

static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_register_default_prices()

static func _register_default_prices() -> void:
	# ------------------------------------------------------------------
	# Placeholder MVP balance — mirrors existing CropDefinition /
	# AnimalDefinition / FishDefinition / Forage values so numbers stay
	# consistent if callers migrate to this registry.
	# Categories: crop, animal_product, fish, forage, mineral, artisan, cooked
	# ------------------------------------------------------------------
	# Crops (from FarmPlotManager)
	register_price("parsnip", 35, "crop")
	register_price("cauliflower", 80, "crop")
	register_price("tomato", 45, "crop")
	register_price("melon", 140, "crop")
	register_price("pumpkin", 120, "crop")
	register_price("corn", 55, "crop")
	register_price("frost_kale", 70, "crop")
	# Quality-suffixed variants share base price (quality handled via multiplier)
	# No need to register parsnip_silver etc. — get_price strips suffix.

	# Animal products (from AnimalManager)
	register_price("egg", 20, "animal_product")
	register_price("milk", 30, "animal_product")
	register_price("wool", 40, "animal_product")

	# Fish (from FishingManager) — 4 base fish
	register_price("carp", 30, "fish")
	register_price("trout", 40, "fish")
	register_price("salmon", 80, "fish")
	register_price("tuna", 120, "fish")

	# Forage (from ForagingManager)
	register_price("wild_berries", 8, "forage")
	register_price("wild_flower", 6, "forage")
	register_price("mushroom", 12, "forage")
	register_price("snow_truffle", 20, "forage")

	# Minerals / ores (from ToolManager / MiningManager)
	register_price("stone", 5, "mineral")
	register_price("wood", 4, "mineral")
	register_price("copper_ore", 10, "mineral")
	register_price("iron_ore", 20, "mineral")
	register_price("gold_ore", 40, "mineral")
	register_price("diamond", 100, "mineral")

	# Artisan goods (from InfrastructureManager)
	register_price("wine", 80, "artisan")
	register_price("pickle", 50, "artisan")
	register_price("mayonnaise", 40, "artisan")
	register_price("fruit", 15, "crop")
	register_price("vegetable", 15, "crop")

	# Cooked food (from CookingManager)
	register_price("parsnip_soup", 50, "cooked")
	register_price("cauliflower_stew", 90, "cooked")
	register_price("tomato_soup", 60, "cooked")
	register_price("pumpkin_pie", 130, "cooked")
	register_price("fish_stew", 70, "cooked")

static func register_price(item_id: String, base_price: int, category: String = "misc") -> void:
	if item_id.is_empty() or base_price <= 0:
		return
	_prices[item_id] = {"base_price": base_price, "category": category}

static func has_price(item_id: String) -> bool:
	_ensure_initialized()
	var base_id := _strip_quality_suffix(item_id)
	return _prices.has(base_id)

static func get_base_price(item_id: String) -> int:
	_ensure_initialized()
	var base_id := _strip_quality_suffix(item_id)
	var entry: Dictionary = _prices.get(base_id, {})
	return entry.get("base_price", 0)

static func get_category(item_id: String) -> String:
	_ensure_initialized()
	var base_id := _strip_quality_suffix(item_id)
	var entry: Dictionary = _prices.get(base_id, {})
	return entry.get("category", "misc")

static func get_price(item_id: String, quality: String = QUALITY_NORMAL) -> int:
	_ensure_initialized()
	var base := get_base_price(item_id)
	if base == 0:
		return 0
	var mult: float = QUALITY_PRICE_MULTIPLIER.get(quality, 1.0)
	# Skill perk hook: if Farming skill has hit level 5, grant +10% sell price.
	# Headless-safe: SkillManager may not be loaded in all contexts.
	var bonus_mult := 1.0
	if Engine.has_singleton("SkillManager") or _has_autoload("SkillManager"):
		# SkillManager is an autoload Node, not an Engine singleton.
		# Use global lookup via root.
		var sm = _get_skill_manager()
		if sm != null and sm.has_method("get_sell_price_multiplier"):
			bonus_mult = sm.get_sell_price_multiplier()
	mult *= bonus_mult
	return int(round(base * mult))

static func get_all_prices() -> Dictionary:
	_ensure_initialized()
	return _prices.duplicate(true)

static func _strip_quality_suffix(item_id: String) -> String:
	# Item ids encode quality as suffix: "parsnip_gold", "parsnip_silver".
	# Registry stores base id only. Strip known suffixes.
	if item_id.ends_with("_gold"):
		return item_id.substr(0, item_id.length() - 5)
	if item_id.ends_with("_silver"):
		return item_id.substr(0, item_id.length() - 7)
	return item_id

# --- helpers to reach autoloads without hard import ---

static func _has_autoload(name: String) -> bool:
	# In headless test runner, autoloads are children of root.
	if Engine.get_main_loop() == null:
		return false
	var root = (Engine.get_main_loop() as SceneTree).root
	if root == null:
		return false
	return root.has_node(name)

static func _get_skill_manager() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root = (Engine.get_main_loop() as SceneTree).root
	if root == null:
		return null
	return root.get_node_or_null("SkillManager")

static func list_item_ids() -> Array:
	_ensure_initialized()
	return _prices.keys()

static func clear() -> void:
	# Test helper: reset to uninitialized so next call re-registers defaults.
	_prices.clear()
	_initialized = false
