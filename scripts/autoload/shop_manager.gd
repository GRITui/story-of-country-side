extends Node
## Autoload: ShopManager
##
## Seed-shop front door for ENG-91 economy: lists purchasable seeds and
## sells them against the player's gold. Deliberately minimal -- only
## seeds exist as purchasables today; the same register_/list_/buy_ shape
## extends to other shop inventories later without a redesign.
##
## Gold path: buys go through ShippingBinManager.spend(), the wallet owner
## (ENG-22) -- this manager never touches ShippingBinManager.gold
## directly, same contract discipline every consumer follows. Purchased
## stock lands in InventoryManager via add_item(); planting then consumes
## it through FarmPlotManager.plant()'s own gate, so no shop->farm
## shortcut exists.
##
## Catalog coverage: _register_default_content() lists one seed per
## currently-registered FarmPlotManager crop (7/7). It is an explicit
## table -- not auto-derived from FarmPlotManager at runtime -- so
## Content can tune per-seed prices/display names as literal values
## (Content lane may edit registered values, not logic, per
## SQUAD-SPLIT.md). The test suite asserts catalog-vs-crop parity so a
## future crop added without a seed fails loudly instead of shipping
## unplantable.
##
## Prices carry the final econ-balance blueprint values (see register table below).

signal seed_purchased(seed_id: String, price: int)

var _seeds: Dictionary = {} # seed_id -> SeedDefinition

func _ready() -> void:
	_register_default_content()

## Seed prices carry the final econ-balance blueprint values (parsnip 12,
## cauliflower 45, tomato 30, melon 70, pumpkin 60, corn 35, frost_kale 40).
## Matches FarmPlotManager CropDefinition.seed_price — keep the two in sync.
func _register_default_content() -> void:
	register_seed(_make_seed("parsnip_seed", "Parsnip Seeds", "parsnip", 12, "Spring"))
	register_seed(_make_seed("cauliflower_seed", "Cauliflower Seeds", "cauliflower", 45, "Spring"))
	register_seed(_make_seed("tomato_seed", "Tomato Seeds", "tomato", 30, "Summer"))
	register_seed(_make_seed("melon_seed", "Melon Seeds", "melon", 70, "Summer"))
	register_seed(_make_seed("pumpkin_seed", "Pumpkin Seeds", "pumpkin", 60, "Fall"))
	register_seed(_make_seed("corn_seed", "Corn Seeds", "corn", 35, "Fall"))
	register_seed(_make_seed("frost_kale_seed", "Frost Kale Seeds", "frost_kale", 40, "Winter"))

func _make_seed(seed_id: String, display_name: String, crop_id: String, price: int, season: String) -> SeedDefinition:
	var def := SeedDefinition.new()
	def.seed_id = seed_id
	def.display_name = display_name
	def.crop_id = crop_id
	def.price = price
	def.season = season
	return def

## Re-registering the same seed_id is a content overwrite (last write
## wins), same convention as ToolManager.register_tier /
## FestivalManager.register_festival.
func register_seed(def: SeedDefinition) -> void:
	if def == null or def.seed_id.is_empty():
		return
	_seeds[def.seed_id] = def

func get_seed_definition(seed_id: String) -> SeedDefinition:
	return _seeds.get(seed_id)

func get_seed_price(seed_id: String) -> int:
	var def: SeedDefinition = _seeds.get(seed_id)
	if def == null:
		return 0
	return def.price

func get_all_seed_ids() -> Array[String]:
	var ids: Array[String] = []
	for seed_id: String in _seeds.keys():
		ids.append(seed_id)
	ids.sort()
	return ids

## Shop-listing projection: one {seed_id, display_name, crop_id, price,
## season} dict per registered seed, sorted by seed_id for deterministic
## UI order. Returns plain dictionaries (not Resources) so a read-only
## listing never hands callers a live reference into the catalog.
func list_seeds() -> Array[Dictionary]:
	var listing: Array[Dictionary] = []
	for seed_id: String in get_all_seed_ids():
		var def: SeedDefinition = _seeds[seed_id]
		listing.append({
			"seed_id": def.seed_id,
			"display_name": def.display_name,
			"crop_id": def.crop_id,
			"price": def.price,
			"season": def.season,
		})
	return listing

## Buys exactly one seed of seed_id: spends its price via the gold
## owner's public spend() (which already rejects unaffordable/non-positive
## amounts) and credits one seed item to InventoryManager. Returns false
## (nothing spent, nothing granted) for an unknown seed_id or insufficient
## gold -- check-before-spend, mirroring ToolManager.upgrade_tool's
## pattern so a failed purchase never leaves a partial ledger change.
func buy_seed(seed_id: String, quantity: int = 1) -> bool:
	var def: SeedDefinition = _seeds.get(seed_id)
	if def == null or quantity <= 0:
		return false
	var total_cost := def.price * quantity
	if not ShippingBinManager.spend(total_cost):
		return false
	InventoryManager.add_item(seed_id, quantity)
	seed_purchased.emit(seed_id, total_cost)
	return true
