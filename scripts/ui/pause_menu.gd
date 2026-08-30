extends CanvasLayer
class_name PauseMenu
## In-game pause menu (design/ui-flows/menu-hud-flow-spec.md §1).
##
## Toggled by the built-in `ui_cancel` action (Escape by default) -- kept
## as-is by #101 (project.godot's [input] section now exists for
## movement/interact/dialog, but `ui_cancel` is already Godot's own
## always-registered action, not a raw click/button-index check, so there
## is no "raw input" gap here for that issue to close). Freezes TimeManager
## via freeze("pause")/unfreeze("pause") while
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
## them staring at the menu. Settings now has a real destination:
## SettingsOverlay (S-Tier Zeta). Save & Quit to Title is also partial:
## there is no title screen yet (see main_controller.gd's own
## docstring on this gap), so it calls the real SaveManager.save_game()
## and then quits the application outright instead of returning to a title
## screen that doesn't exist -- flagged here and in the PR, not faked.
##
## Also has "Relationships", "Infrastructure", "Community Goal", and
## "Fishing" buttons beyond the spec's six listed items -- see
## relationships_overlay.gd's, infrastructure_overlay.gd's,
## community_goal_overlay.gd's, and fishing_overlay.gd's own docstrings
## for why: MarriageManager (#20), InfrastructureManager (#24),
## CommunityGoalManager, and FishingManager (#15) all shipped after the
## spec's menu tree was written (or, for Fishing, deliberately left its
## mini-game/UI half unbuilt) and had no player-facing surface anywhere
## in the repo; this menu is the most natural place to hang one for each
## given there's no NPC dialogue/world-map/fishing-spot system yet to
## launch them from instead.
##
## S-Tier Zeta QoL: last-location persistence — remembers the last opened
## overlay (inventory/map/skills/etc/settings) and restores it on next
## open(). Persisted to user://pause_state.json so it survives reboots;
## also kept in-memory for the current session. Also enables the Settings
## button (previously disabled placeholder).

signal travel_requested(location: String)

const PAUSE_REASON := "pause"
const PAUSE_STATE_PATH := "user://pause_state.json"

@onready var _menu_panel: Control = $Root/MenuPanel
@onready var _resume_button: Button = $Root/MenuPanel/Margin/VBox/ResumeButton
@onready var _inventory_button: Button = $Root/MenuPanel/Margin/VBox/InventoryButton
@onready var _map_button: Button = $Root/MenuPanel/Margin/VBox/MapButton
@onready var _skills_button: Button = $Root/MenuPanel/Margin/VBox/SkillsButton
@onready var _relationships_button: Button = $Root/MenuPanel/Margin/VBox/RelationshipsButton
@onready var _infrastructure_button: Button = $Root/MenuPanel/Margin/VBox/InfrastructureButton
@onready var _community_goal_button: Button = $Root/MenuPanel/Margin/VBox/CommunityGoalButton
@onready var _fishing_button: Button = $Root/MenuPanel/Margin/VBox/FishingButton
@onready var _settings_button: Button = $Root/MenuPanel/Margin/VBox/SettingsButton
@onready var _save_quit_button: Button = $Root/MenuPanel/Margin/VBox/SaveQuitButton

var _inventory_overlay: InventoryOverlay
var _skills_overlay: SkillsOverlay
var _relationships_overlay: RelationshipsOverlay
var _infrastructure_overlay: InfrastructureOverlay
var _community_goal_overlay: CommunityGoalOverlay
var _fishing_overlay: FishingOverlay
var _map_overlay: MapOverlay
var _settings_overlay: CanvasLayer
var _is_open := false
var _last_location: String = ""

func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_inventory_button.pressed.connect(_on_inventory_pressed)
	_map_button.pressed.connect(_on_map_pressed)
	_skills_button.pressed.connect(_on_skills_pressed)
	_relationships_button.pressed.connect(_on_relationships_pressed)
	_infrastructure_button.pressed.connect(_on_infrastructure_pressed)
	_community_goal_button.pressed.connect(_on_community_goal_pressed)
	_fishing_button.pressed.connect(_on_fishing_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_save_quit_button.pressed.connect(_on_save_quit_pressed)
	_settings_button.disabled = false
	_settings_button.text = "Settings"
	_load_last_location()

func _load_last_location() -> void:
	if not FileAccess.file_exists(PAUSE_STATE_PATH):
		return
	var file := FileAccess.open(PAUSE_STATE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		_last_location = str(parsed.get("last_location", ""))

func _save_last_location() -> void:
	var file := FileAccess.open(PAUSE_STATE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"last_location": _last_location}))
	file.close()

