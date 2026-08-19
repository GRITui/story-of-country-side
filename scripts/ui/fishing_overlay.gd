extends CanvasLayer
class_name FishingOverlay
## Full-screen Fishing mini-game overlay against FishingManager (#15),
## reachable from the pause menu.
##
## Not one of menu-hud-flow-spec.md §1's six listed pause-menu items --
## same situation as Relationships/Infrastructure/Community Goal (all
## postdate the spec). Adds one more pause-menu entry beyond the spec's
## fixed list, same "Frontend can produce its own convention decisions
## when claiming unspec'd scope" precedent SQUAD-SPLIT.md's UX-GRID note
## describes.
##
## Scope boundary, same reasoning festival_mini_game_overlay.gd's own
## docstring gives for FestivalManager: FishingManager's own docstring
## explicitly declines to build a concrete mini-game ("no input/skill-
## check design exists... building one would invent an undecided design
## and cross into Frontend/UI territory"). This overlay is that
## placeholder implementation, not left unbuilt: the same three
## fixed-score difficulty buttons (Poor/Good/Great Effort) Festival's
## overlay uses, reused here for consistency across both mini-game
## contracts -- there is no timing bar/QTE input anywhere in this repo to
## build a real one from.
##
## FishingManager has no player-location concept (FishDefinition's own
## docstring: "no dedicated Location/map-zone system exists in this repo
## yet"), so this overlay lets the player pick a location directly from a
## flat list rather than simulating one -- the four location strings
## (pond/river/lake/ocean) are read from existing content
## (_register_default_content() registers exactly these four across its
## fish roster), not invented here, same pattern MapOverlay's location
## list and SkillsOverlay's skill-name list both follow.
##
## Fish availability (get_available_fish) is read fresh every time the
## location changes or a catch attempt completes, driven by
## TimeManager's current season/hour -- no local duplicate scheduling
## state, matching every other overlay's pure-display discipline for
## backend-owned state. FishingManager fires no signals of its own
## outside a direct attempt_catch() call (unlike FestivalManager, nothing
## else in the backend can trigger a catch), so there's no external
## signal to react to beyond this overlay's own button presses.

signal closed

const LOCATIONS := ["pond", "river", "lake", "ocean"]
const CHOICE_SCORES := {
	"Poor Effort": 0.2,
	"Good Effort": 0.6,
	"Great Effort": 0.95,
}

@onready var _result_label: Label = $Root/Panel/Margin/VBox/ResultLabel
@onready var _location_list: HBoxContainer = $Root/Panel/Margin/VBox/LocationList
@onready var _fish_list: VBoxContainer = $Root/Panel/Margin/VBox/ScrollContainer/FishList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _current_location: String = ""

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	for location in LOCATIONS:
		var button := Button.new()
		button.name = "Location_%s" % location
		button.text = location.capitalize()
		button.pressed.connect(_on_location_pressed.bind(location))
		_location_list.add_child(button)
	_on_location_pressed(LOCATIONS[0])

func _on_location_pressed(location: String) -> void:
	_current_location = location
	_refresh_fish_list()

func _refresh_fish_list() -> void:
	for child in _fish_list.get_children():
		child.free()

	var fish_ids := FishingManager.get_available_fish(_current_location, TimeManager.current_season(), TimeManager.hour)
	if fish_ids.is_empty():
		var empty_label := Label.new()
		empty_label.name = "EmptyLabel"
		empty_label.text = "Nothing biting here right now."
		_fish_list.add_child(empty_label)
		return

	for fish_id in fish_ids:
		var def: FishDefinition = FishingManager.get_fish_definition(fish_id)
		var row := HBoxContainer.new()
		row.name = "Fish_%s" % fish_id
		row.add_theme_constant_override("separation", 8)

		var name_label := Label.new()
		name_label.text = def.display_name if def != null else fish_id
		name_label.custom_minimum_size = Vector2(140, 0)
		row.add_child(name_label)

		for choice_label in CHOICE_SCORES.keys():
			var button := Button.new()
			button.text = choice_label
			button.pressed.connect(_on_cast_pressed.bind(fish_id, choice_label))
			row.add_child(button)

		_fish_list.add_child(row)

func _on_cast_pressed(fish_id: String, choice_label: String) -> void:
	var score: float = CHOICE_SCORES[choice_label]
	var result := FishingManager.attempt_catch(fish_id, score)
	if result.get("success", false):
		_result_label.text = "%s -- Caught! (%s quality)" % [choice_label, result.get("quality", "normal")]
	else:
		_result_label.text = "%s -- It got away!" % choice_label

func _on_close_pressed() -> void:
	closed.emit()
