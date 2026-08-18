extends CanvasLayer
class_name InventoryOverlay
## Full-screen Inventory overlay (design/ui-flows/menu-hud-flow-spec.md §3),
## reachable from the pause menu (§1).
##
## Pure display layer, same convention as hud.gd: every row is read from
## InventoryManager at scene-ready time and then kept in sync via its
## item_changed signal -- no InventoryOverlay-local duplicate ledger.
##
## InventoryManager (scripts/autoload/inventory_manager.gd) is a plain
## item_id -> count ledger with no enumeration getter and no item metadata
## (icon/display name) -- the same content gap hud.gd already flagged for
## the hotbar. There is no public "give me every non-zero item" method, so
## priming reads InventoryManager.to_save_dict()["counts"] -- an existing
## public method (not a `_`-prefixed field) whose return happens to be a
## duplicate of the full ledger, which is exactly what save/load already
## relies on. This is a read path, not a private-field reach-around.
##
## No icons, sorting, or categories -- a plain "item_id  x count" list per
## row, per the spec's explicit allowance ("one slot-rendering component"
## is a §3 aspiration blocked on the same item-metadata gap; this ships
## the plainest possible reactive list instead of fabricating slot art).

signal closed

@onready var _list: VBoxContainer = $Root/Panel/Margin/VBox/ItemList
@onready var _empty_label: Label = $Root/Panel/Margin/VBox/ItemList/EmptyLabel
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _rows: Dictionary = {} # item_id -> Label

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	InventoryManager.item_changed.connect(_on_item_changed)
	_prime_from_current_state()

func _prime_from_current_state() -> void:
	var counts: Dictionary = InventoryManager.to_save_dict().get("counts", {})
	for item_id in counts.keys():
		_set_row(item_id, counts[item_id])
	_refresh_empty_label()

func _on_item_changed(item_id: String, _delta: int, total: int) -> void:
	if total <= 0:
		_remove_row(item_id)
	else:
		_set_row(item_id, total)
	_refresh_empty_label()

func _set_row(item_id: String, total: int) -> void:
	if total <= 0:
		_remove_row(item_id)
		return
	var label: Label = _rows.get(item_id)
	if label == null:
		label = Label.new()
		label.name = "Item_%s" % item_id
		_list.add_child(label)
		_rows[item_id] = label
	label.text = "%s  x%d" % [item_id, total]

func _remove_row(item_id: String) -> void:
	var label: Label = _rows.get(item_id)
	if label != null:
		# free(), not queue_free() -- callers (including headless tests) need
		# the row gone from the tree immediately, not at end-of-frame.
		label.free()
		_rows.erase(item_id)

func _refresh_empty_label() -> void:
	_empty_label.visible = _rows.is_empty()

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if InventoryManager.item_changed.is_connected(_on_item_changed):
		InventoryManager.item_changed.disconnect(_on_item_changed)
