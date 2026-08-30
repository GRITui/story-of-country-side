extends Node
## Autoload: InputMapManager — Retro Input & Diegetic HCI (PO-16BIT-HCI-3)
##
## Registers all player input actions programmatically so project.godot stays
## clean and the action list is reviewable. Also owns focus-safety and
## scroll-prevention for HTML5 Canvas exports.
##
## Actions registered (spec § Input Manager):
##   Movement: move_up (W/Up + Gamepad Up/LS-up), move_down (S/Down + LS-down),
##             move_left (A/Left + LS-left), move_right (D/Right + LS-right) — 4/8-way,
##             12x8 feet collision is enforced in PlayerAvatar (feet rect), not here.
##   Primary:  primary_action (Space / J / Joy A) + advance_dialog alias (Space/Enter/J)
##   Secondary: secondary_action (E / K / Joy X) + interact alias (E/K/Enter)
##   Hotbar:   hotbar_1 .. hotbar_8 (1-8 keys + Joy D-pad/Pad), hotbar_next (Tab/ScrollDown),
##             hotbar_prev (Shift+Tab/ScrollUp), hotbar_next/prev also consume mouse wheel.
##   Menu:     menu (Escape / Joy Start)
##
## Focus safety:
##   ensure_canvas_focus() — call on mount/click; on HTML5 evals canvas.focus(),
##   otherwise grabs viewport focus. _unhandled_input consumes wheel scroll and
##   re-focuses on any click. Godot viewport focus is automatic; this helper
##   guarantees HTML5 Canvas stays focused after overlay open/close.
##
## Mobile/Gamepad:
##   Gamepad left stick + D-pad map to move_*; A/B (Joy 0/1) map to Primary/
##   Secondary; mobile D-pad overlay lives in scripts/ui/mobile_controls.gd
##   and just emits the same actions via Input.action_press/release.
##
## Public API:
##   get_action_name(action) -> human-readable label for UI hints
##   is_action_registered(action) -> bool
##   ensure_canvas_focus() -> void
##   consume_scroll(event) -> bool (true if wheel event was consumed)
##   get_hotbar_index(event) -> int (-1 if not a hotbar event, else 0..7)

## Human-readable labels for UI hints (e.g. "Press E to interact").
const ACTION_LABELS := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"interact": "Interact",
	"secondary_action": "Interact",
	"primary_action": "Confirm",
	"advance_dialog": "Advance",
	"menu": "Menu",
	"hotbar_1": "Hotbar 1",
	"hotbar_2": "Hotbar 2",
	"hotbar_3": "Hotbar 3",
	"hotbar_4": "Hotbar 4",
	"hotbar_5": "Hotbar 5",
	"hotbar_6": "Hotbar 6",
	"hotbar_7": "Hotbar 7",
	"hotbar_8": "Hotbar 8",
	"hotbar_next": "Next Tool (Tab/Scroll)",
	"hotbar_prev": "Prev Tool (Shift+Tab)",
	"cancel": "Cancel / Back",
}

## Short prompt labels per input source, for the context bar (#176).
const PROMPT_KEYS := {
	"primary_action": {"pad": "A", "key": "Space"},
	"interact": {"pad": "X", "key": "E"},
	"secondary_action": {"pad": "X", "key": "E"},
	"advance_dialog": {"pad": "A", "key": "Space"},
	"cancel": {"pad": "B", "key": "Esc"},
	"menu": {"pad": "Start", "key": "Esc"},
	"hotbar_next": {"pad": "RB", "key": "Tab"},
	"hotbar_prev": {"pad": "LB", "key": "Shift+Tab"},
}

## Last detected input source: "pad" or "key". Starts "key" (desktop-first).
var last_input_source := "key"

# Foot collision spec for reference — actual clamp lives in PlayerAvatar.
const FEET_COLLISION_SIZE := Vector2(12, 8)

