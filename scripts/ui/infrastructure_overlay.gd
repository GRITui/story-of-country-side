extends CanvasLayer
class_name InfrastructureOverlay
## Full-screen Infrastructure Upgrades overlay against InfrastructureManager
## (#24): house/coop tier upgrades and artisan machine build/job flow.
##
## Not one of menu-hud-flow-spec.md §1's six listed pause-menu items --
## same situation as RelationshipsOverlay (that tree predates
## InfrastructureManager, which shipped after the spec). Adds one more
## pause-menu entry beyond the spec's fixed list, same "Frontend can
## produce its own convention decisions when claiming unspec'd scope"
## precedent SQUAD-SPLIT.md's UX-GRID note describes.
##
## Content gap, disclosed rather than worked around: InfrastructureManager
## has no public getter for a tier/recipe's actual cost numbers (gold_cost/
## material_item_id/material_quantity) -- only can_upgrade_house()/
## can_upgrade_coop()/can_build_machine() bool checks and the built/tier
## state getters. _house_tiers/_coop_tiers/_machines (where those numbers
## live) are private. This overlay therefore can't preview "costs 1000
## gold + 50 wood" text; buttons are enabled/disabled by the bool checks
## alone, same as every other overlay's "never duplicate the backend's own
## validation" discipline, just with no cost preview instead of a
## fabricated one. Flagged as a Cross-Squad Request in
## squad-handshake-frontend.md rather than reaching into the private
## dictionaries.
##
## InfrastructureManager also has no "list every machine_type" getter,
## same situation SkillsOverlay hit for SkillManager's skill names. The
## three machine types shown (keg/preserves_jar/mayo_machine) are read
## from existing content -- _register_default_content() registers exactly
## these three -- not invented here.
##
## One job per machine_type, using the machine_type itself as the job_id
## -- InfrastructureManager's start_job(job_id, machine_type) allows an
## arbitrary job_id (implying multiple concurrent jobs per machine could
## be supported), but there's no queue UI designed for that yet, so this
## is this PR's own placeholder interaction model, same disclosure every
## prior scene/overlay's docstring makes for its own placeholder choices.
##
## Pure display + action layer, same discipline as every prior overlay:
## every row reads from InfrastructureManager at scene-ready time and
## stays in sync via its public signals -- no local duplicate tier/job
## state.

signal closed

const MACHINE_TYPES := ["keg", "preserves_jar", "mayo_machine"]

@onready var _house_label: Label = $Root/Panel/Margin/VBox/HouseRow/HouseLabel
@onready var _house_button: Button = $Root/Panel/Margin/VBox/HouseRow/UpgradeHouseButton
@onready var _coop_label: Label = $Root/Panel/Margin/VBox/CoopRow/CoopLabel
@onready var _coop_button: Button = $Root/Panel/Margin/VBox/CoopRow/UpgradeCoopButton
@onready var _machine_list: VBoxContainer = $Root/Panel/Margin/VBox/MachineList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _machine_rows: Dictionary = {} # machine_type -> {status: Label, action: Button}

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_house_button.pressed.connect(_on_upgrade_house_pressed)
	_coop_button.pressed.connect(_on_upgrade_coop_pressed)

	InfrastructureManager.house_upgraded.connect(_on_house_upgraded)
	InfrastructureManager.coop_upgraded.connect(_on_coop_upgraded)
	InfrastructureManager.machine_built.connect(_on_machine_changed)
	InfrastructureManager.artisan_job_started.connect(_on_machine_changed)
	InfrastructureManager.artisan_job_ready.connect(_on_machine_changed)
	InfrastructureManager.artisan_job_collected.connect(_on_machine_changed)

	_build_machine_rows()
	_refresh_house()
	_refresh_coop()
	_refresh_all_machines()

