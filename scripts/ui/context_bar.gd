extends CanvasLayer
class_name ContextBar
## #176: on-screen context bar showing the current prompts, e.g.
## "A Confirm · X Interact · B Back" (pad) or "Space Confirm · E Interact
## · Esc Back" (keyboard). Labels follow _imm().last_input_source,
## which flips on the first joypad vs key/mouse event.
##
## Polls once per second (prompts only change when the input source flips,
## so no per-frame cost). Visible only when prompts are set.


const InputMapManagerScript := preload("res://scripts/autoload/input_map_manager.gd")

func _imm() -> Node:
	var m := get_node_or_null("/root/InputMapManager")
	if m == null:
		m = InputMapManagerScript.new()
		m.name = "InputMapManager"
		add_child(m)
	return m

@onready var _label: Label = $Root/Panel/Margin/Prompts

var _source := ""

func _ready() -> void:
	layer = 25
	visible = false
	# Show nothing until someone sets prompts; desktop keyboard is default.
	_refresh()

func _process(_delta: float) -> void:
	if _imm().last_input_source != _source:
		_refresh()

func set_prompts(actions: Array) -> void:
	## actions: e.g. ["primary_action", "interact", "cancel"]
	_label.set_meta("actions", actions)
	visible = not actions.is_empty()
	_refresh()

func clear() -> void:
	set_prompts([])

func _refresh() -> void:
	_source = _imm().last_input_source
	var actions: Array = _label.get_meta("actions", [])
	var parts: Array = []
	for action in actions:
		parts.append("%s %s" % [_imm().get_prompt(action),
			_imm().get_action_name(action)])
	_label.text = "   ".join(parts)