func _ready() -> void:
	_register_all_actions()
	# Focus safety — Godot viewport focus is automatic but HTML5 canvas needs explicit focus.
	ensure_canvas_focus()
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	# Focus safety: any click refocuses canvas (prevents browser losing focus).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		ensure_canvas_focus()
	# Input-source tracking for the context bar (#176): pad vs key.
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_source = "pad"
	elif event is InputEventKey or event is InputEventMouseButton:
		last_input_source = "key"
	# Prevent browser/window scroll: consume wheel events (Godot doesn't scroll window but HTML5 host does if not consumed).
	if consume_scroll(event):
		get_viewport().set_input_as_handled()

## HTML5-aware canvas focus helper. No-op on desktop but guarantees focus after mount/click/overlay close.
func ensure_canvas_focus() -> void:
	# Try JavaScriptBridge for HTML5 Canvas focus; fall back to viewport focus.
	if Engine.has_singleton("JavaScriptBridge"):
		var js := Engine.get_singleton("JavaScriptBridge")
		if js and js.has_method("eval"):
			# canvas id is 'canvas' in Godot HTML5 export; blur activeElement first so focus fires.
			js.eval("try{if(document.activeElement)document.activeElement.blur();var c=document.getElementById('canvas');if(c)c.focus();}catch(e){}", true)
			return
	# Desktop fallback: ensure window/viewport has focus so Input.get_vector works without extra click.
	var vp := get_viewport()
	if vp:
		# Make viewport consume input; grab focus if a Control has it.
		vp.gui_release_focus()
	var win := get_window()
	if win:
		win.grab_focus()

