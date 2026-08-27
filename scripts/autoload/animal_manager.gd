extends Node
## Autoload: AnimalManager
##
## Ranching (#14): daily feeding/brushing loop, egg/milk/wool harvest
## outputs tied to happiness/care level, keyed off TimeManager.day_started
## the same way FarmPlotManager (#13) ticks crop growth. Depends on the
## Time & Stamina foundation (already merged) and consumes InventoryManager
## + SkillManager (#13's InventoryManager gap-fill, #25's XP hook) the same
## way FarmPlotManager does -- collect_product() never calls
## ShippingBinManager directly, same "player pulls from inventory, ships
## it" boundary #13 established.
##
## Ranching feeds the Farming skill, not a separate one -- documented
## decision from #25's interface notes (SDV precedent: ranching outputs
## count toward the same Farming skill as crops).
##
## Product progress only advances on a day the animal was fed (mirrors
## FarmPlotManager's "growth only advances if watered" rule) -- an unfed
## animal loses happiness and makes no progress toward its next product.
## Brushing doesn't gate production, only happiness (the genre's own
## precedent: brushing is a bonus-affection action, feeding is the
## required one). Quality tiers are a direct, deterministic mapping from
## happiness at collection time (not FarmPlotManager's weighted RNG roll)
## because #14 explicitly ties quality to "happiness/care level," unlike
## #13 which left quality tiers unspecified -- worth reconsidering
## together with FarmPlotManager's approach once real playtesting exists.
##
## No feed-item economy (hay/silo) or animal-purchase cost exists anywhere
## in this repo -- add_animal()/feed() are free actions, same "no
## unrequested economy" boundary #13's plant_seed() drew for seeds.
##
## Content pass (#53): expanded from 3 to 5 species and retuned wool's
## price for internal consistency. Per-fed-day value across the roster:
## chicken 20/day, cow 30/day, duck 22.5/day (2-day), goat 27.5/day
## (2-day), sheep 25/day (3-day, bumped from 60 to 75 -- the original
## price left a 3-day producer earning the exact same 20/day as a 1-day
## producer, no reward for the longer commitment). This roughly brackets
## Agriculture's single-harvest crops (9-20 gold/day, see
## FarmPlotManager) since ranching is a recurring daily chore rather than
## a one-off harvest.


signal animal_added(animal_id: String, species_id: String)
signal animal_fed(animal_id: String)
signal animal_brushed(animal_id: String)
signal product_collected(animal_id: String, item_id: String, quality: String, quantity: int)

const QUALITY_NORMAL := "normal"
const QUALITY_SILVER := "silver"
const QUALITY_GOLD := "gold"

const HAPPINESS_MIN := 0
const HAPPINESS_MAX := 100
const HAPPINESS_DEFAULT := 50

## MVP placeholder tuning, not final balance.
const FEED_HAPPINESS_DELTA := 10
const BRUSH_HAPPINESS_DELTA := 10
const NEGLECT_HAPPINESS_DELTA := 20
const QUALITY_GOLD_HAPPINESS := 80
const QUALITY_SILVER_HAPPINESS := 50
const QUALITY_PRICE_MULTIPLIER := {
	QUALITY_NORMAL: 1.0,
	QUALITY_SILVER: 1.25,
	QUALITY_GOLD: 1.5,
}

var _definitions: Dictionary = {} # species_id -> AnimalDefinition
var _animals: Dictionary = {}     # animal_id (String) -> Animal

func _ready() -> void:
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

## Content pass (#53): chicken/cow/sheep kept as-is (species_id and
## product_item_id, e.g. "wool", are referenced elsewhere -- see
## InfrastructureManager's mayo-machine quest and CommunityGoalManager's
## fish_tank/pantry-style bundles) except sheep's price, retuned for
## consistency (see top-of-file docstring). Two new species added: duck
## (a faster second poultry option) and goat (a faster second dairy
## option), both 2-day producers slotting between chicken/cow and sheep.
func _register_default_content() -> void:
	# Migrate all animal product base sell prices to PriceRegistry
	PriceRegistry.register_price("egg", 20)
	PriceRegistry.register_price("duck_egg", 45)
	PriceRegistry.register_price("milk", 30)
	PriceRegistry.register_price("goat_milk", 55)
	PriceRegistry.register_price("wool", 75)
	
	# Continue with existing animal registration (keeping existing logic)
	register_species(_make_def("chicken", "Chicken", "egg", 1, PriceRegistry.get_price("egg"), 3))
	register_species(_make_def("duck", "Duck", "duck_egg", 2, PriceRegistry.get_price("duck_egg"), 5))
	register_species(_make_def("cow", "Cow", "milk", 1, PriceRegistry.get_price("milk"), 4))
	register_species(_make_def("goat", "Goat", "goat_milk", 2, PriceRegistry.get_price("goat_milk"), 6))
	register_species(_make_def("sheep", "Sheep", "wool", 3, PriceRegistry.get_price("wool"), 8))

func _make_def(species_id: String, display_name: String, product_item_id: String,
	days_between_products: int, base_sell_price: int, xp_reward: int) -> AnimalDefinition:
	var def := AnimalDefinition.new()
	def.species_id = species_id
	def.display_name = display_name
	def.product_item_id = product_item_id
	def.days_between_products = days_between_products
	def.base_sell_price = base_sell_price
	def.xp_reward = xp_reward
	return def

