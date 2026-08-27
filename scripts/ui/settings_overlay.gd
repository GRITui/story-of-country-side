extends CanvasLayer
class_name SettingsOverlay
## Settings overlay — volume sliders + fullscreen toggle + key rebind list.
## Reads/writes via SettingsManager (user://settings.json). Minimal,
## headless-testable: no scene-tree assumptions beyond the nodes declared
## here. Launched from PauseMenu's Settings button (S-Tier Zeta).

signal closed

@onready var _master_slider: HSlider = $Root/Panel/Margin/VBox/MasterRow/MasterSlider
@onready var _master_label: Label = $Root/Panel/Margin/VBox/MasterRow/MasterLabel
@onready var _music_slider: HSlider = $Root/Panel/Margin/VBox/MusicRow/MusicSlider
@onready var _music_label: Label = $Root/Panel/Margin/VBox/MusicRow/MusicLabel
@onready var _sfx_slider: HSlider = $Root/Panel/Margin/VBox/SfxRow/SfxSlider
@onready var _sfx_label: Label = $Root/Panel/Margin/VBox/SfxRow/SfxLabel
@onready var _fullscreen_toggle: CheckButton = $Root/Panel/Margin/VBox/FullscreenRow/FullscreenToggle
@onready var _keybind_list: VBoxContainer = $Root/Panel/Margin/VBox/KeybindList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_setup_sliders()
	_setup_fullscreen()
	_refresh_keybinds()
	# Listen for external changes
	if SettingsManager.has_signal("settings_changed"):
		SettingsManager.settings_changed.connect(_on_settings_changed)

func _exit_tree() -> void:
	if SettingsManager.has_signal("settings_changed") and SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.disconnect(_on_settings_changed)

func _setup_sliders() -> void:
	_master_slider.min_value = 0.0
	_master_slider.max_value = 1.0
	_master_slider.step = 0.05
	_master_slider.value = SettingsManager.get_volume("master")
	_master_label.text = "Master: %d%%" % int(_master_slider.value * 100)
	_master_slider.value_changed.connect(_on_master_changed)

	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.step = 0.05
	_music_slider.value = SettingsManager.get_volume("music")
	_music_label.text = "Music: %d%%" % int(_music_slider.value * 100)
	_music_slider.value_changed.connect(_on_music_changed)

	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.value = SettingsManager.get_volume("sfx")
	_sfx_label.text = "SFX: %d%%" % int(_sfx_slider.value * 100)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

func _setup_fullscreen() -> void:
	_fullscreen_toggle.button_pressed = SettingsManager.is_fullscreen()
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

func _refresh_keybinds() -> void:
	# Clear existing rows except the template header if any
	for child in _keybind_list.get_children():
		child.queue_free()
	var binds: Dictionary = SettingsManager.get_all_keybinds()
	if binds.is_empty():
		var empty := Label.new()
		empty.text = "(no custom keybinds — using defaults)"
		empty.modulate = Color(1, 1, 1, 0.6)
		_keybind_list.add_child(empty)
	else:
		for action in binds.keys():
			var row := HBoxContainer.new()
			var action_label := Label.new()
			action_label.text = action
			action_label.custom_minimum_size = Vector2(160, 0)
			var bind_label := Label.new()
			bind_label.text = str(binds[action])
			bind_label.modulate = Color(0.8, 1, 0.8)
			var clear_btn := Button.new()
			clear_btn.text = "Clear"
			clear_btn.pressed.connect(_on_clear_keybind.bind(action))
			row.add_child(action_label)
			row.add_child(bind_label)
			row.add_child(clear_btn)
			_keybind_list.add_child(row)
	# Always show hint + add row
	var hint := Label.new()
	hint.text = "Rebind via SettingsManager.set_keybind(action, key) — UI picker is a future enhancement."
	hint.modulate = Color(1, 1, 1, 0.5)
	_keybind_list.add_child(hint)

func _on_master_changed(value: float) -> void:
	_master_label.text = "Master: %d%%" % int(value * 100)
	SettingsManager.set_volume("master", value)

func _on_music_changed(value: float) -> void:
	_music_label.text = "Music: %d%%" % int(value * 100)
	SettingsManager.set_volume("music", value)

func _on_sfx_changed(value: float) -> void:
	_sfx_label.text = "SFX: %d%%" % int(value * 100)
	SettingsManager.set_volume("sfx", value)

func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)

func _on_clear_keybind(action: String) -> void:
	SettingsManager.set_keybind(action, "")
	_refresh_keybinds()

func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "key_rebinds":
		_refresh_keybinds()

func _on_close_pressed() -> void:
	closed.emit()
