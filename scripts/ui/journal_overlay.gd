extends CanvasLayer
class_name JournalOverlay
## Full-screen Collection Journal / Encyclopedia (Issue #117).
##
## Reachable from PauseMenu (next to Fishing/Community Goal). Four tabs:
## Fish / Crops / Ore / Forage. Each tab lists every known item for that
## category (via JournalManager.get_catalog) and shows discovered items
## with name + price/season hint vs undiscovered as "???".
##
## Pure display layer: reads JournalManager at ready time and stays in
## sync via its entry_discovered signal -- no local duplicate ledger.
## Mirrors every other overlay's pattern (SkillsOverlay, InventoryOverlay).
##
## Completion footer shows "Discovered X / Y (Z%)" for the active tab and
## an overall total.

signal closed

const TAB_CATEGORIES: Array[String] = ["fish", "crop", "ore", "forage"]
const TAB_LABELS: Dictionary = {
	"fish": "Fish",
	"crop": "Crops",
	"ore": "Ore",
	"forage": "Forage",
}

@onready var _tab_buttons: HBoxContainer = $Root/Panel/Margin/VBox/TabBar
@onready var _entry_list: VBoxContainer = $Root/Panel/Margin/VBox/ScrollContainer/EntryList
@onready var _progress_label: Label = $Root/Panel/Margin/VBox/ProgressLabel
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _active_category: String = "fish"
var _tab_button_nodes: Dictionary = {} # category -> Button

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	JournalManager.entry_discovered.connect(_on_entry_discovered)
	_build_tab_buttons()
	_switch_to(_active_category)

func _build_tab_buttons() -> void:
	for cat in TAB_CATEGORIES:
		var btn := Button.new()
		btn.name = "Tab_%s" % cat
		btn.text = TAB_LABELS.get(cat, cat)
		btn.pressed.connect(_on_tab_pressed.bind(cat))
		_tab_buttons.add_child(btn)
		_tab_button_nodes[cat] = btn
	_refresh_tab_highlight()

func _on_tab_pressed(category: String) -> void:
	_switch_to(category)

func _switch_to(category: String) -> void:
	_active_category = category
	_refresh_tab_highlight()
	_rebuild_entry_list()

func _refresh_tab_highlight() -> void:
	for cat in _tab_button_nodes.keys():
		var btn: Button = _tab_button_nodes[cat]
		btn.disabled = (cat == _active_category)

func _rebuild_entry_list() -> void:
	for child in _entry_list.get_children():
		child.free()

	var catalog := JournalManager.get_catalog(_active_category)
	if catalog.is_empty():
		var label := Label.new()
		label.text = "No entries."
		_entry_list.add_child(label)
	else:
		for item_id in catalog:
			var row := _build_entry_row(item_id)
			_entry_list.add_child(row)
	_refresh_progress()

func _build_entry_row(item_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Entry_%s" % item_id
	row.add_theme_constant_override("separation", 10)

	var discovered := JournalManager.is_discovered(item_id)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(160, 0)
	if discovered:
		var entry = JournalManager.get_entry(item_id)
		if entry != null and not entry.display_name.is_empty():
			name_label.text = entry.display_name
		else:
			name_label.text = item_id.capitalize().replace("_", " ")
	else:
		name_label.text = "???"
	row.add_child(name_label)

	var hint_label := Label.new()
	hint_label.custom_minimum_size = Vector2(260, 0)
	if discovered:
		hint_label.text = _hint_for_item(item_id, _active_category)
	else:
		hint_label.text = "Undiscovered"
		hint_label.modulate = Color(0.6, 0.6, 0.6)
	row.add_child(hint_label)

	var status_label := Label.new()
	status_label.text = "★" if discovered else "☆"
	status_label.custom_minimum_size = Vector2(20, 0)
	row.add_child(status_label)

	return row

func _hint_for_item(item_id: String, category: String) -> String:
	match category:
		"fish":
			var def = FishingManager.get_fish_definition(item_id)
			if def == null:
				return ""
			var price := FishingManager.get_sell_price(item_id, "normal")
			var seasons := ", ".join(def.valid_seasons)
			var locs := ", ".join(def.valid_locations)
			var time_hint := _fish_time_hint(def)
			return "Price: %dg | Season: %s | Location: %s | %s" % [price, seasons, locs, time_hint]
		"crop":
			var def2 = FarmPlotManager.get_crop_definition(item_id)
			if def2 == null:
				return ""
			var price2 := FarmPlotManager.get_sell_price(item_id, "normal")
			var seasons2 := ", ".join(def2.valid_seasons)
			return "Price: %dg | Season: %s | Grow: %dd" % [price2, seasons2, def2.days_to_grow]
		"ore":
			if item_id == MiningManager.STONE_ITEM_ID:
				return "Price: 2g | Common stone"
			# Find ore def for xp/floor hint
			return "Ore | Floor-gated"
		"forage":
			var def3 = ForagingManager.get_forageable_definition(item_id)
			if def3 == null:
				return ""
			var price3 := ForagingManager.get_sell_price(item_id)
			var seasons3 := ", ".join(def3.valid_seasons)
			return "Price: %dg | Season: %s" % [price3, seasons3]
	return ""

func _refresh_progress() -> void:
	var prog: Dictionary = JournalManager.get_progress(_active_category)
	var discovered: int = prog.get("discovered", 0)
	var total: int = prog.get("total", 0)
	var ratio: float = prog.get("ratio", 0.0)
	if total == 0:
		_progress_label.text = "No entries in this category."
	else:
		_progress_label.text = "Discovered %d / %d (%.0f%%)" % [discovered, total, ratio * 100.0]

func _on_entry_discovered(_item_id: String, _category: String) -> void:
	# If the discovered entry belongs to the active tab, rebuild so the
	# new "???" flips to its name immediately.
	_rebuild_entry_list()

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if JournalManager.entry_discovered.is_connected(_on_entry_discovered):
		JournalManager.entry_discovered.disconnect(_on_entry_discovered)
