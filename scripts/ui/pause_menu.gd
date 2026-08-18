extends CanvasLayer
class_name PauseMenu
## In-game pause menu (design/ui-flows/menu-hud-flow-spec.md §1).
##
## Toggled by the built-in `ui_cancel` action (Escape by default) --
## project.godot has no [input] section yet, so this reuses Godot's default
## action instead of adding a new one and touching that shared file for no
## reason. Freezes TimeManager via freeze("pause")/unfreeze("pause") while
## open, reusing the same reference-counted freeze mechanism the festival
## system (#21) already established -- one time-freeze mechanism, per the
## spec's own §1 rule, not a second one.
##
## Menu items per the spec's §1 tree: Resume, Inventory, Map, Skills /
## Progression, Settings, Save & Quit to Title. Only Resume and Inventory
## are real destinations this PR -- Map, Skills, and Settings have no
## backing scene/system to open yet (no MapManager/SkillManager UI/settings
## system exists), so they're wired as disabled buttons clearly labelled
## "(not yet implemented)" rather than either faking a screen or silently
## omitting the menu item the spec lists. Save & Quit to Title is also
## partial: there is no title screen yet (see main_controller.gd's own
## docstring on this gap), so it calls the real SaveManager.save_game()
## and then quits the application outright instead of returning to a title
## screen that doesn't exist -- flagged here and in the PR, not faked.

const PAUSE_REASON := "pause"

@onready var _menu_panel: Control = $Root/MenuPanel
@onready var _resume_button: Button = $Root/MenuPanel/Margin/VBox/ResumeButton
@onready var _inventory_button: Button = $Root/MenuPanel/Margin/VBox/InventoryButton
@onready var _map_button: Button = $Root/MenuPanel/Margin/VBox/MapButton
@onready var _skills_button: Button = $Root/MenuPanel/Margin/VBox/SkillsButton
@onready var _settings_button: Button = $Root/MenuPanel/Margin/VBox/SettingsButton
@onready var _save_quit_button: Button = $Root/MenuPanel/Margin/VBox/SaveQuitButton

var _inventory_overlay: InventoryOverlay
var _is_open := false

func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_inventory_button.pressed.connect(_on_inventory_pressed)
	_save_quit_button.pressed.connect(_on_save_quit_pressed)
	# Map/Skills/Settings have no destination yet -- disabled, not hidden,
	# so the menu shape matches the spec's §1 tree even though three of its
	# six items aren't implemented.
	_map_button.disabled = true
	_skills_button.disabled = true
	_settings_button.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_open:
		# While the Inventory sub-screen is showing, Escape backs out to the
		# pause menu first rather than resuming straight through it.
		if _inventory_overlay != null and is_instance_valid(_inventory_overlay):
			_close_inventory()
		else:
			close()
	else:
		open()
	get_viewport().set_input_as_handled()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_menu_panel.visible = true
	TimeManager.freeze(PAUSE_REASON)

func close() -> void:
	if not _is_open:
		return
	_close_inventory()
	_is_open = false
	visible = false
	TimeManager.unfreeze(PAUSE_REASON)

func is_open() -> bool:
	return _is_open

func _on_resume_pressed() -> void:
	close()

func _on_inventory_pressed() -> void:
	_menu_panel.visible = false
	_inventory_overlay = load("res://scenes/ui/InventoryOverlay.tscn").instantiate()
	add_child(_inventory_overlay)
	_inventory_overlay.closed.connect(_close_inventory)

func _close_inventory() -> void:
	if _inventory_overlay != null and is_instance_valid(_inventory_overlay):
		_inventory_overlay.queue_free()
	_inventory_overlay = null
	_menu_panel.visible = true

func _on_save_quit_pressed() -> void:
	SaveManager.save_game()
	get_tree().quit()
