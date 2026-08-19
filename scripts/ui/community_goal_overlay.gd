extends CanvasLayer
class_name CommunityGoalOverlay
## Full-screen Community Goal contribution overlay against
## CommunityGoalManager (ENG-27): a Community-Center-style bundle/
## collection goal, reachable from the pause menu.
##
## Not one of menu-hud-flow-spec.md §1's six listed pause-menu items --
## same situation as Relationships/Infrastructure (that tree predates
## CommunityGoalManager, which shipped after the spec). Adds one more
## pause-menu entry beyond the spec's fixed list, same "Frontend can
## produce its own convention decisions when claiming unspec'd scope"
## precedent SQUAD-SPLIT.md's UX-GRID note describes.
##
## This overlay was blocked until PR #72 added list_bundle_ids()/
## get_bundle_definition() -- CommunityGoalManager previously exposed no
## way to enumerate registered bundles or read a bundle's title/
## required_items composition, only per-bundle-id/item-id queries that
## require already knowing which bundle_ids/item_ids exist. Hardcoding
## all 10 bundles' content from _register_default_content() into frontend
## code was considered and rejected (flagged as a Cross-Squad Request
## instead, see squad-handshake-frontend.md's epoch 24 notes): unlike the
## small, stable lists SkillsOverlay/InfrastructureOverlay hardcode (4
## skill names, 3 machine types), bundle composition is exactly what
## Content-Squad actively retunes, so a frontend-side copy would silently
## drift stale after any content edit. This overlay reads bundles live via
## the new getters instead.
##
## Bundle list wrapped in a ScrollContainer -- unlike every prior overlay
## (Skills: 4 rows, Infrastructure: ~9 rows), 10 bundles x up to 4 items
## each is too tall to fit the fixed-size panel every other overlay uses
## without one.
##
## "Contribute" per item row sends everything currently held
## (InventoryManager.get_count(item_id)), clamped to what's still needed --
## contribute_item() itself does that clamping (never over-contributes,
## never removes more than it credits), this button just doesn't
## duplicate that math, it passes the held count and lets the backend
## decide the actual transferred amount. No quantity-picker UI (spinbox
## etc.) -- "contribute everything you can right now" is the simplest
## placeholder interaction that doesn't require inventing a design no
## other overlay in this repo has needed yet.
##
## Pure display + action layer, same discipline as every prior overlay:
## every row reads from CommunityGoalManager/InventoryManager at
## scene-ready time and stays in sync via CommunityGoalManager's public
## signals -- no local duplicate contribution/completion state.

signal closed

@onready var _progress_label: Label = $Root/Panel/Margin/VBox/ProgressLabel
@onready var _bundle_list: VBoxContainer = $Root/Panel/Margin/VBox/ScrollContainer/BundleList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _bundle_ids: Array = []
var _title_labels: Dictionary = {} # bundle_id -> Label
var _item_rows: Dictionary = {} # bundle_id -> {item_id -> {progress: Label, action: Button}}

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)

	CommunityGoalManager.bundle_contribution_added.connect(_on_contribution_added)
	CommunityGoalManager.bundle_completed.connect(_on_bundle_completed)

	_bundle_ids = CommunityGoalManager.list_bundle_ids()
	_bundle_ids.sort() # deterministic order, same reasoning FestivalManager.get_festival_for_date's own sort uses
	_build_bundle_rows()
	_refresh_progress_label()
	for bundle_id in _bundle_ids:
		_refresh_bundle(bundle_id)

func _build_bundle_rows() -> void:
	for bundle_id in _bundle_ids:
		var def: BundleDefinition = CommunityGoalManager.get_bundle_definition(bundle_id)
		if def == null:
			continue

		var section := VBoxContainer.new()
		section.name = "Bundle_%s" % bundle_id
		section.add_theme_constant_override("separation", 2)

		var title_label := Label.new()
		title_label.text = def.title
		title_label.add_theme_font_size_override("font_size", 18)
		section.add_child(title_label)
		_title_labels[bundle_id] = title_label

		_item_rows[bundle_id] = {}
		for item_id in def.required_items.keys():
			var row := HBoxContainer.new()
			row.name = "Item_%s" % item_id
			row.add_theme_constant_override("separation", 12)

			var item_label := Label.new()
			item_label.text = item_id
			item_label.custom_minimum_size = Vector2(160, 0)
			row.add_child(item_label)

			var progress_label := Label.new()
			progress_label.custom_minimum_size = Vector2(80, 0)
			row.add_child(progress_label)

			var action_button := Button.new()
			action_button.text = "Contribute"
			action_button.pressed.connect(_on_contribute_pressed.bind(bundle_id, item_id))
			row.add_child(action_button)

			section.add_child(row)
			_item_rows[bundle_id][item_id] = {"progress": progress_label, "action": action_button}

		_bundle_list.add_child(section)

func _refresh_progress_label() -> void:
	_progress_label.text = "Bundles completed: %d/%d" % [
		CommunityGoalManager.bundles_completed_count(), CommunityGoalManager.bundles_total_count()]

func _refresh_bundle(bundle_id: String) -> void:
	var def: BundleDefinition = CommunityGoalManager.get_bundle_definition(bundle_id)
	if def == null:
		return
	var complete := CommunityGoalManager.is_bundle_complete(bundle_id)
	var title_label: Label = _title_labels.get(bundle_id)
	if title_label != null:
		title_label.text = "%s (Complete!)" % def.title if complete else def.title

	var rows: Dictionary = _item_rows.get(bundle_id, {})
	for item_id in def.required_items.keys():
		var required: int = def.required_items[item_id]
		var contributed := CommunityGoalManager.contributed_count(bundle_id, item_id)
		var row: Dictionary = rows.get(item_id, {})
		if row.is_empty():
			continue
		var progress_label: Label = row["progress"]
		var action_button: Button = row["action"]
		progress_label.text = "%d/%d" % [contributed, required]
		var held := InventoryManager.get_count(item_id)
		action_button.disabled = complete or contributed >= required or held <= 0

func _on_contribute_pressed(bundle_id: String, item_id: String) -> void:
	var held := InventoryManager.get_count(item_id)
	if held > 0:
		CommunityGoalManager.contribute_item(bundle_id, item_id, held)

func _on_contribution_added(bundle_id: String, _item_id: String, _quantity: int) -> void:
	_refresh_bundle(bundle_id)

func _on_bundle_completed(bundle_id: String) -> void:
	_refresh_bundle(bundle_id)
	_refresh_progress_label()

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if CommunityGoalManager.bundle_contribution_added.is_connected(_on_contribution_added):
		CommunityGoalManager.bundle_contribution_added.disconnect(_on_contribution_added)
	if CommunityGoalManager.bundle_completed.is_connected(_on_bundle_completed):
		CommunityGoalManager.bundle_completed.disconnect(_on_bundle_completed)
