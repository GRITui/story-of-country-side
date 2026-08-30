extends Node
## Autoload: JournalManager (#117)
##
## Collection journal -- the 60-hour retention loop. Tracks first-discovery
## of fish/crop/ore/forage items as they flow through existing signals:
##   fish_caught (FishingManager) -> category "fish"
##   crop_harvested (FarmPlotManager) -> category "crop"
##   rock_broken (MiningManager) -> category "ore"
##   forage_gathered (ForagingManager) -> category "forage"
##
## No polling. _ready() hooks all four signals; every _on_* handler calls
## _mark_discovered which is idempotent (second discovery is a no-op).
##
## Persistence: to_save_dict/from_save_dict, same shape as every other
## manager SaveManager already calls. Day stamp uses TimeManager.day if
## available, else 0 (headless tests have no clock).
##
## Public API:
##   is_discovered(item_id)                    -> bool
##   get_all_discovered()                      -> Array[String]
##   get_discovered_by_category(cat)           -> Array[String]
##   get_progress(category)                    -> Dictionary {discovered, total, ratio}
##   get_all_progress()                        -> Dictionary cat -> progress dict
##   get_catalog(category)                     -> Array[String] (all known ids for progress denominator)
##
## Category strings are canonicalized: "fish"/"crop"/"ore"/"forage" (lowercase
## singular). Plural aliases "crops"/"ores"/"forages" and "fishes" are
## accepted by get_progress/get_catalog via _canonical_category().
##
## Catalog for total counts is built dynamically: tries to read each
## manager's _definitions directly (private but accessible in GDScript) so
## content additions automatically grow the denominator without touching
## this file. Falls back to a hardcoded snapshot of the current default
## content if that introspection fails (headless tests mock managers, etc.).

signal entry_discovered(item_id: String, category: String)
signal journal_cleared

const CATEGORIES := ["fish", "crop", "ore", "forage"]

## Hardcoded fallback catalog -- snapshot of the default content at the
## time this was written. Used only if manager introspection fails.
const FALLBACK_CATALOG := {
	"fish": ["bream", "bass", "carp", "eel", "pike", "salmon", "sardine", "squid", "sturgeon", "trout", "tuna"],
	"crop": ["cauliflower", "corn", "frost_kale", "melon", "parsnip", "pumpkin", "tomato"],
	"ore": ["stone", "copper_ore", "iron_ore", "gold_ore", "diamond"],
	"forage": ["four_leaf_clover", "hazelnut", "mushroom", "snow_truffle", "spring_onion", "sweet_pea", "wild_berries", "wild_flower", "winter_root"],
}

var _discovered: Dictionary = {} # item_id -> JournalEntry (Resource)
var _by_category: Dictionary = {} # category -> Dictionary item_id -> true (set)

func _ready() -> void:
	for cat in CATEGORIES:
		_by_category[cat] = {}
	# Defer signal wiring one frame so autoload order doesn't matter -- if
	# FishingManager etc. haven't run _ready yet, they'll exist as nodes
	# but their signals are still valid to connect to.
	if not FishingManager.fish_caught.is_connected(_on_fish_caught):
		FishingManager.fish_caught.connect(_on_fish_caught)
	if not FarmPlotManager.crop_harvested.is_connected(_on_crop_harvested):
		FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	if not MiningManager.rock_broken.is_connected(_on_rock_broken):
		MiningManager.rock_broken.connect(_on_rock_broken)
	if not ForagingManager.forage_gathered.is_connected(_on_forage_gathered):
		ForagingManager.forage_gathered.connect(_on_forage_gathered)

func _canonical_category(cat: String) -> String:
	var lower := cat.to_lower()
	match lower:
		"crops", "crop":
			return "crop"
		"fish", "fishes":
			return "fish"
		"ores", "ore":
			return "ore"
		"forages", "forage":
			return "forage"
		_:
			return lower

func _normalize_item_id(raw: String, _category: String) -> String:
	# Strip quality suffixes added by FarmPlotManager/FishingManager
	# (e.g. "parsnip_gold" -> "parsnip", "trout_silver" -> "trout")
	if raw.ends_with("_gold"):
		return raw.substr(0, raw.length() - 5)
	if raw.ends_with("_silver"):
		return raw.substr(0, raw.length() - 7)
	return raw

func _resolve_display_name(item_id: String, category: String) -> String:
	match category:
		"fish":
			var def = FishingManager.get_fish_definition(item_id)
			if def != null and not def.display_name.is_empty():
				return def.display_name
		"crop":
			var def2 = FarmPlotManager.get_crop_definition(item_id)
			if def2 != null and not def2.display_name.is_empty():
				return def2.display_name
		"forage":
			var def3 = ForagingManager.get_forageable_definition(item_id)
			if def3 != null and not def3.display_name.is_empty():
				return def3.display_name
		"ore":
			# OreDefinition has no display_name field, use item_id capitalized
			return item_id.capitalize().replace("_", " ")
	return item_id.capitalize().replace("_", " ")

func _current_day() -> int:
	if TimeManager == null:
		return 0
	if "day" in TimeManager:
		return TimeManager.day
	if TimeManager.has_method("current_day"):
		return TimeManager.current_day()
	if TimeManager.has_method("get_day"):
		return TimeManager.get_day()
	return 0

