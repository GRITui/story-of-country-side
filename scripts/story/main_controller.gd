extends Node
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
## #52 sub-scope: FarmScene (the world/tile-rendering scene for
## FarmPlotManager, scenes/world/FarmScene.tscn) is added as a plain Node2D
## sibling here rather than under a CanvasLayer -- it's world-space content,
## not screen-space UI, so it goes in alongside the HUD/pause-menu
## CanvasLayers but stays a regular child of this Node. Shown at the same
## point the HUD is (after the intro finishes / immediately if the intro's
## already been seen) since it's gameplay content the intro's full-screen
## beat should also hide.

@onready var _hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
@onready var _pause_menu_scene: PackedScene = load("res://scenes/ui/PauseMenu.tscn")
@onready var _farm_scene_scene: PackedScene = load("res://scenes/world/FarmScene.tscn")
var _hud: CanvasLayer
var _pause_menu: CanvasLayer
var _farm_scene: Node2D

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
	_show_farm_scene()

func _show_pause_menu() -> void:
	if _pause_menu != null:
		return
	_pause_menu = _pause_menu_scene.instantiate()
	add_child(_pause_menu)

func _show_farm_scene() -> void:
	if _farm_scene != null:
		return
	_farm_scene = _farm_scene_scene.instantiate()
	add_child(_farm_scene)
