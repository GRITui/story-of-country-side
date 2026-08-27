extends Node
## Autoload: JournalManager
##
## Tracks discovered items across all categories (ENG-117): crops, animal
## products, fish, ore, forage. Listens to harvest/collect/catch signals
## from each activity manager so the player sees a discoverable encyclopedia
## of found items.
##
## Debug: remove_discovery(item_id) for content testing; get_raw_map()
## exposes internal state for QA.
##
## Categories: 
##   "crop"     — FarmPlotManager.crop_harvested
##   "animal"   — AnimalManager.product_collected
##   "fish"     — FishingManager.catch
##   "ore"      — MiningManager.rock_broken (item_id of ore)
##   "forage"   — ForagingManager.forage_gathered
##
## Content lane: expose clear getters (get_discovered/is_discovered/get_total)
## for frontend overlays; Frontend lane: render the journal UI.

## State
var _discovered: Dictionary = {}  # category -> Set[item_id]

## Signals
signal item_discovered(category: String, item_id: String)
signal journal_cleared()  # reset for testing/rollback

func _ready() -> void:
	# Connect to activity managers
	if FarmPlotManager:
		FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	if AnimalManager:
		AnimalManager.product_collected.connect(_on_animal_product_collected)
	if FishingManager:
		FishingManager.catch.connect(_on_fish_caught)
	if MiningManager:
		MiningManager.rock_broken.connect(_on_ore_mined)
	if ForagingManager:
		ForagingManager.forage_gathered.connect(_on_forage_collected)

## Public API
func get_discovered(category: String) -> Array[String]:
	return _discovered.get(category, {}).keys()

func get_total(category: String) -> int:
	var set := _discovered.get(category, {})
	return set.size()

func is_discovered(item_id: String, category: String = "any") -> bool:
	if category == "any":
		for cat_set in _discovered.values():
			if cat_set.has(item_id):
				return true
		return false
	else:
		var cat_set := _discovered.get(category, {})
		return cat_set.has(item_id)

func get_all_categories() -> Array[String]:
	return _discovered.keys()

func clear_journal() -> void:
	_discovered.clear()
	journal_cleared.emit()

## Debug/testing helper
func remove_discovery(category: String, item_id: String) -> bool:
	var cat_set := _discovered.get(category)
	if cat_set and cat_set.has(item_id):
		cat_set.erase(item_id)
		return true
	return false

func get_raw_map() -> Dictionary:
	var copy: Dictionary = {}
	for cat in _discovered:
		copy[cat] = _discovered[cat].keys()
	return copy

## Internal signal handlers
func _on_crop_harvested(_position: Vector2i, item_id: String, _quality: String, _quantity: int) -> void:
	_discover_item("crop", item_id)

func _on_animal_product_collected(_animal_id: String, item_id: String, _quality: String, _quantity: int) -> void:
	_discover_item("animal", item_id)

func _on_fish_caught(_position: Vector2i, item_id: String, _quality: String, _quantity: int) -> void:
	_discover_item("fish", item_id)

func _on_ore_mined(_tile: Vector2i, item_id: String, _quantity: int) -> void:
	_discover_item("ore", item_id)

func _on_forage_collected(_position: Vector2i, item_id: String, _quantity: int) -> void:
	_discover_item("forage", item_id)

func _discover_item(category: String, item_id: String) -> void:
	var cat_set := _discovered.get(category)
	if not cat_set:
		cat_set = {}
		_discovered[category] = cat_set
	if not cat_set.has(item_id):
		cat_set.insert(item_id)
		item_discovered.emit(category, item_id)

func to_save_dict() -> Dictionary:
	var copy: Dictionary = {}
	for cat in _discovered:
		copy[cat] = _discovered[cat].keys()
	return copy

func from_save_dict(data: Dictionary) -> void:
	_discovered.clear()
	for cat in data:
		_discovered[cat] = {}
		for item_id in data[cat]:
			_discovered[cat][item_id] = true
