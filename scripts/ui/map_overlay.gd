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

const LOCATIONS := ["Farm", "Ranch", "Forage", "Mine", "SeaCoast", "Mountain"]
const WORLD_MAP_PATH := "res://assets/pixelart/map/world_map.png"

@onready var _current_label: Label = $Root/Panel/Margin/VBox/CurrentLabel
@onready var _location_list: VBoxContainer = $Root/Panel/Margin/VBox/LocationList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var current_location: String = "Farm"

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_current_label.text = "Current location: %s" % current_location
	_add_world_map()
	for location in LOCATIONS:
		var button := Button.new()
		button.name = "Travel_%s" % location
		button.text = "Travel to %s" % location
		button.pressed.connect(_on_travel_pressed.bind(location))
		_location_list.add_child(button)

## Loads world_map.png (256x256 stylized overview) as a centered
## TextureRect inserted above the location buttons. Falls back to no image
## if the asset is missing (headless/CI). Keeps backend autoloads untouched.
func _add_world_map() -> void:
	var container: VBoxContainer = $Root/Panel/Margin/VBox
	var tex: Texture2D = load(WORLD_MAP_PATH)
	if tex == null:
		return
	var map_rect := TextureRect.new()
	map_rect.name = "WorldMap"
	map_rect.texture = tex
	map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_rect.custom_minimum_size = Vector2(256, 256)
	# Insert below CurrentLabel (index 1) so label stays on top
	var insert_index := 1
	if container.get_child_count() > 1:
		insert_index = 1
		# Find CurrentLabel index and place after it
		for i in range(container.get_child_count()):
			if container.get_child(i) == _current_label:
				insert_index = i + 1
				break
	container.add_child(map_rect)
	container.move_child(map_rect, insert_index)
	var caption := Label.new()
	caption.name = "MapCaption"
	caption.text = "Regional overview — travel via buttons below."
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(caption)
	container.move_child(caption, insert_index + 1)

func _on_travel_pressed(location: String) -> void:
	travel_requested.emit(location)
	closed.emit()

func _on_close_pressed() -> void:
	closed.emit()
