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
## Progression, Settings, Save & Quit to Title. Resume, Inventory,
## Skills, and (as of this PR) Map are real destinations. Map opens
## MapOverlay, a location switcher for the world scenes (see
## map_overlay.gd's own docstring) -- it emits travel_requested, which
## this menu forwards upward via its own travel_requested signal (a
## parent, e.g. main_controller.gd, connects to that to actually switch
## the active world scene) and closes the whole pause menu on, since
## traveling should return the player to live gameplay rather than leave
## them staring at the menu. Settings still has no backing scene/system
## to open (no settings system exists), so it stays a disabled button
## clearly labelled "(not yet implemented)" rather than either faking a
## screen or silently omitting the menu item the spec lists.
## Save & Quit to Title is also partial: there is no title screen yet
## (see main_controller.gd's own
## docstring on this gap), so it calls the real SaveManager.save_game()
## and then quits the application outright instead of returning to a title
## screen that doesn't exist -- flagged here and in the PR, not faked.
##
## Also has "Relationships" and "Infrastructure" buttons beyond the spec's
## six listed items -- see relationships_overlay.gd's and
## infrastructure_overlay.gd's own docstrings for why: both
## MarriageManager (#20) and InfrastructureManager (#24) shipped after
## the spec's menu tree was written and had no player-facing surface
## anywhere in the repo; this menu is the most natural place to hang one
## for each given there's no NPC dialogue/world-map system yet to launch
## them from instead.

signal travel_requested(location: String)

const PAUSE_REASON := "pause"

@onready var _menu_panel: Control = $Root/MenuPanel
@onready var _resume_button: Button = $Root/MenuPanel/Margin/VBox/ResumeButton
@onready var _inventory_button: Button = $Root/MenuPanel/Margin/VBox/InventoryButton
@onready var _map_button: Button = $Root/MenuPanel/Margin/VBox/MapButton
@onready var _skills_button: Button = $Root/MenuPanel/Margin/VBox/SkillsButton
@onready var _relationships_button: Button = $Root/MenuPanel/Margin/VBox/RelationshipsButton
@onready var _infrastructure_button: Button = $Root/MenuPanel/Margin/VBox/InfrastructureButton
@onready var _settings_button: Button = $Root/MenuPanel/Margin/VBox/SettingsButton
@onready var _save_quit_button: Button = $Root/MenuPanel/Margin/VBox/SaveQuitButton

var _inventory_overlay: InventoryOverlay
var _skills_overlay: SkillsOverlay
var _relationships_overlay: RelationshipsOverlay
var _infrastructure_overlay: InfrastructureOverlay
var _map_overlay: MapOverlay
var _is_open := false

func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_inventory_button.pressed.connect(_on_inventory_pressed)
	_map_button.pressed.connect(_on_map_pressed)
	_skills_button.pressed.connect(_on_skills_pressed)
	_relationships_button.pressed.connect(_on_relationships_pressed)
	_infrastructure_button.pressed.connect(_on_infrastructure_pressed)
	_save_quit_button.pressed.connect(_on_save_quit_pressed)
	# Settings has no destination yet -- disabled, not hidden, so the menu
	# shape still matches the spec's §1 tree even though one of its six
	# items isn't implemented.
	_settings_button.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_open:
		# While the Inventory, Map, Skills, Relationships, or
		# Infrastructure sub-screen is showing, Escape backs out to the
		# pause menu first rather than resuming straight through it.
		if _inventory_overlay != null and is_instance_valid(_inventory_overlay):
			_close_inventory()
		elif _map_overlay != null and is_instance_valid(_map_overlay):
			_close_map()
		elif _skills_overlay != null and is_instance_valid(_skills_overlay):
			_close_skills()
		elif _relationships_overlay != null and is_instance_valid(_relationships_overlay):
			_close_relationships()
		elif _infrastructure_overlay != null and is_instance_valid(_infrastructure_overlay):
			_close_infrastructure()
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
	_close_map()
	_close_skills()
	_close_relationships()
	_close_infrastructure()
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

func _on_map_pressed() -> void:
	_menu_panel.visible = false
	_map_overlay = load("res://scenes/ui/MapOverlay.tscn").instantiate()
	add_child(_map_overlay)
	_map_overlay.closed.connect(_close_map)
	_map_overlay.travel_requested.connect(_on_map_travel_requested)

func _close_map() -> void:
	if _map_overlay != null and is_instance_valid(_map_overlay):
		_map_overlay.queue_free()
	_map_overlay = null
	_menu_panel.visible = true

## Traveling closes the whole pause menu (not just the Map sub-screen) --
## the player should land back in live gameplay at the new location, not
## be left staring at the paused menu they opened Map from.
func _on_map_travel_requested(location: String) -> void:
	travel_requested.emit(location)
	close()

func _on_skills_pressed() -> void:
	_menu_panel.visible = false
	_skills_overlay = load("res://scenes/ui/SkillsOverlay.tscn").instantiate()
	add_child(_skills_overlay)
	_skills_overlay.closed.connect(_close_skills)

func _close_skills() -> void:
	if _skills_overlay != null and is_instance_valid(_skills_overlay):
		_skills_overlay.queue_free()
	_skills_overlay = null
	_menu_panel.visible = true

func _on_relationships_pressed() -> void:
	_menu_panel.visible = false
	_relationships_overlay = load("res://scenes/ui/RelationshipsOverlay.tscn").instantiate()
	add_child(_relationships_overlay)
	_relationships_overlay.closed.connect(_close_relationships)

func _close_relationships() -> void:
	if _relationships_overlay != null and is_instance_valid(_relationships_overlay):
		_relationships_overlay.queue_free()
	_relationships_overlay = null
	_menu_panel.visible = true

func _on_infrastructure_pressed() -> void:
	_menu_panel.visible = false
	_infrastructure_overlay = load("res://scenes/ui/InfrastructureOverlay.tscn").instantiate()
	add_child(_infrastructure_overlay)
	_infrastructure_overlay.closed.connect(_close_infrastructure)

func _close_infrastructure() -> void:
	if _infrastructure_overlay != null and is_instance_valid(_infrastructure_overlay):
		_infrastructure_overlay.queue_free()
	_infrastructure_overlay = null
	_menu_panel.visible = true

func _on_save_quit_pressed() -> void:
	SaveManager.save_game()
	get_tree().quit()
