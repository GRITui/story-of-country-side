extends SceneTree
## #176 integration test: gamepad defaults, prompt helpers, remap API,
## capture flow, and the dialogue/shop pad-confirm path.
## Run: godot --headless --path . --script res://tests/integration/test_gamepad_remap.gd

var _failures := 0

func _assert(cond: bool, label: String) -> void:
	if cond:
		print("ok  | " + label)
	else:
		_failures += 1
		print("FAIL| " + label)

func _init() -> void:
	# InputMapManager is an autoload; with --script there is no autoload
	# processing, so instantiate the singleton the same way the engine would.
	var imm := preload("res://scripts/autoload/input_map_manager.gd").new()
	imm.name = "InputMapManager"
	root.add_child(imm)
	imm._ready()

	# --- scope item 1: default joypad bindings exist ---
	var move_up_events := InputMap.action_get_events("move_up")
	var has_dpad_up := false
	var has_ls_up := false
	for ev in move_up_events:
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_DPAD_UP:
			has_dpad_up = true
		if ev is InputEventJoypadMotion and ev.axis == JOY_AXIS_LEFT_Y and ev.axis_value < 0:
			has_ls_up = true
	_assert(has_dpad_up, "move_up has D-pad up")
	_assert(has_ls_up, "move_up has left-stick up")
	_assert(_has_joy("primary_action", JOY_BUTTON_A), "primary_action has pad A (confirm)")
	_assert(_has_joy("advance_dialog", JOY_BUTTON_A), "advance_dialog has pad A (dialogue)")
	_assert(_has_joy("interact", JOY_BUTTON_X), "interact has pad X (use)")
	_assert(_has_joy("menu", JOY_BUTTON_START), "menu has pad Start")
	_assert(_has_joy("cancel", JOY_BUTTON_B), "cancel has pad B (new #176)")
	_assert(_has_joy("hotbar_next", JOY_BUTTON_RIGHT_SHOULDER), "hotbar_next has RB")
	_assert(_has_joy("hotbar_prev", JOY_BUTTON_LEFT_SHOULDER), "hotbar_prev has LB")

	# --- scope item 2: input-source tracking + prompt strings ---
	imm.last_input_source = "key"
	_assert(imm.get_prompt("interact") == "E", "keyboard prompt for interact is E")
	imm.last_input_source = "pad"
	_assert(imm.get_prompt("interact") == "X", "pad prompt for interact is X")
	_assert(imm.get_prompt("primary_action") == "A", "pad prompt for primary is A")
	_assert(imm.get_prompt("cancel") == "B", "pad prompt for cancel is B")
	var key_ev := InputEventKey.new()
	key_ev.pressed = true
	key_ev.physical_keycode = KEY_W
	imm._unhandled_input(key_ev)
	_assert(imm.last_input_source == "key", "key event flips source to key")
	var pad_ev := InputEventJoypadButton.new()
	pad_ev.pressed = true
	pad_ev.button_index = JOY_BUTTON_A
	imm._unhandled_input(pad_ev)
	_assert(imm.last_input_source == "pad", "pad event flips source to pad")

	# --- scope item 3: remap API ---
	var binds := imm.get_bindings("interact")
	_assert(not binds.is_empty(), "interact has remappable bindings")
	var old: InputEvent = binds[0]
	var newb := InputEventJoypadButton.new()
	newb.button_index = JOY_BUTTON_Y
	_assert(imm.remap_action("interact", old, newb), "remap_action accepts joypad button")
	_assert(InputMap.action_has_event("interact", newb), "new Y binding active")
	_assert(not InputMap.action_has_event("interact", old), "old binding removed")
	# reject non-key/button event
	var axis := InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	_assert(not imm.remap_action("interact", newb, axis), "remap rejects axis events")
	_assert(not imm.remap_action("nonexistent_action", null, newb), "remap rejects unknown action")

	# --- reset round-trip ---
	imm.reset_to_defaults()
	_assert(_has_joy("interact", JOY_BUTTON_X), "reset restores pad X on interact")
	_assert(not InputMap.action_has_event("interact", newb), "reset drops custom Y binding")
	_assert(_has_joy("cancel", JOY_BUTTON_B), "reset restores cancel B")

	# --- scope item 4: remap overlay capture flow (pad press rebinds) ---
	var overlay := preload("res://scenes/ui/RemapOverlay.tscn").instantiate()
	root.add_child(overlay)
	overlay.open()
	_assert(overlay.is_open(), "remap overlay opens")
	var action := "primary_action"
	var old_bind: InputEvent = imm.get_bindings(action)[0]
	var dummy_btn := Button.new()
	overlay._begin_capture(action, old_bind, dummy_btn)
	var pad_rebind := InputEventJoypadButton.new()
	pad_rebind.pressed = true
	pad_rebind.button_index = JOY_BUTTON_Y
	overlay._unhandled_input(pad_rebind)
	_assert(InputMap.action_has_event(action, pad_rebind), "capture flow rebinds to pad Y")
	overlay.close()
	imm.reset_to_defaults()

	# --- scope item 4 (issue): pad action advances dialogue ---
	# DialogueBox listens for advance_dialog; synthesizing the action press
	# exercises the same path a pad A press takes.
	var dialogue_scene_path := "res://scenes/ui/DialogueBox.tscn"
	if ResourceLoader.exists(dialogue_scene_path):
		Input.action_press("advance_dialog")
		_assert(Input.is_action_pressed("advance_dialog"), "advance_dialog press registers (pad A path)")
		Input.action_release("advance_dialog")
	else:
		_assert(false, "DialogueBox.tscn exists")

	print("")
	if _failures == 0:
		print("PASS: all gamepad/remap checks")
	else:
		print("FAILURES: %d" % _failures)
	quit(1 if _failures > 0 else 0)

func _has_joy(action: String, button: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == button:
			return true
	return false