func _build_machine_rows() -> void:
	for machine_type in MACHINE_TYPES:
		var row := HBoxContainer.new()
		row.name = "Machine_%s" % machine_type
		row.add_theme_constant_override("separation", 12)

		var name_label := Label.new()
		name_label.text = machine_type
		name_label.custom_minimum_size = Vector2(140, 0)
		row.add_child(name_label)

		var status_label := Label.new()
		status_label.custom_minimum_size = Vector2(160, 0)
		row.add_child(status_label)

		var action_button := Button.new()
		action_button.pressed.connect(_on_machine_action_pressed.bind(machine_type))
		row.add_child(action_button)

		_machine_list.add_child(row)
		_machine_rows[machine_type] = {"status": status_label, "action": action_button}

func _refresh_house() -> void:
	_house_label.text = "House: Tier %d" % InfrastructureManager.get_house_tier()
	_house_button.disabled = not InfrastructureManager.can_upgrade_house()

func _refresh_coop() -> void:
	_coop_label.text = "Coop: Tier %d (max animals: %d)" % [
		InfrastructureManager.get_coop_tier(), InfrastructureManager.get_max_animal_capacity()]
	_coop_button.disabled = not InfrastructureManager.can_upgrade_coop()

func _refresh_all_machines() -> void:
	for machine_type in MACHINE_TYPES:
		_refresh_machine_row(machine_type)

func _refresh_machine_row(machine_type: String) -> void:
	var row: Dictionary = _machine_rows.get(machine_type, {})
	if row.is_empty():
		return
	var status_label: Label = row["status"]
	var action_button: Button = row["action"]

	if not InfrastructureManager.is_machine_built(machine_type):
		status_label.text = "Not built"
		action_button.text = "Build"
		action_button.disabled = not InfrastructureManager.can_build_machine(machine_type)
		return

	var job: Dictionary = InfrastructureManager.get_job(machine_type)
	if job.is_empty():
		status_label.text = "Built -- idle"
		action_button.text = "Start Job"
		action_button.disabled = false
	elif job.get("ready", false):
		status_label.text = "Ready to collect"
		action_button.text = "Collect"
		action_button.disabled = false
	else:
		status_label.text = "In progress (%d day(s) left)" % int(job.get("days_remaining", 0))
		action_button.text = "Processing..."
		action_button.disabled = true

func _on_machine_action_pressed(machine_type: String) -> void:
	if not InfrastructureManager.is_machine_built(machine_type):
		InfrastructureManager.build_machine(machine_type)
		return
	var job: Dictionary = InfrastructureManager.get_job(machine_type)
	if job.is_empty():
		InfrastructureManager.start_job(machine_type, machine_type)
	elif job.get("ready", false):
		InfrastructureManager.collect_job(machine_type)

func _on_upgrade_house_pressed() -> void:
	InfrastructureManager.upgrade_house()

func _on_upgrade_coop_pressed() -> void:
	InfrastructureManager.upgrade_coop()

func _on_house_upgraded(_new_tier: int) -> void:
	_refresh_house()

func _on_coop_upgraded(_new_tier: int) -> void:
	_refresh_coop()

func _on_machine_changed(machine_type: String, _a = null, _b = null, _c = null) -> void:
	_refresh_machine_row(machine_type)

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if InfrastructureManager.house_upgraded.is_connected(_on_house_upgraded):
		InfrastructureManager.house_upgraded.disconnect(_on_house_upgraded)
	if InfrastructureManager.coop_upgraded.is_connected(_on_coop_upgraded):
		InfrastructureManager.coop_upgraded.disconnect(_on_coop_upgraded)
	if InfrastructureManager.machine_built.is_connected(_on_machine_changed):
		InfrastructureManager.machine_built.disconnect(_on_machine_changed)
	if InfrastructureManager.artisan_job_started.is_connected(_on_machine_changed):
		InfrastructureManager.artisan_job_started.disconnect(_on_machine_changed)
	if InfrastructureManager.artisan_job_ready.is_connected(_on_machine_changed):
		InfrastructureManager.artisan_job_ready.disconnect(_on_machine_changed)
	if InfrastructureManager.artisan_job_collected.is_connected(_on_machine_changed):
		InfrastructureManager.artisan_job_collected.disconnect(_on_machine_changed)
