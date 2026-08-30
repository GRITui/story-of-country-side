extends Node
## Autoload: ModManager
## Implements #119: Modding-lite.
## Loads user content packs from a local 'mods/' directory to extend game content.

signal mod_loaded(mod_name: String)

const MODS_DIR := "user://mods/"

func _ready() -> void:
	# Ensure directory exists
	if not DirAccess.dir_exists_absolute(MODS_DIR):
		DirAccess.make_dir_recursive_absolute(MODS_DIR)
	
	_load_mods()

func _load_mods() -> void:
	var dir = DirAccess.open(MODS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				_process_mod_file(file_name)
			file_name = dir.get_next()
	print("ModManager: Mod loading sequence complete.")

func _process_mod_file(file_name: String) -> void:
	var path = MODS_DIR + file_name
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		print("ModManager: Failed to parse mod %s: %s" % [file_name, json.get_error_message()])
		return
	
	var data = json.data
	if not data is Dictionary:
		return
	
	var mod_name = data.get("name", "Unknown Mod")
	
	# Inject content into relevant managers if they exist
	if data.has("crops"):
		_inject_crops(data["crops"])
	if data.has("festivals"):
		_inject_festivals(data["festivals"])
	if data.has("sfx"):
		_inject_sfx(data["sfx"])
	
	mod_loaded.emit(mod_name)
	print("ModManager: Loaded mod [%s]" % mod_name)

func _inject_crops(crops_data: Array) -> void:
	for crop in crops_data:
		# We reuse the logic from FarmPlotManager's registration
		# This assumes FarmPlotManager has a public register_crop() method
		if FarmPlotManager and FarmPlotManager.has_method("register_crop"):
			FarmPlotManager.register_crop(crop)

func _inject_festivals(fest_data: Array) -> void:
	for fest in fest_data:
		if FestivalManager:
			# Use the helper used in FestivalManager's registration
			var def = FestivalManager._make_festival(
				fest.get("id", ""), 
				fest.get("name", ""), 
				fest.get("season", ""), 
				fest.get("day", 0), 
				fest.get("flavor", "")
			)
			FestivalManager.register_festival(def)

func _inject_sfx(sfx_data: Array) -> void:
	for sfx in sfx_data:
		if AudioManager:
			if sfx.get("kind") == "asset":
				AudioManager.register_sfx_asset(sfx.get("id", ""), sfx.get("path", ""))
			else:
				AudioManager.register_sfx(sfx.get("id", ""), sfx.get("freq", 440.0), sfx.get("dur", 0.1))
