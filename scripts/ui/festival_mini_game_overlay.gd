extends CanvasLayer
class_name FestivalMiniGameOverlay
## Full-screen mini-game overlay for the active festival, against
## FestivalManager (#21).
##
## Unlike every other overlay this squad has built, this one is NOT
## reached from the pause menu -- it auto-shows when FestivalManager
## emits festival_started (wired in main_controller.gd, since that's
## already the scene that owns "what's shown at the top level of the
## game" per its own docstring) and is the whole point of a festival day,
## not an optional menu a player navigates to. TimeManager is already
## frozen ("festival" reason) for the whole festival, so nothing else
## needs to react to this overlay opening/closing the way pause-menu
## overlays coordinate freeze state with PauseMenu.
##
## Scope boundary, same reasoning FestivalManager's own docstring gives
## for shipping only submit_mini_game_result()'s pass/fail contract: "no
## input/skill-check design exists anywhere in the design doc, and
## building one concrete implementation would... invent an undecided
## design." This overlay is that concrete implementation, built as an
## explicit placeholder rather than left unbuilt -- FestivalManager's
## contract needs a real caller, the same way MarriageManager's marry()
## needed RelationshipsOverlay's "Marry Now" button to stand in for a
## ceremony scene that doesn't exist. Three difficulty buttons (Poor/
## Good/Great Effort) map to fixed placeholder scores -- no timing bar,
## QTE, or skill-check input exists anywhere in this repo to build a real
## one from, and inventing bespoke input handling here would be exactly
## the "undecided design" FestivalManager's own docstring warns against
## fabricating.
##
## Flow: festival_started -> this overlay shows the choice screen ->
## player picks one -> submit_mini_game_result() is called and the result
## (pass/fail) is shown -> a Continue button calls FestivalManager.end_festival()
## (there is no auto-end on day rollover, per FestivalManager's own design)
## and this overlay closes itself.

signal closed

## Placeholder scores -- MINI_GAME_PASS_THRESHOLD is 0.5, so Poor fails
## and Good/Great pass. Not final balance, same honesty as every other
## placeholder number in this repo.
const CHOICE_SCORES := {
	"Poor Effort": 0.2,
	"Good Effort": 0.6,
	"Great Effort": 0.95,
}

@onready var _title_label: Label = $Root/Panel/Margin/VBox/TitleLabel
@onready var _result_label: Label = $Root/Panel/Margin/VBox/ResultLabel
@onready var _choice_list: VBoxContainer = $Root/Panel/Margin/VBox/ChoiceList
@onready var _continue_button: Button = $Root/Panel/Margin/VBox/ContinueButton

var _festival_id: String = ""

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.visible = false
	_result_label.visible = false

	var festival: FestivalDefinition = FestivalManager.get_active_festival()
	if festival == null:
		# Defensive: this overlay is only ever instantiated on festival_started,
		# so an active festival should always exist -- but never render a
		# broken screen if that invariant is somehow violated.
		_title_label.text = "Festival"
		_festival_id = ""
	else:
		_title_label.text = festival.display_name
		_festival_id = festival.festival_id

	for choice_label in CHOICE_SCORES.keys():
		var button := Button.new()
		button.text = choice_label
		button.pressed.connect(_on_choice_pressed.bind(choice_label))
		_choice_list.add_child(button)

func _on_choice_pressed(choice_label: String) -> void:
	var score: float = CHOICE_SCORES[choice_label]
	var result := FestivalManager.submit_mini_game_result(_festival_id, score)
	_choice_list.visible = false
	_result_label.visible = true
	_continue_button.visible = true
	if result.get("success", false):
		_result_label.text = "%s -- Success! (score %.2f)" % [choice_label, score]
	else:
		_result_label.text = "%s -- Didn't quite make it (score %.2f)" % [choice_label, score]

func _on_continue_pressed() -> void:
	FestivalManager.end_festival()
	closed.emit()