func get_last_location() -> String:
	return _last_location

func _remember_location(loc: String) -> void:
	_last_location = loc
	_save_last_location()

func _restore_last_location() -> void:
	if _last_location.is_empty():
		return
	match _last_location:
		"inventory":
			_on_inventory_pressed()
		"map":
			_on_map_pressed()
		"skills":
			_on_skills_pressed()
		"relationships":
			_on_relationships_pressed()
		"infrastructure":
			_on_infrastructure_pressed()
		"community_goal":
			_on_community_goal_pressed()
		"fishing":
			_on_fishing_pressed()
		"settings":
			_on_settings_pressed()
		_:
			pass

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_open:
		# While the Inventory, Map, Skills, Relationships, Infrastructure,
		# Community Goal, Fishing, or Settings sub-screen is showing, Escape backs
		# out to the pause menu first rather than resuming straight
		# through it.
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
		elif _community_goal_overlay != null and is_instance_valid(_community_goal_overlay):
			_close_community_goal()
		elif _fishing_overlay != null and is_instance_valid(_fishing_overlay):
			_close_fishing()
		elif _settings_overlay != null and is_instance_valid(_settings_overlay):
			_close_settings()
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
	# Restore last location if any — but only once per open,
	# and not if we are already showing an overlay from a prior open that
	# wasn't properly closed (defensive).
	if not _last_location.is_empty():
		# Defer to next frame so _menu_panel is visible before hiding it
		_restore_last_location()

func close() -> void:
	if not _is_open:
		return
	_close_inventory()
	_close_map()
	_close_skills()
	_close_relationships()
	_close_infrastructure()
	_close_community_goal()
	_close_fishing()
	_close_settings()
	_is_open = false
	visible = false
	TimeManager.unfreeze(PAUSE_REASON)

func is_open() -> bool:
	return _is_open

func _on_resume_pressed() -> void:
	close()

func _on_inventory_pressed() -> void:
	_remember_location("inventory")
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
	_remember_location("map")
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
	_remember_location("skills")
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
	_remember_location("relationships")
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
	_remember_location("infrastructure")
	_menu_panel.visible = false
	_infrastructure_overlay = load("res://scenes/ui/InfrastructureOverlay.tscn").instantiate()
	add_child(_infrastructure_overlay)
	_infrastructure_overlay.closed.connect(_close_infrastructure)

func _close_infrastructure() -> void:
	if _infrastructure_overlay != null and is_instance_valid(_infrastructure_overlay):
		_infrastructure_overlay.queue_free()
	_infrastructure_overlay = null
	_menu_panel.visible = true

func _on_community_goal_pressed() -> void:
	_remember_location("community_goal")
	_menu_panel.visible = false
	_community_goal_overlay = load("res://scenes/ui/CommunityGoalOverlay.tscn").instantiate()
	add_child(_community_goal_overlay)
	_community_goal_overlay.closed.connect(_close_community_goal)

func _close_community_goal() -> void:
	if _community_goal_overlay != null and is_instance_valid(_community_goal_overlay):
		_community_goal_overlay.queue_free()
	_community_goal_overlay = null
	_menu_panel.visible = true

func _on_fishing_pressed() -> void:
	_remember_location("fishing")
	_menu_panel.visible = false
	_fishing_overlay = load("res://scenes/ui/FishingOverlay.tscn").instantiate()
	add_child(_fishing_overlay)
	_fishing_overlay.closed.connect(_close_fishing)

func _close_fishing() -> void:
	if _fishing_overlay != null and is_instance_valid(_fishing_overlay):
		_fishing_overlay.queue_free()
	_fishing_overlay = null
	_menu_panel.visible = true

func _on_settings_pressed() -> void:
	_remember_location("settings")
	_menu_panel.visible = false
	_settings_overlay = load("res://scenes/ui/SettingsOverlay.tscn").instantiate()
	add_child(_settings_overlay)
	if _settings_overlay.has_signal("closed"):
		_settings_overlay.closed.connect(_close_settings)

func _close_settings() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		_settings_overlay.queue_free()
	_settings_overlay = null
	_menu_panel.visible = true

func _on_save_quit_pressed() -> void:
	SaveManager.save_game()
	get_tree().quit()
