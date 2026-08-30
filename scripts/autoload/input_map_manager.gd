extends Node
## Autoload: InputMapManager
##
## ENG-101: Registers all player input actions programmatically so the
## project.godot file stays clean and the action list is easy to review.
## Each action maps one or more physical keys to a named action string.
##
## Actions registered:
##   Movement: move_up (W / Up), move_down (S / Down),
##             move_left (A / Left), move_right (D / Right)
##   Actions:  interact (E / Enter), menu (Escape)
##   Hotbar:   hotbar_1 .. hotbar_9 (1-9 keys)
##
## Public API:
##   get_action_name(action) -> human-readable label for UI hints
##   is_action_registered(action) -> bool

## Human-readable labels for UI hints (e.g. "Press E to interact").
const ACTION_LABELS := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"interact": "Interact",
	"menu": "Menu",
	"hotbar_1": "Hotbar 1",
	"hotbar_2": "Hotbar 2",
	"hotbar_3": "Hotbar 3",
	"hotbar_4": "Hotbar 4",
	"hotbar_5": "Hotbar 5",
	"hotbar_6": "Hotbar 6",
	"hotbar_7": "Hotbar 7",
	"hotbar_8": "Hotbar 8",
	"hotbar_9": "Hotbar 9",
}

func _ready() -> void:
	_register_all_actions()

func _register_all_actions() -> void:
	_register_action("move_up", [
		_make_key(KEY_W),
		_make_key(KEY_UP),
	])
	_register_action("move_down", [
		_make_key(KEY_S),
		_make_key(KEY_DOWN),
	])
	_register_action("move_left", [
		_make_key(KEY_A),
		_make_key(KEY_LEFT),
	])
	_register_action("move_right", [
		_make_key(KEY_D),
		_make_key(KEY_RIGHT),
	])
	_register_action("interact", [
		_make_key(KEY_E),
		_make_key(KEY_ENTER),
	])
	_register_action("menu", [
		_make_key(KEY_ESCAPE),
	])
	for i in range(1, 10):
		_register_action("hotbar_%d" % i, [
			_make_key(KEY_1 + i - 1),
		])

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

## Returns a human-readable label for an action name, suitable for UI hints
## like "Press E to interact". Returns the raw action name if no label is
## registered (defensive against future actions added without updating
## ACTION_LABELS).
func get_action_name(action: String) -> String:
	return ACTION_LABELS.get(action, action)

## Returns true if the given action name has been registered with InputMap.
func is_action_registered(action: String) -> bool:
	return InputMap.has_action(action)
