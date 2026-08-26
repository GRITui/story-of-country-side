extends CanvasLayer
class_name SleepOverlay
## Confirmation dialog shown when the player interacts with a SleepZone.
## Freezes TimeManager while open (same pattern as PauseMenu). Emits
## closed(sleep_confirmed) so the caller can advance the day on confirm.

signal closed(sleep_confirmed: bool)

const OVERLAY_REASON := "sleep_overlay"

func _ready() -> void:
	TimeManager.freeze(OVERLAY_REASON)
	_build_ui()

func _build_ui() -> void:
	var root := ColorRect.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.color = Color(0, 0, 0, 0.7)
	add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	center.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Go to sleep?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	vbox.add_child(button_row)

	var yes_button := Button.new()
	yes_button.name = "YesButton"
	yes_button.text = "Yes"
	yes_button.custom_minimum_size = Vector2(100, 0)
	yes_button.pressed.connect(_on_yes_pressed)
	button_row.add_child(yes_button)

	var no_button := Button.new()
	no_button.name = "NoButton"
	no_button.text = "No"
	no_button.custom_minimum_size = Vector2(100, 0)
	no_button.pressed.connect(_on_no_pressed)
	button_row.add_child(no_button)

func _on_yes_pressed() -> void:
	_close(true)

func _on_no_pressed() -> void:
	_close(false)

func _close(sleep_confirmed: bool) -> void:
	TimeManager.unfreeze(OVERLAY_REASON)
	closed.emit(sleep_confirmed)
	queue_free()
