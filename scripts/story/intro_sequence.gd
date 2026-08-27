class_name IntroSequence
extends Node
## scripts/story/intro_sequence.gd
##
## ENG-26 (Opening hook): a linear, data-driven narration sequence -- the
## player leaves their corporate job, inherits a rundown farm from a
## relative, and arrives in town. Deliberately NOT a dialogue/cutscene
## engine: DEFAULT_LINES is a flat Array[String], advanced one line at a
## time, no branching, no timeline/track data. That's out of scope for
## this issue (see the PR description).
##
## DEFAULT_LINES holds the final intro narration (Content lane, issue #53).
## `lines` can still be overridden before this node enters the tree (e.g.
## by a test, or a future alternate-intro variant) without touching any of
## the advance/finish logic below.
##
## Freezes TimeManager for the duration, reusing the same freeze mechanism
## the pause menu and festivals use (one time-freeze mechanism, not a
## competing one) per design/ui-flows/menu-hud-flow-spec.md §1.

signal line_changed(index: int, text: String)
signal finished

const DEFAULT_LINES: Array[String] = [
	"6:52 AM. The subway's late, the coffee's burnt, and your inbox already has forty new messages -- same as every morning for the last six years.",
	"The letter is waiting on your desk when you get in: your great-aunt Rosalind has passed, and left you the one thing she owned outright -- forty acres and a farmhouse, out past the county line.",
	"You read it twice, then type your resignation before the coffee's gone cold. Nobody stops you on the way out.",
	"Three trains and a bus later, the driver calls your stop -- a town small enough that its name fits on one sign.",
	"The farmhouse is exactly as your memory left it, only smaller, and the fields around it have long since gone to weed and quiet.",
	"You set your one suitcase down on the porch and let the silence settle. No inbox. No fluorescent lights. Just dirt, daylight, and a lot of work ahead.",
]

const FREEZE_REASON := "intro"
const HINT_FADE_DURATION := 3.0

## Overridable before this node enters the tree (e.g. by a test, or a
## future writer-authored variant); defaults to DEFAULT_LINES otherwise.
@export var lines: Array[String] = []

var _index: int = 0
var _active: bool = false
var _hint_label: Label = null
var _hint_timer: float = 0.0
var _hint_visible: bool = false

@onready var _label: Label = get_node_or_null("Label")

func _ready() -> void:
	if lines.is_empty():
		lines = DEFAULT_LINES.duplicate()
	start()

## Idempotent -- calling start() while already active is a no-op, so a
## stray extra call (double-instantiation, re-entrant _ready) can't reset
## progress or double-freeze TimeManager (freeze() is itself idempotent
## per reason, but _index would otherwise be clobbered).
func start() -> void:
	if _active:
		return
	_active = true
	_index = 0
	if TimeManager:
		TimeManager.freeze(FREEZE_REASON)
	_show_current_line()

## Advances to the next line, or finishes the sequence once the lines are
## exhausted. A no-op once the sequence has already finished.
func advance() -> void:
	if not _active:
		return
	_index += 1
	_show_current_line()

func current_line() -> String:
	return lines[_index] if _index < lines.size() else ""

func is_finished() -> bool:
	return not _active

func _show_current_line() -> void:
	if _index >= lines.size():
		_finish()
		return
	var text: String = lines[_index]
	if _label:
		_label.text = text
	line_changed.emit(_index, text)
	if _index == lines.size() - 1:
		_show_hint()

func _finish() -> void:
	_active = false
	_hide_hint()
	if TimeManager:
		TimeManager.unfreeze(FREEZE_REASON)
	finished.emit()

func _process(delta: float) -> void:
	if _hint_visible and _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			_hide_hint()

func _show_hint() -> void:
	if _hint_label == null:
		_hint_label = Label.new()
		_hint_label.text = "Press any key to continue"
		_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hint_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
		_hint_label.offset_bottom = -40
		_hint_label.offset_top = -70
		_hint_label.modulate = Color(1, 1, 1, 0.8)
		add_child(_hint_label)
	_hint_visible = true
	_hint_timer = HINT_FADE_DURATION

func _hide_hint() -> void:
	_hint_visible = false
	if _hint_label != null:
		_hint_label.queue_free()
		_hint_label = null

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _hint_visible and _index == lines.size() - 1:
		_hide_hint()
	var advances: bool = event.is_action_pressed("ui_accept") \
func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var advances: bool = event.is_action_pressed("advance_dialog") \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if advances:
		advance()
		get_viewport().set_input_as_handled()
