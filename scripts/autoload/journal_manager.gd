extends Node
## Autoload: JournalManager
## Implements #117: Collection Journal (Encyclopedia).

signal item_discovered(category: String, item_id: String)

const CATEGORIES = ["Fish", "Crops", "Ores", "Forage"]
var _discovered: Dictionary = {} ## category -> {item_id: bool}

func _ready() -> void:
	for cat in CATEGORIES:
		_discovered[cat] = {}

func discover(category: String, item_id: String) -> void:
	if not _discovered.has(category): return
	if not _discovered[category].has(item_id):
		_discovered[category][item_id] = true
		item_discovered.emit(category, item_id)

func is_discovered(category: String, item_id: String) -> bool:
	return _discovered.get(category, {}).get(item_id, false)

func get_discovery_progress(category: String) -> float:
	# In a real version, compare against a master list of all item_ids
	return 0.0 # Placeholder for total discovered / total possible

func to_save_dict() -> Dictionary:
	return _discovered.duplicate()

func from_save_dict(data: Dictionary) -> void:
	_discovered = (data as Dictionary).duplicate()