func _mark_discovered(raw_item_id: String, category: String) -> void:
	var cat := _canonical_category(category)
	if not _by_category.has(cat):
		return
	var item_id := _normalize_item_id(raw_item_id, cat)
	if item_id.is_empty():
		return
	if _discovered.has(item_id):
		return
	var entry = preload("res://scripts/journal/journal_entry.gd").new()
	entry.item_id = item_id
	entry.category = cat
	entry.discovered_day = _current_day()
	entry.display_name = _resolve_display_name(item_id, cat)
	_discovered[item_id] = entry
	(_by_category[cat] as Dictionary)[item_id] = true
	entry_discovered.emit(item_id, cat)

func is_discovered(item_id: String) -> bool:
	var norm := _normalize_item_id(item_id, "")
	return _discovered.has(norm) or _discovered.has(item_id)

func get_all_discovered() -> Array[String]:
	var result: Array[String] = []
	for key in _discovered.keys():
		result.append(key)
	result.sort()
	return result

func get_discovered_by_category(category: String) -> Array[String]:
	var cat := _canonical_category(category)
	if not _by_category.has(cat):
		return []
	var result: Array[String] = []
	for k in (_by_category[cat] as Dictionary).keys():
		result.append(k)
	result.sort()
	return result

func get_catalog(category: String) -> Array[String]:
	var cat := _canonical_category(category)
	match cat:
		"fish":
			var dyn := _catalog_from_manager(FishingManager, "_definitions")
			if not dyn.is_empty():
				return dyn
		"crop":
			var dyn2 := _catalog_from_manager(FarmPlotManager, "_definitions")
			if not dyn2.is_empty():
				return dyn2
		"ore":
			# MiningManager stores ores as Array, not Dictionary -- handle separately
			var ores := _ore_catalog()
			if not ores.is_empty():
				return ores
		"forage":
			var dyn3 := _catalog_from_manager(ForagingManager, "_definitions")
			if not dyn3.is_empty():
				return dyn3
	var fallback: Array = FALLBACK_CATALOG.get(cat, [])
	var out: Array[String] = []
	for id in fallback:
		out.append(id)
	out.sort()
	return out

func _catalog_from_manager(manager: Node, dict_name: String) -> Array[String]:
	var out: Array[String] = []
	if manager == null:
		return out
	# Access private _definitions via get() or direct property
	var defs = null
	if dict_name in manager:
		defs = manager.get(dict_name)
	if defs is Dictionary and not (defs as Dictionary).is_empty():
		for k in (defs as Dictionary).keys():
			out.append(k)
		out.sort()
	return out

func _ore_catalog() -> Array[String]:
	var out: Array[String] = []
	if MiningManager == null:
		return out
	# MiningManager._ore_definitions is Array[OreDefinition] plus STONE_ITEM_ID
	out.append(MiningManager.STONE_ITEM_ID)
	if "_ore_definitions" in MiningManager:
		var arr = MiningManager.get("_ore_definitions")
		if arr is Array:
			for def in arr as Array:
				if def != null and "item_id" in def and not def.item_id.is_empty():
					if not out.has(def.item_id):
						out.append(def.item_id)
	out.sort()
	return out

func get_progress(category: String) -> Dictionary:
	var cat := _canonical_category(category)
	var catalog := get_catalog(cat)
	var total := catalog.size()
	var discovered := get_discovered_by_category(cat).size()
	var ratio := 0.0 if total == 0 else float(discovered) / float(total)
	return {"category": cat, "discovered": discovered, "total": total, "ratio": ratio}

func get_all_progress() -> Dictionary:
	var result := {}
	for cat in CATEGORIES:
		result[cat] = get_progress(cat)
	return result

func get_entry(item_id: String):
	var norm := _normalize_item_id(item_id, "")
	if _discovered.has(norm):
		return _discovered[norm]
	return _discovered.get(item_id)

## Test helper: inject a discovery without needing a real signal.
func debug_discover(item_id: String, category: String) -> void:
	_mark_discovered(item_id, category)

## Clears all discoveries (used by new_game reset and tests).
func clear_all() -> void:
	_discovered.clear()
	for cat in _by_category.keys():
		(_by_category[cat] as Dictionary).clear()
	journal_cleared.emit()

# Signal handlers

func _on_fish_caught(fish_id: String, _quality: String, _quantity: int) -> void:
	_mark_discovered(fish_id, "fish")

func _on_crop_harvested(_position: Vector2i, item_id: String, _quality: String, _quantity: int) -> void:
	_mark_discovered(item_id, "crop")

func _on_rock_broken(_tile: Vector2i, item_id: String, _quantity: int) -> void:
	_mark_discovered(item_id, "ore")

func _on_forage_gathered(_position: Vector2i, item_id: String, _quantity: int) -> void:
	_mark_discovered(item_id, "forage")

# Persistence

func to_save_dict() -> Dictionary:
	var entries := {}
	for item_id in _discovered.keys():
		var e = _discovered[item_id]
		entries[item_id] = e.to_dict()
	return {"discovered": entries}

func from_save_dict(data: Dictionary) -> void:
	clear_all()
	var entries: Dictionary = data.get("discovered", {})
	for item_id in entries.keys():
		var dict: Dictionary = entries[item_id]
		var entry = preload("res://scripts/journal/journal_entry.gd").from_dict(dict)
		if entry.item_id.is_empty():
			continue
		_discovered[entry.item_id] = entry
		var cat := _canonical_category(entry.category)
		if not _by_category.has(cat):
			_by_category[cat] = {}
		(_by_category[cat] as Dictionary)[entry.item_id] = true
