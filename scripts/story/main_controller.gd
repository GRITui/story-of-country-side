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

func _ready() -> void:
	if not SaveManager.load_game():
		SaveManager.new_game()
	if not SaveManager.has_seen_intro():
		_play_intro()

func _play_intro() -> void:
	var intro_scene: PackedScene = load("res://scenes/intro/IntroSequence.tscn")
	var intro: IntroSequence = intro_scene.instantiate()
	add_child(intro)
	intro.finished.connect(_on_intro_finished.bind(intro))

func _on_intro_finished(intro: Node) -> void:
	SaveManager.mark_intro_seen()
	intro.queue_free()
