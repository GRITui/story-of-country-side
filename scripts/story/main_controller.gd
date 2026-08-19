extends Node
class_name MainController
## Attached to scenes/Main.tscn's root node.
##
## ENG-26 (Opening hook): the boot-time entry point this issue's intro
## sequence slots into. There is no title screen / New Game menu built
## yet (design/ui-flows/menu-hud-flow-spec.md §1 specs the UI flow but no
## Engineer-squad ticket has implemented it), so this stands in as the
## minimal "new game" entry point per the issue's instructions: on boot,
## load an existing save if one exists, otherwise start a fresh one via
## SaveManager.new_game(). Either way, the intro sequence plays exactly
## once per save (SaveManager.has_seen_intro() persists across loads) and
## is skipped on every subsequent boot.
##
## When a real title screen lands, it should call SaveManager.new_game()
## itself (from its "New Game" button) and this _ready()-time auto-boot
## behavior should move behind that menu instead of running unconditionally.
##
## The always-on HUD (design/ui-flows/menu-hud-flow-spec.md §2) is added as
## a sibling CanvasLayer here rather than always-present in Main.tscn itself,
## so it can be held back until the intro sequence (if any) finishes -- the
## intro is a full-screen narrative beat, and layering HUD chrome on top of
## it would contradict the spec's "nothing renders as live behind a
## full-screen sequence" intent (§3, applied here to the intro too).
##
## The pause menu (§1) is added alongside the HUD for the same reason: it
## should not be reachable (or its Escape toggle armed) while the intro is
## still playing.
##
## #52 sub-scope: the active world scene (FarmScene et al) is added as a
## plain Node2D sibling here rather than under a CanvasLayer -- it's
## world-space content, not screen-space UI, so it goes in alongside the
## HUD/pause-menu CanvasLayers but stays a regular child of this Node.
## Shown at the same point the HUD is (after the intro finishes /
## immediately if the intro's already been seen) since it's gameplay
## content the intro's full-screen beat should also hide.
##
## Map overlay sub-scope: only one world scene is ever active at a time
## (this repo has no open-world/streaming design -- each activity system's
## scene is a self-contained location). travel_to(location) swaps the
## active one, called from PauseMenu's own travel_requested signal (which
## it forwards from MapOverlay -- see pause_menu.gd/map_overlay.gd's own
## docstrings). Farm is the fixed starting location; there's no save data
## for "which location the player was last in" (SaveManager doesn't track
## it), so every boot starts back at Farm regardless of where a save last
## left off -- a real gap, not silently faked, flagged in this PR.
##
## Festival mini-game sub-scope: FestivalManager.festival_started is
## connected here (not from PauseMenu, since a festival isn't an optional
## menu screen -- see festival_mini_game_overlay.gd's own docstring) and
## shows FestivalMiniGameOverlay full-screen for the festival's duration.
## No save/load re-trigger handling -- FestivalManager itself has no
## to_save_dict()/from_save_dict() (its own docstring: every festival is
## purely date-driven, re-derived from day_started), so a festival active
## at save time simply isn't re-shown after a reload; a real gap in the
## backend's own save model, not something this overlay's wiring can or
## should paper over.

const LOCATION_SCENE_PATHS := {
	"Farm": "res://scenes/world/FarmScene.tscn",
	"Ranch": "res://scenes/world/RanchScene.tscn",
	"Forage": "res://scenes/world/ForageScene.tscn",
	"Mine": "res://scenes/world/MineScene.tscn",
}
const STARTING_LOCATION := "Farm"

@onready var _hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
@onready var _pause_menu_scene: PackedScene = load("res://scenes/ui/PauseMenu.tscn")
var _hud: CanvasLayer
var _pause_menu: CanvasLayer
var _active_world_scene: Node2D
var _current_location: String = "" ## empty until the first travel_to() call, so the initial boot travel isn't a same-location no-op
var _festival_overlay: FestivalMiniGameOverlay

func _ready() -> void:
	if not SaveManager.load_game():
		SaveManager.new_game()
	if not SaveManager.has_seen_intro():
		_play_intro()
	else:
		_show_hud()

func _play_intro() -> void:
	var intro_scene: PackedScene = load("res://scenes/intro/IntroSequence.tscn")
	var intro: IntroSequence = intro_scene.instantiate()
	add_child(intro)
	intro.finished.connect(_on_intro_finished.bind(intro))

func _on_intro_finished(intro: Node) -> void:
	SaveManager.mark_intro_seen()
	intro.queue_free()
	_show_hud()

func _show_hud() -> void:
	if _hud != null:
		return
	_hud = _hud_scene.instantiate()
	add_child(_hud)
	_show_pause_menu()
	travel_to(STARTING_LOCATION)
	FestivalManager.festival_started.connect(_on_festival_started)

func _show_pause_menu() -> void:
	if _pause_menu != null:
		return
	_pause_menu = _pause_menu_scene.instantiate()
	add_child(_pause_menu)
	_pause_menu.travel_requested.connect(travel_to)

func current_location() -> String:
	return _current_location

## Swaps the active world scene. A no-op for an unknown location string
## (defensive against a future MapOverlay location list drifting out of
## sync with this dictionary) or for re-selecting the already-active
## location -- free(), not queue_free(), so a caller checking
## current_location()/the scene tree immediately after this call sees the
## swap already applied, same "callers need this gone immediately"
## reasoning inventory_overlay.gd's _remove_row uses.
func travel_to(location: String) -> void:
	if not LOCATION_SCENE_PATHS.has(location) or location == _current_location:
		return
	if _active_world_scene != null and is_instance_valid(_active_world_scene):
		_active_world_scene.free()
	_active_world_scene = load(LOCATION_SCENE_PATHS[location]).instantiate()
	add_child(_active_world_scene)
	_current_location = location

func _on_festival_started(_festival_id: String) -> void:
	if _festival_overlay != null and is_instance_valid(_festival_overlay):
		return # already showing (shouldn't happen -- FestivalManager only starts one festival at a time)
	_festival_overlay = load("res://scenes/ui/FestivalMiniGameOverlay.tscn").instantiate()
	add_child(_festival_overlay)
	_festival_overlay.closed.connect(_on_festival_overlay_closed)

func _on_festival_overlay_closed() -> void:
	if _festival_overlay != null and is_instance_valid(_festival_overlay):
		_festival_overlay.queue_free()
	_festival_overlay = null
