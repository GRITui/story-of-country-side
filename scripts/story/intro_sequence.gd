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
## PLACEHOLDER COPY: the lines below are placeholder narration written for
## sequencing purposes only -- no writer has produced final intro copy
## anywhere in the design docs yet. A writer can replace DEFAULT_LINES (or
## override `lines` before this node enters the tree) without touching any
## of the advance/finish logic below.
##
## Freezes TimeManager for the duration, reusing the same freeze mechanism
## the pause menu and festivals use (one time-freeze mechanism, not a
## competing one) per design/ui-flows/menu-hud-flow-spec.md §1.

signal line_changed(index: int, text: String)
signal finished

const DEFAULT_LINES: Array[String] = [
	"Another fluorescent-lit morning. Another inbox that never empties.",
	"Then the letter arrives: your great-aunt has passed, and left you the only thing she owned outright -- her farm.",
	"You hand in your resignation before you've finished reading it twice.",
	"The bus drops you at the edge of a town you've never seen, suitcase in hand.",
	"The farmhouse is smaller than you remembered from childhood visits, and the fields have gone to weed.",
	"Still. It's yours now. Time to get to work.",
]

const FREEZE_REASON := "intro"

## Overridable before this node enters the tree (e.g. by a test, or a
## future writer-authored variant); defaults to DEFAULT_LINES otherwise.
@export var lines: Array[String] = []

var _index: int = 0
var _active: bool = false

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

func _finish() -> void:
	_active = false
	if TimeManager:
		TimeManager.unfreeze(FREEZE_REASON)
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var advances: bool = event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if advances:
		advance()
		get_viewport().set_input_as_handled()
