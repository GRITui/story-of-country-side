extends CanvasLayer
class_name ShopOverlay
## Minimal Seed Shop overlay (issue #123, the UI-hook gap PR #122/ENG-91
## flagged): `FarmPlotManager.buy_seed(crop_id, quantity)` landed as a
## callable backend method with no scene/UI hook at all -- the starting
## grant (8 parsnip seeds) covers day 1, but there was no restock path
## once those ran out. This overlay is the smallest player-facing
## purchase surface: one row per purchasable seed type (display name +
## `CropDefinition.seed_price`), a Buy (x1) button that calls
## `buy_seed(crop_id, 1)` directly, and a status line reflecting success
## or failure (insufficient gold, etc.) back to the player.
##
## Same chrome/structure as SkillsOverlay/InventoryOverlay (title
## top-left, close top-right, per menu-hud-flow-spec.md §3's "consistent
## screen chrome" rule) and the same pure-display discipline: rows are
## primed once at _ready() from FarmPlotManager/CropDefinition and then
## kept in sync via FarmPlotManager.seed_purchased and
## ShippingBinManager.gold_changed -- no ShopOverlay-local price/gold
## duplicate. `buy_seed()` itself is never re-validated here (no
## re-checking gold before the call) -- same "let the manager be the one
## source of truth for whether an action succeeds" discipline
## RelationshipsOverlay/InfrastructureOverlay already follow for their
## own gated actions.
##
## ENG-LIST-CROP-IDS: FarmPlotManager.get_all_crop_ids() now exists, so
## the CROP_IDS hardcoded list this docstring used to justify is gone --
## rows are primed straight off the real registered roster instead.
##
## Quantity is fixed at 1 per Buy click (no quantity stepper) -- the
## smallest viable purchase UI per issue #123's "simple toggle... doesn't
## need a dedicated NPC/building yet" framing for v1; a player who wants
## more just clicks again.

signal closed

@onready var _list: VBoxContainer = $Root/Panel/Margin/VBox/SeedList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton
@onready var _gold_label: Label = $Root/Panel/Margin/VBox/Header/GoldLabel
@onready var _status_label: Label = $Root/Panel/Margin/VBox/StatusLabel

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	FarmPlotManager.seed_purchased.connect(_on_seed_purchased)
	ShippingBinManager.gold_changed.connect(_on_gold_changed)
	_prime_from_current_state()

func _prime_from_current_state() -> void:
	for crop_id in FarmPlotManager.get_all_crop_ids():
		_add_row(crop_id)
	_refresh_gold_label()
	_status_label.text = ""

func _add_row(crop_id: String) -> void:
	var def: CropDefinition = FarmPlotManager.get_crop_definition(crop_id)
	if def == null:
		return
	var row := HBoxContainer.new()
	row.name = "Row_%s" % crop_id
	row.add_theme_constant_override("separation", 12)

	# Seed icon (assets/pixelart/items/icon_<crop_id>.png fallback)
	var icon_path := "res://assets/pixelart/items/icon_%s.png" % crop_id
	var icon_tex: Texture2D = load(icon_path)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

	var owned: int = 0
	if InventoryManager and InventoryManager.has_method("get_count"):
		owned = InventoryManager.get_count("%s_seed" % crop_id)
		if owned == 0:
			owned = InventoryManager.get_count(crop_id)
	var price_label := Label.new()
	price_label.name = "PriceLabel_%s" % crop_id
	price_label.text = "%s seed -- %d gold (owned: %d)" % [def.display_name, def.seed_price, owned]
	price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_label.tooltip_text = "Requires %d gold; you have %d gold" % [def.seed_price, ShippingBinManager.gold if ShippingBinManager else 0]
	row.add_child(price_label)

	var buy_button := Button.new()
	buy_button.name = "BuyButton_%s" % crop_id
	buy_button.text = "Buy x1"
	buy_button.disabled = ShippingBinManager.gold < def.seed_price if ShippingBinManager else false
	buy_button.tooltip_text = "Not enough gold" if buy_button.disabled else ""
	buy_button.pressed.connect(_on_buy_pressed.bind(crop_id))
	row.add_child(buy_button)

	_list.add_child(row)

func _on_buy_pressed(crop_id: String) -> void:
	var def: CropDefinition = FarmPlotManager.get_crop_definition(crop_id)
	var seed_display_name := def.display_name if def != null else crop_id
	if FarmPlotManager.buy_seed(crop_id, 1):
		_status_label.text = "Bought 1 %s seed." % seed_display_name
	else:
		_status_label.text = "Can't buy %s seed -- not enough gold." % seed_display_name

func _on_seed_purchased(_crop_id: String, _quantity: int, _total_cost: int) -> void:
	_refresh_gold_label()
	_refresh_rows()

func _on_gold_changed(_new_gold: int) -> void:
	_refresh_gold_label()
	_refresh_rows()

func _refresh_gold_label() -> void:
	_gold_label.text = "Gold: %d" % ShippingBinManager.gold

func _refresh_rows() -> void:
	for child in _list.get_children():
		var crop_id: String = child.name.trim_prefix("Row_")
		var def: CropDefinition = FarmPlotManager.get_crop_definition(crop_id)
		if def == null:
			continue
		var btn: Button = child.get_node_or_null("BuyButton_%s" % crop_id)
		if btn != null and ShippingBinManager:
			btn.disabled = ShippingBinManager.gold < def.seed_price
			btn.tooltip_text = "Not enough gold" if btn.disabled else ""

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if FarmPlotManager.seed_purchased.is_connected(_on_seed_purchased):
		FarmPlotManager.seed_purchased.disconnect(_on_seed_purchased)
	if ShippingBinManager.gold_changed.is_connected(_on_gold_changed):
		ShippingBinManager.gold_changed.disconnect(_on_gold_changed)