## Returns true if event was a scroll wheel event and was consumed (prevents window scroll).
func consume_scroll(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
				or event.button_index == MOUSE_BUTTON_WHEEL_LEFT or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			# Emit hotbar cycle synthetically so wheel also cycles tools (Scroll per spec).
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Input.action_press("hotbar_next")
				Input.action_release("hotbar_next")
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Input.action_press("hotbar_prev")
				Input.action_release("hotbar_prev")
			return true
	return false

## Returns 0..7 if event is a hotbar press (1-8 or Tab cycle), else -1. Handles Tab wrap.
func get_hotbar_index(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		# Direct 1..8
		for i in range(1, 9):
			if event.physical_keycode == KEY_1 + i - 1:
				return i - 1
		if event.physical_keycode == KEY_TAB:
			return -2 # signal Tab cycle (caller should advance current index)
	return -1

func _register_all_actions() -> void:
	# Movement — WASD + Arrows + Gamepad LS/D-pad
	_register_action("move_up", [
		_make_key(KEY_W),
		_make_key(KEY_UP),
		_make_joy_button(JOY_BUTTON_DPAD_UP),
		_make_joy_axis(JOY_AXIS_LEFT_Y, -1.0),
	])
	_register_action("move_down", [
		_make_key(KEY_S),
		_make_key(KEY_DOWN),
		_make_joy_button(JOY_BUTTON_DPAD_DOWN),
		_make_joy_axis(JOY_AXIS_LEFT_Y, 1.0),
	])
	_register_action("move_left", [
		_make_key(KEY_A),
		_make_key(KEY_LEFT),
		_make_joy_button(JOY_BUTTON_DPAD_LEFT),
		_make_joy_axis(JOY_AXIS_LEFT_X, -1.0),
	])
	_register_action("move_right", [
		_make_key(KEY_D),
		_make_key(KEY_RIGHT),
		_make_joy_button(JOY_BUTTON_DPAD_RIGHT),
		_make_joy_axis(JOY_AXIS_LEFT_X, 1.0),
	])
	# Secondary: E / K (interact)
	_register_action("interact", [
		_make_key(KEY_E),
		_make_key(KEY_K),
		_make_key(KEY_ENTER),
		_make_joy_button(JOY_BUTTON_X),
	])
	_register_action("secondary_action", [
		_make_key(KEY_E),
		_make_key(KEY_K),
		_make_joy_button(JOY_BUTTON_X),
	])
	# Primary: Space / J (advance/confirm)
	_register_action("primary_action", [
		_make_key(KEY_SPACE),
		_make_key(KEY_J),
		_make_joy_button(JOY_BUTTON_A),
	])
	_register_action("advance_dialog", [
		_make_key(KEY_SPACE),
		_make_key(KEY_J),
		_make_key(KEY_ENTER),
		_make_joy_button(JOY_BUTTON_A),
	])
	_register_action("menu", [
		_make_key(KEY_ESCAPE),
		_make_joy_button(JOY_BUTTON_START),
	])
	# Cancel/back — gamepad B is the universal back button (#176). Pause menu
	# still keeps its historical ui_cancel binding; this action is the
	# remappable alias for context-bar prompts and future UI back-outs.
	_register_action("cancel", [
		_make_key(KEY_ESCAPE),
		_make_joy_button(JOY_BUTTON_B),
	])
	# Hotbar 1..8 — number keys + Joy face/shoulder as fallback for gamepad
	for i in range(1, 9):
		_register_action("hotbar_%d" % i, [
			_make_key(KEY_1 + i - 1),
		])
	# Tab cycle — next/prev (Scroll emits these synthetically via consume_scroll)
	_register_action("hotbar_next", [
		_make_key(KEY_TAB),
		_make_joy_button(JOY_BUTTON_RIGHT_SHOULDER),
		_make_wheel(MOUSE_BUTTON_WHEEL_DOWN),
	])
	_register_action("hotbar_prev", [
		_make_key_with_shift(KEY_TAB),
		_make_joy_button(JOY_BUTTON_LEFT_SHOULDER),
		_make_wheel(MOUSE_BUTTON_WHEEL_UP),
	])
	# Also keep hotbar_9 registered for backward compat (not shown in 8-slot HUD)
	if not InputMap.has_action("hotbar_9"):
		_register_action("hotbar_9", [_make_key(KEY_9)])

func _register_action(action_name: String, events: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for ev in events:
		if not InputMap.action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)

func _make_key(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	return ev

func _make_key_with_shift(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.shift_pressed = true
	return ev

func _make_wheel(button_index: int) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	return ev

func _make_joy_button(button: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev

func _make_joy_axis(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	return ev

## Returns a human-readable label for an action name, suitable for UI hints
## like "Press E to interact". Returns the raw action name if no label is
## registered (defensive against future actions added without updating
## ACTION_LABELS).
func get_action_name(action: String) -> String:
	return ACTION_LABELS.get(action, action)

## Returns true if the given action name has been registered with InputMap.
func is_action_registered(action: String) -> bool:
	return InputMap.has_action(action)

## --- #176: context-bar prompts + remapping API -----------------------------

## Prompt label for an action in the currently active input source,
## e.g. get_prompt("interact") -> "X" (pad) or "E" (keyboard).
func get_prompt(action: String) -> String:
	var per_action: Dictionary = PROMPT_KEYS.get(action, {})
	return per_action.get(last_input_source, per_action.get("key", action))

## Events the player may rebind (keyboard keys and gamepad buttons; movement
## axes, the mouse wheel, and Joy Start are locked — Start must always open
## the menu so a player can never soft-lock themselves out of remapping).
func get_remappable_actions() -> Array:
	return ["primary_action", "interact", "cancel", "menu",
		"hotbar_next", "hotbar_prev"]

## Returns the remappable events (key/joy button) currently bound to an action.
func get_bindings(action: String) -> Array:
	var out: Array = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey or ev is InputEventJoypadButton:
			out.append(ev)
	return out

## Replaces a binding: removes old_event from, adds new_event to the action.
## Validates that new_event is a key or joypad button; returns false otherwise.
func remap_action(action: String, old_event: InputEvent, new_event: InputEvent) -> bool:
	if not InputMap.has_action(action):
		return false
	if not (new_event is InputEventKey or new_event is InputEventJoypadButton):
		return false
	if old_event != null and InputMap.action_has_event(action, old_event):
		InputMap.action_erase_event(action, old_event)
	if not InputMap.action_has_event(action, new_event):
		InputMap.action_add_event(action, new_event)
	return true

## Restores the default bindings (clears every action and re-registers).
func reset_to_defaults() -> void:
	var actions := ["move_up", "move_down", "move_left", "move_right",
		"interact", "secondary_action", "primary_action", "advance_dialog",
		"menu", "cancel", "hotbar_next", "hotbar_prev"]
	for i in range(1, 10):
		actions.append("hotbar_%d" % i)
	for action in actions:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
	_register_all_actions()
