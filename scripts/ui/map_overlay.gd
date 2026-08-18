extends CanvasLayer
class_name MapOverlay
## Full-screen Map overlay (design/ui-flows/menu-hud-flow-spec.md §1/§3),
## reachable from the pause menu (§1) -- fills the "Map" gap that's stayed
## a disabled "(not yet implemented)" placeholder since PR #54.
##
## No MapManager or any backend location/travel state exists (per
## pause_menu.gd's own docstring, that's exactly why Map stayed disabled
## until now) -- there is nothing to read reactively here. This overlay is
## instead the location switcher main_controller.gd needed but never got:
## FarmScene shipped wired into the boot flow (main_controller.gd
## instantiates it directly), but RanchScene/ForageScene/MineScene
## (shipped later this same epoch) were never wired in anywhere -- they
## existed as tested, working .tscn files nobody could actually reach
## while playing. This overlay's Travel buttons call
## MainController.travel_to(location), which this PR also adds, replacing
## whichever world scene is currently active.
##
## No submenus/zones/fast-travel-cost mechanic -- four flat buttons, one
## per shipped world scene. Not a designed map screen (no art, no
## world-layout doc exists), same "placeholder interaction, not a
## designed one" disclosure every prior scene/overlay's docstring makes.

signal travel_requested(location: String)
signal closed

const LOCATIONS := ["Farm", "Ranch", "Forage", "Mine"]

@onready var _current_label: Label = $Root/Panel/Margin/VBox/CurrentLabel
@onready var _location_list: VBoxContainer = $Root/Panel/Margin/VBox/LocationList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var current_location: String = "Farm"

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_current_label.text = "Current location: %s" % current_location
	for location in LOCATIONS:
		var button := Button.new()
		button.name = "Travel_%s" % location
		button.text = "Travel to %s" % location
		button.pressed.connect(_on_travel_pressed.bind(location))
		_location_list.add_child(button)

func _on_travel_pressed(location: String) -> void:
	travel_requested.emit(location)
	closed.emit()

func _on_close_pressed() -> void:
	closed.emit()
