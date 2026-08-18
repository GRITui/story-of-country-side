extends CanvasLayer
class_name RelationshipsOverlay
## Full-screen Relationships / Marriage overlay against MarriageManager
## (#20) and RelationshipManager (#19).
##
## Not one of menu-hud-flow-spec.md §1's six listed pause-menu items --
## that tree predates MarriageManager/RelationshipManager (both landed
## after the spec) and has no "Relationships" entry. Rather than leaving
## MarriageManager's propose()/marry() with no player-facing surface at
## all (there is no NPC dialogue/interaction system yet to hang a
## "Propose" action off of -- MarriageManager's own docstring anticipates
## "a future ceremony scene (Frontend's territory)" calling marry(), and
## this is that scene), this PR adds one new pause-menu entry beyond the
## spec's fixed list, same "Frontend can produce its own convention
## decisions when claiming unspec'd scope" precedent SQUAD-SPLIT.md's own
## UX-GRID note describes. Same chrome as InventoryOverlay/SkillsOverlay
## (title top-left, close top-right) for consistency with every other
## overlay this menu already opens.
##
## Pure display + action layer, same discipline as every prior overlay:
## every row reads from MarriageManager/RelationshipManager at scene-ready
## time and stays in sync via their public signals -- no local duplicate
## engagement/hearts state. Every action button calls straight into a
## public MarriageManager method (propose()/marry()) and never duplicates
## its own precondition checks beyond what can_propose() already answers
## (same "backend validates, scene never duplicates that check" discipline
## FarmScene/RanchScene/ForageScene/MineScene all follow for their own
## click-to-interact).
##
## "Marry Now" (calls marry() directly instead of waiting out
## WEDDING_PREP_DAYS) is this PR's own placeholder for the "future
## ceremony scene" MarriageManager's docstring names -- no actual
## ceremony animation/sequence exists (no art, no design doc for one), so
## this button stands in as the trigger a real ceremony scene would call
## once its visual sequence finished, same "placeholder interaction, not
## a designed one" disclosure every prior world scene's docstring makes.

signal closed

@onready var _status_label: Label = $Root/Panel/Margin/VBox/StatusLabel
@onready var _marry_now_button: Button = $Root/Panel/Margin/VBox/MarryNowButton
@onready var _npc_list: VBoxContainer = $Root/Panel/Margin/VBox/NpcList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _npc_rows: Dictionary = {} # npc_name -> {hearts: Label, status: Label, propose: Button}

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_marry_now_button.pressed.connect(_on_marry_now_pressed)

	MarriageManager.proposal_accepted.connect(_on_marriage_state_changed)
	MarriageManager.proposal_rejected.connect(_on_proposal_rejected)
	MarriageManager.wedding_scheduled.connect(_on_marriage_state_changed)
	MarriageManager.married.connect(_on_marriage_state_changed)
	MarriageManager.child_born.connect(_on_marriage_state_changed)
	RelationshipManager.points_changed.connect(_on_points_changed)

	_build_npc_rows()
	_refresh_all()

func _build_npc_rows() -> void:
	for npc_name in MarriageManager.MARRIAGEABLE_NPCS:
		var row := HBoxContainer.new()
		row.name = "Npc_%s" % npc_name
		row.add_theme_constant_override("separation", 12)

		var name_label := Label.new()
		name_label.text = npc_name
		name_label.custom_minimum_size = Vector2(80, 0)
		row.add_child(name_label)

		var hearts_label := Label.new()
		row.add_child(hearts_label)

		var status_label := Label.new()
		status_label.custom_minimum_size = Vector2(140, 0)
		row.add_child(status_label)

		var propose_button := Button.new()
		propose_button.text = "Propose"
		propose_button.pressed.connect(_on_propose_pressed.bind(npc_name))
		row.add_child(propose_button)

		_npc_list.add_child(row)
		_npc_rows[npc_name] = {"hearts": hearts_label, "status": status_label, "propose": propose_button}

func _refresh_all() -> void:
	_refresh_status_label()
	_marry_now_button.visible = MarriageManager.is_engaged()
	for npc_name in MarriageManager.MARRIAGEABLE_NPCS:
		_refresh_npc_row(npc_name)

func _refresh_status_label() -> void:
	if MarriageManager.is_married():
		_status_label.text = "Married to %s -- %d children -- +%d gold/day" % [
			MarriageManager.spouse_name(), MarriageManager.children_count(), MarriageManager.daily_gold_bonus()]
	elif MarriageManager.is_engaged():
		_status_label.text = "Engaged to %s -- wedding in %d day(s)" % [
			MarriageManager.engaged_to(), MarriageManager.days_until_wedding()]
	else:
		_status_label.text = "Unmarried"

func _refresh_npc_row(npc_name: String) -> void:
	var row: Dictionary = _npc_rows.get(npc_name, {})
	if row.is_empty():
		return
	var hearts_label: Label = row["hearts"]
	var status_label: Label = row["status"]
	var propose_button: Button = row["propose"]

	hearts_label.text = "%d/%d hearts" % [RelationshipManager.get_hearts(npc_name), RelationshipManager.MAX_HEARTS]

	if MarriageManager.spouse_name() == npc_name:
		status_label.text = "Spouse"
	elif MarriageManager.engaged_to() == npc_name:
		status_label.text = "Engaged"
	else:
		status_label.text = ""

	propose_button.disabled = not MarriageManager.can_propose(npc_name)

func _on_propose_pressed(npc_name: String) -> void:
	MarriageManager.propose(npc_name)

func _on_marry_now_pressed() -> void:
	MarriageManager.marry(MarriageManager.engaged_to())

func _on_marriage_state_changed(_a = null, _b = null) -> void:
	_refresh_all()

func _on_proposal_rejected(_npc_name: String, _reason: String) -> void:
	_refresh_all() # can_propose() may now read differently even on a rejected attempt (e.g. item was checked, not consumed)

func _on_points_changed(npc_name: String, _points: int, _hearts: int) -> void:
	_refresh_npc_row(npc_name)

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if MarriageManager.proposal_accepted.is_connected(_on_marriage_state_changed):
		MarriageManager.proposal_accepted.disconnect(_on_marriage_state_changed)
	if MarriageManager.proposal_rejected.is_connected(_on_proposal_rejected):
		MarriageManager.proposal_rejected.disconnect(_on_proposal_rejected)
	if MarriageManager.wedding_scheduled.is_connected(_on_marriage_state_changed):
		MarriageManager.wedding_scheduled.disconnect(_on_marriage_state_changed)
	if MarriageManager.married.is_connected(_on_marriage_state_changed):
		MarriageManager.married.disconnect(_on_marriage_state_changed)
	if MarriageManager.child_born.is_connected(_on_marriage_state_changed):
		MarriageManager.child_born.disconnect(_on_marriage_state_changed)
	if RelationshipManager.points_changed.is_connected(_on_points_changed):
		RelationshipManager.points_changed.disconnect(_on_points_changed)
