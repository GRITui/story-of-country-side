extends CanvasLayer
class_name MobileControls
## PO-16BIT-HCI-3: Mobile D-pad left + A/B right + Gamepad.
##
## Responsive Control overlay (anchors full rect, HTML5 Canvas / touch).
## Emits the same InputMap actions that keyboard/gamepad use, so
## PlayerAvatar.move_by_input via Input.get_vector and interact/primary
## handlers work without any fork.
##
## Left cluster: D-pad (4 dirs, 8-way via chord — holding Up+Right yields diagonal)
## Right cluster: A (Primary Space/J) and B (Secondary E/K)
## Also maps to Joy buttons via InputMapManager's gamepad bindings.
##
## Visible on touch devices / when forced via set_force_visible(); hidden on desktop by default
## but can be toggled for testing. Consumes no scroll and keeps canvas focus.

var _force_visible := false
var _pressed_dirs: Dictionary = {"up": false, "down": false, "left": false, "right": false}

@onready var _dpad_up: Button = $Root/LeftCluster/Up if has_node("Root/LeftCluster/Up") else null
@onready var _dpad_down: Button = $Root/LeftCluster/Down if has_node("Root/LeftCluster/Down") else null
@onready var _dpad_left: Button = $Root/LeftCluster/Left if has_node("Root/LeftCluster/Left") else null
@onready var _dpad_right: Button = $Root/LeftCluster/Right if has_node("Root/LeftCluster/Right") else null
@onready var _btn_a: Button = $Root/RightCluster/A if has_node("Root/RightCluster/A") else null
@onready var _btn_b: Button = $Root/RightCluster/B if has_node("Root/RightCluster/B") else null

func _ready() -> void:
	layer = 30
	# Responsive: show on touch devices or when forced
	var show_mobile := DisplayServer.is_touchscreen_available() or _force_visible or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	visible = show_mobile
	_wire_buttons()
	set_process(true)

func set_force_visible(v: bool) -> void:
	_force_visible = v
	visible = v or DisplayServer.is_touchscreen_available()

func _wire_buttons() -> void:
	for btn in [_dpad_up, _dpad_down, _dpad_left, _dpad_right, _btn_a, _btn_b]:
		if btn == null:
			continue
		btn.focus_mode = Control.FOCUS_NONE
		# Keep canvas focus after touch (prevent browser blur)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	# D-pad
	_wire_dir(_dpad_up, "up", "move_up")
	_wire_dir(_dpad_down, "down", "move_down")
	_wire_dir(_dpad_left, "left", "move_left")
	_wire_dir(_dpad_right, "right", "move_right")
	# A/B
	if _btn_a:
		_btn_a.button_down.connect(func(): Input.action_press("primary_action"); Input.action_press("advance_dialog"))
		_btn_a.button_up.connect(func(): Input.action_release("primary_action"); Input.action_release("advance_dialog"))
		_btn_a.pressed.connect(_on_a_pressed)
	if _btn_b:
		_btn_b.button_down.connect(func(): Input.action_press("secondary_action"); Input.action_press("interact"))
		_btn_b.button_up.connect(func(): Input.action_release("secondary_action"); Input.action_release("interact"))
		_btn_b.pressed.connect(_on_b_pressed)

func _wire_dir(btn: Button, dir: String, action: String) -> void:
	if btn == null:
		return
	btn.button_down.connect(func(): _set_dir(dir, true, action))
	btn.button_up.connect(func(): _set_dir(dir, false, action))

func _set_dir(dir: String, pressed: bool, action: String) -> void:
	_pressed_dirs[dir] = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	# Ensure canvas stays focused after touch
	if has_node("/root/InputMapManager"):
		var imm: Node = get_node("/root/InputMapManager")
		if imm.has_method("ensure_canvas_focus"):
			imm.ensure_canvas_focus()

func _on_a_pressed() -> void:
	# Single press also handled via button_down/up; this is for click feedback
	pass

func _on_b_pressed() -> void:
	pass

func _process(_delta: float) -> void:
	# Drive Input.get_vector via held actions — no extra polling needed; InputMapManager already registers joy axes.
	pass

func is_mobile_visible() -> bool:
	return visible

## Static helper: instantiate and add to current scene (used by world scenes / main_controller).
static func ensure_in_scene(parent: Node) -> MobileControls:
	for c in parent.get_children():
		if c is MobileControls:
			return c as MobileControls
	var mc: MobileControls = load("res://scenes/ui/MobileControls.tscn").instantiate()
	parent.add_child(mc)
	return mc
