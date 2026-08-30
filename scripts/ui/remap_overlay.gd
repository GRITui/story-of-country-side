extends CanvasLayer
class_name RemapOverlay
## #176: key/gamepad remap screen, opened from the pause menu.
##
## Lists _imm.get_remappable_actions() as rows: label + one button
## per current binding. Clicking (or pressing A on) a binding button enters
## capture mode ("press a key or pad button…"); the next key/joy-button press
## becomes the new binding via InputMapManager.remap_action(). Esc cancels
## capture. Esc outside capture mode (or the Close button) closes the overlay.
##
## "Reset to defaults" restores InputMapManager's registered defaults.
## Bindings live on the InputMap (session-persistent); save-file persistence
## is intentionally out of scope here (tracked for #170 save schema).

signal closed

const InputMapManagerScript := preload("res://scripts/autoload/input_map_manager.gd")

var _imm: Node  # InputMapManager autoload (fallback: fresh instance in tests)
var _rows: VBoxContainer
var _status: Label
var _capturing_for: Dictionary = {}  # {action, old_event, button}
var _active := false

func _init() -> void:
	layer = 40
	_imm = get_node_or_null("/root/InputMapManager")
	if _imm == null:
		# Test/headless context without autoload processing.
		_imm = InputMapManagerScript.new()
		_imm.name = "InputMapManager"
		add_child(_imm)
	_build_ui()
	visible = false

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.name = "Dim"
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Controls"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Select a binding, then press a key or pad button."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	vbox.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows)

	_status = Label.new()
	_status.text = ""
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var reset_btn := Button.new()
	reset_btn.text = "Reset to defaults"
	reset_btn.pressed.connect(_on_reset_pressed)
	btn_row.add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	btn_row.add_child(close_btn)

func open() -> void:
	_active = true
	visible = true
	_capturing_for = {}
	_rebuild_rows()
	# Focus the first binding button so gamepad/keyboard nav works immediately.
	var first := _first_binding_button()
	if first:
		first.grab_focus()

func close() -> void:
	if not _active:
		return
	_active = false
	_capturing_for = {}
	visible = false
	closed.emit()

func is_open() -> bool:
	return _active

func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	for action in _imm.get_remappable_actions():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = _imm.get_action_name(action)
		label.custom_minimum_size = Vector2(150, 0)
		row.add_child(label)
		for ev in _imm.get_bindings(action):
			var b := Button.new()
			b.text = _describe_event(ev)
			b.pressed.connect(_begin_capture.bind(action, ev, b))
			row.add_child(b)
		_rows.add_child(row)

func _first_binding_button() -> Button:
	for row in _rows.get_children():
		for child in row.get_children():
			if child is Button:
				return child
	return null

func _begin_capture(action: String, old_event: InputEvent, button: Button) -> void:
	_capturing_for = {"action": action, "old_event": old_event, "button": button}
	_status.text = "Press a key or pad button for \"%s\" (Esc cancels)…" % \
		_imm.get_action_name(action)
	button.text = "…"
	button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _capturing_for.is_empty():
		if event.is_action_pressed("ui_cancel"):
			close()
			_mark_handled()
		return
	# Capture mode.
	if event.is_action_pressed("ui_cancel"):
		_cancel_capture()
		_mark_handled()
		return
	var ok_event: InputEvent = null
	if event is InputEventKey and event.pressed and not event.echo:
		ok_event = event
	elif event is InputEventJoypadButton and event.pressed:
		ok_event = event
	if ok_event == null:
		return
	var action: String = _capturing_for["action"]
	_imm.remap_action(action, _capturing_for["old_event"], ok_event)
	_capturing_for = {}
	_status.text = "Binding updated."
	_rebuild_rows()
	_mark_handled()

func _mark_handled() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()

func _cancel_capture() -> void:
	_capturing_for = {}
	_status.text = ""
	_rebuild_rows()

func _on_reset_pressed() -> void:
	_imm.reset_to_defaults()
	_capturing_for = {}
	_status.text = "Defaults restored."
	_rebuild_rows()

static func _describe_event(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return OS.get_keycode_string(ev.physical_keycode)
	if ev is InputEventJoypadButton:
		return "Pad " + str(ev.button_index)
	return ev.as_text()
