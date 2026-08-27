extends Node
## Autoload: SettingsManager
##
## Minimal, headless-testable settings backend (volume master/music/sfx,
## fullscreen, key rebind map). Persists to user://settings.json.
## Registered in project.godot [autoload] so any scene can read/write via
## SettingsManager.get_volume() etc without needing to instantiate.

const SETTINGS_PATH := "user://settings.json"

var master_volume: float = SettingsDefinition.DEFAULT_MASTER_VOLUME
var music_volume: float = SettingsDefinition.DEFAULT_MUSIC_VOLUME
var sfx_volume: float = SettingsDefinition.DEFAULT_SFX_VOLUME
var fullscreen: bool = SettingsDefinition.DEFAULT_FULLSCREEN
var key_rebinds: Dictionary = {}

signal settings_changed(key: String, value: Variant)

func _ready() -> void:
	load_settings()

func _apply_fullscreen() -> void:
	# Headless / dummy display may not support mode switching — guard.
	if not DisplayServer.get_name() == "headless":
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_volumes() -> void:
	# Audio bus application is best-effort; headless has no real buses.
	# Use linear_to_db with clamping; ignore errors if bus not found.
	var buses := {
		"Master": master_volume,
		"Music": music_volume,
		"SFX": sfx_volume,
	}
	for bus_name in buses.keys():
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			continue
		var vol: float = SettingsDefinition.clamp_volume(buses[bus_name])
		var db: float = linear_to_db(vol) if vol > 0.001 else -80.0
		AudioServer.set_bus_volume_db(idx, db)

func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"key_rebinds": key_rebinds.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	master_volume = SettingsDefinition.clamp_volume(float(data.get("master_volume", SettingsDefinition.DEFAULT_MASTER_VOLUME)))
	music_volume = SettingsDefinition.clamp_volume(float(data.get("music_volume", SettingsDefinition.DEFAULT_MUSIC_VOLUME)))
	sfx_volume = SettingsDefinition.clamp_volume(float(data.get("sfx_volume", SettingsDefinition.DEFAULT_SFX_VOLUME)))
	fullscreen = bool(data.get("fullscreen", SettingsDefinition.DEFAULT_FULLSCREEN))
	var rb: Variant = data.get("key_rebinds", {})
	if typeof(rb) == TYPE_DICTIONARY:
		key_rebinds = (rb as Dictionary).duplicate(true)
	else:
		key_rebinds = {}

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SettingsManager: failed to open %s for writing" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(to_dict()))
	file.close()

func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		reset_to_defaults(false)
		return false
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		reset_to_defaults(false)
		return false
	from_dict(parsed)
	_apply_volumes()
	_apply_fullscreen()
	return true

func reset_to_defaults(persist: bool = true) -> void:
	var d := SettingsDefinition.default_settings()
	from_dict(d)
	_apply_volumes()
	_apply_fullscreen()
	if persist:
		save_settings()

func set_volume(bus: String, value: float) -> void:
	var clamped := SettingsDefinition.clamp_volume(value)
	match bus:
		"master":
			master_volume = clamped
			settings_changed.emit("master_volume", clamped)
		"music":
			music_volume = clamped
			settings_changed.emit("music_volume", clamped)
		"sfx":
			sfx_volume = clamped
			settings_changed.emit("sfx_volume", clamped)
		_:
			push_warning("SettingsManager: unknown volume bus '%s'" % bus)
			return
	_apply_volumes()
	save_settings()

func get_volume(bus: String) -> float:
	match bus:
		"master": return master_volume
		"music": return music_volume
		"sfx": return sfx_volume
		_: return 0.0

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	settings_changed.emit("fullscreen", enabled)
	save_settings()

func is_fullscreen() -> bool:
	return fullscreen

func set_keybind(action: String, event_text: String) -> void:
	if action.is_empty():
		return
	if event_text.is_empty():
		key_rebinds.erase(action)
	else:
		key_rebinds[action] = event_text
	settings_changed.emit("key_rebinds", key_rebinds.duplicate(true))
	save_settings()

func get_keybind(action: String) -> String:
	return key_rebinds.get(action, "")

func get_all_keybinds() -> Dictionary:
	return key_rebinds.duplicate(true)

func has_settings_file() -> bool:
	return FileAccess.file_exists(SETTINGS_PATH)

func delete_settings_file() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