## Re-registering the same species_id is a content overwrite (last write
## wins), same convention as ToolManager.register_tier / FarmPlotManager.register_crop.
func register_species(def: AnimalDefinition) -> void:
	if def == null or def.species_id.is_empty():
		return
	_definitions[def.species_id] = def

func get_species_definition(species_id: String) -> AnimalDefinition:
	return _definitions.get(species_id)

func get_animal(animal_id: String) -> Animal:
	return _animals.get(animal_id)

## Every registered animal_id -- read-only integration point for
## InfrastructureManager's auto-feeder/collection-hub automation devices,
## so they can feed()/collect_product() every animal without reaching
## into _animals directly.
func get_all_animal_ids() -> Array:
	return _animals.keys()

func has_animal(animal_id: String) -> bool:
	return _animals.has(animal_id)

## Fails if species_id isn't registered or animal_id is already taken --
## no purchase cost, see this file's top-of-file docstring.
func add_animal(animal_id: String, species_id: String) -> bool:
	if animal_id.is_empty() or _animals.has(animal_id):
		return false
	if not _definitions.has(species_id):
		return false
	var animal := Animal.new()
	animal.species_id = species_id
	_animals[animal_id] = animal
	animal_added.emit(animal_id, species_id)
	return true

## Once per day per animal -- required for that day's production progress
## and to avoid the neglect happiness penalty. No feed-item cost, see this
## file's top-of-file docstring.
func feed(animal_id: String) -> bool:
	var animal: Animal = _animals.get(animal_id)
	if animal == null or animal.fed_today:
		return false
	animal.fed_today = true
	animal_fed.emit(animal_id)
	return true

## Once per day per animal -- happiness-only, does not gate production.
func brush(animal_id: String) -> bool:
	var animal: Animal = _animals.get(animal_id)
	if animal == null or animal.brushed_today:
		return false
	animal.brushed_today = true
	animal_brushed.emit(animal_id)
	return true

## Collects a ready animal's product: maps current happiness to a quality
## tier, credits InventoryManager and Farming XP, then resets the animal
## toward its next product cycle (animals are never removed, unlike a
## non-regrowable crop -- every species regrows indefinitely). Returns {}
## on any failure (no animal, not ready, unknown species).
func collect_product(animal_id: String) -> Dictionary:
	var animal: Animal = _animals.get(animal_id)
	if animal == null or not animal.product_ready:
		return {}
	var def: AnimalDefinition = _definitions.get(animal.species_id)
	if def == null:
		return {}

	var quality := _quality_for_happiness(animal.happiness)
	var item_id := get_item_id(def.product_item_id, quality)
	var quantity := 1

	InventoryManager.add_item(item_id, quantity)
	SkillManager.add_xp("Farming", def.xp_reward)

	animal.days_since_product = 0
	animal.product_ready = false

	product_collected.emit(animal_id, item_id, quality, quantity)
	return {"item_id": item_id, "quality": quality, "quantity": quantity, "species_id": animal.species_id}

## Quality tiers are encoded into the inventory item_id itself (e.g. "egg"
## vs. "egg_gold"), same convention as FarmPlotManager.get_item_id -- no
## per-stack quality field on InventoryManager's plain id->quantity ledger.
func get_item_id(product_item_id: String, quality: String) -> String:
	if quality == QUALITY_NORMAL or quality.is_empty():
		return product_item_id
	return "%s_%s" % [product_item_id, quality]

func get_sell_price(species_id: String, quality: String) -> int:
	var def: AnimalDefinition = _definitions.get(species_id)
	if def == null:
		return 0
	var mult: float = QUALITY_PRICE_MULTIPLIER.get(quality, 1.0)
	return int(round(def.base_sell_price * mult))

func _quality_for_happiness(happiness: int) -> String:
	if happiness >= QUALITY_GOLD_HAPPINESS:
		return QUALITY_GOLD
	if happiness >= QUALITY_SILVER_HAPPINESS:
		return QUALITY_SILVER
	return QUALITY_NORMAL

## Daily tick: an unfed animal loses happiness and makes no product
## progress; a fed animal gains happiness (plus a brushing bonus) and
## advances toward its next product. fed_today/brushed_today reset for
## every animal regardless, same "state resets on day change" rule
## FarmPlotManager's watered_today follows.
func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	for animal_id in _animals.keys():
		var animal: Animal = _animals[animal_id]
		var def: AnimalDefinition = _definitions.get(animal.species_id)
		if def == null:
			animal.fed_today = false
			animal.brushed_today = false
			continue

		if animal.fed_today:
			var gain := FEED_HAPPINESS_DELTA + (BRUSH_HAPPINESS_DELTA if animal.brushed_today else 0)
			animal.happiness = clampi(animal.happiness + gain, HAPPINESS_MIN, HAPPINESS_MAX)
			if not animal.product_ready:
				animal.days_since_product += 1
				if animal.days_since_product >= def.days_between_products:
					animal.product_ready = true
		else:
			animal.happiness = clampi(animal.happiness - NEGLECT_HAPPINESS_DELTA, HAPPINESS_MIN, HAPPINESS_MAX)

		animal.fed_today = false
		animal.brushed_today = false

func to_save_dict() -> Dictionary:
	var animals_data: Dictionary = {}
	for animal_id: String in _animals.keys():
		animals_data[animal_id] = (_animals[animal_id] as Animal).to_dict()
	return {"animals": animals_data}

func from_save_dict(data: Dictionary) -> void:
	_animals.clear()
	var raw: Dictionary = data.get("animals", {})
	for animal_id: String in raw.keys():
		_animals[animal_id] = Animal.from_dict(raw[animal_id])
