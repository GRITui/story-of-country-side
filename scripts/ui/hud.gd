extends CanvasLayer
class_name HUD
## Always-on gameplay HUD — PO-16BIT-HCI-3 diegetic retro (design/ui-flows/menu-hud-flow-spec.md §2/§4 + PO-16BIT-HCI-3 spec).
##
## Layout per spec (responsive Control anchors, HTML5 Canvas):
##   Top-Right: wooden placard Season/Day/Weekday + clock + weather
##   Top-Left:  stamina bamboo bar + gold G
##   Bottom:    8-slot hotbar + water gauge
##
## Pure display layer: values read from backend autoloads at ready and kept sync via signals.
## Wooden placard / bamboo / water gauge are styled via StyleBoxFlat/ProgressBar custom colors —
## no duplicate state, same reactive discipline as before.

const HOTBAR_SLOT_COUNT := 8
const WATER_GAUGE_MAX := 100

@onready var _date_label: Label = $TopBar/DateCluster/Row/DateLabel
@onready var _weather_label: Label = $TopBar/DateCluster/Row/WeatherLabel
@onready var _gold_label: Label = $TopBar/GoldClockCluster/GoldLabel
@onready var _clock_label: Label = $TopBar/GoldClockCluster/ClockLabel
@onready var _stamina_bar: ProgressBar = $BottomBar/StaminaCluster/StaminaBar
@onready var _hotbar: HBoxContainer = $BottomBar/HotbarCluster/Hotbar
@onready var _water_gauge: ProgressBar = $BottomBar/WaterCluster/WaterGauge if has_node("BottomBar/WaterCluster/WaterGauge") else null
@onready var _top_wood: PanelContainer = $TopBar/DateCluster if has_node("TopBar/DateCluster") else null
@onready var _selection_highlight: ColorRect = null

var _selected_hotbar := 0
var _water_value: int = WATER_GAUGE_MAX

func _ready() -> void:
	_build_hotbar()
	_style_wooden_placard()
	_style_bamboo_bar()
	_style_water_gauge()
	_highlight_slot(_selected_hotbar)

	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_started.connect(_on_day_started)
	StaminaManager.stamina_changed.connect(_on_stamina_changed)
	ShippingBinManager.gold_changed.connect(_on_gold_changed)
	WeatherManager.weather_changed.connect(_on_weather_changed)
	InventoryManager.item_changed.connect(_on_item_changed)

	_refresh_clock()
	_refresh_date()
	_on_stamina_changed(StaminaManager.current_stamina, StaminaManager.max_stamina)
	_on_gold_changed(ShippingBinManager.gold)
	_on_weather_changed(WeatherManager.get_current_weather())
	_refresh_hotbar()

	# Focus safety — ensure canvas keeps keyboard focus after HUD mounts (InputMapManager helper).
	if Engine.has_singleton("InputMapManager") == false and has_node("/root/InputMapManager"):
		var imm: Node = get_node("/root/InputMapManager")
		if imm.has_method("ensure_canvas_focus"):
			imm.ensure_canvas_focus()

func _unhandled_input(event: InputEvent) -> void:
	# Hotbar 1-8 direct
	for i in range(HOTBAR_SLOT_COUNT):
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			_select_hotbar(i)
			get_viewport().set_input_as_handled()
			return
	# Tab / Shift+Tab / Scroll wheel cycle (InputMapManager also synthesizes wheel -> actions)
	if event.is_action_pressed("hotbar_next"):
		_cycle_hotbar(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hotbar_prev"):
		_cycle_hotbar(-1)
		get_viewport().set_input_as_handled()
	# Prevent window scroll: consume wheel even if not cycling
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_viewport().set_input_as_handled()

func _cycle_hotbar(dir: int) -> void:
	_select_hotbar((_selected_hotbar + dir) % HOTBAR_SLOT_COUNT)

func _select_hotbar(idx: int) -> void:
	_selected_hotbar = clampi(idx, 0, HOTBAR_SLOT_COUNT - 1)
	_highlight_slot(_selected_hotbar)

func _highlight_slot(idx: int) -> void:
	for i in range(HOTBAR_SLOT_COUNT):
		if i >= _hotbar.get_child_count():
			continue
		var slot: PanelContainer = _hotbar.get_child(i)
		if slot.has_method("get") and slot.get("self_modulate") != null:
			slot.self_modulate = Color(1.2, 1.05, 0.6) if i == idx else Color(1, 1, 1)
		# Also add a subtle outline via modulate for selected
		slot.modulate = Color(1, 1, 0.85) if i == idx else Color(1, 1, 1)

func _style_wooden_placard() -> void:
	if _top_wood == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.30, 0.18) # warm wood
	sb.border_color = Color(0.22, 0.14, 0.08)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_top_wood.add_theme_stylebox_override("panel", sb)

func _style_bamboo_bar() -> void:
	if _stamina_bar == null:
		return
	# Bamboo green segmented look — ProgressBar fill style
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.18, 0.22, 0.14)
	bg.corner_radius_top_left = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_right = 4
	_stamina_bar.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.42, 0.78, 0.32) # bamboo green
	fg.corner_radius_top_left = 4
	fg.corner_radius_bottom_left = 4
	fg.corner_radius_top_right = 4
	fg.corner_radius_bottom_right = 4
	_stamina_bar.add_theme_stylebox_override("fill", fg)

func _style_water_gauge() -> void:
	if _water_gauge == null:
		return
	_water_gauge.max_value = WATER_GAUGE_MAX
	_water_gauge.value = _water_value
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.20, 0.28)
	bg.corner_radius_top_left = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_right = 4
	_water_gauge.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.36, 0.62, 0.92) # water blue
	fg.corner_radius_top_left = 4
	fg.corner_radius_bottom_left = 4
	fg.corner_radius_top_right = 4
	fg.corner_radius_bottom_right = 4
	_water_gauge.add_theme_stylebox_override("fill", fg)

func set_water_level(v: int) -> void:
	_water_value = clampi(v, 0, WATER_GAUGE_MAX)
	if _water_gauge:
		_water_gauge.value = _water_value

func get_selected_hotbar() -> int:
	return _selected_hotbar

func _build_hotbar() -> void:
	# Clear existing children (idempotent for tests that re-instantiate)
	for c in _hotbar.get_children():
		c.free()
	for i in range(HOTBAR_SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.name = "Slot%d" % i
		# Wooden slot frame
		var sbs := StyleBoxFlat.new()
		sbs.bg_color = Color(0.52, 0.38, 0.22)
		sbs.border_color = Color(0.26, 0.16, 0.08)
		sbs.border_width_left = 2
		sbs.border_width_right = 2
		sbs.border_width_top = 2
		sbs.border_width_bottom = 2
		sbs.corner_radius_top_left = 4
		sbs.corner_radius_top_right = 4
		sbs.corner_radius_bottom_left = 4
		sbs.corner_radius_bottom_right = 4
		slot.add_theme_stylebox_override("panel", sbs)
		var vbox := VBoxContainer.new()
		vbox.name = "VBox"
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		vbox.add_child(icon)
		var label := Label.new()
		label.name = "Count"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		# Slot number hint (1..8)
		var hint := Label.new()
		hint.name = "Hint"
		hint.text = str(i + 1)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color(0.78, 0.68, 0.48))
		hint.add_theme_font_size_override("font_size", 9)
		vbox.add_child(hint)
		slot.add_child(vbox)
		_hotbar.add_child(slot)

func _refresh_hotbar() -> void:
	var items: Dictionary = {}
	if InventoryManager and InventoryManager.has_method("get_all_items"):
		items = InventoryManager.get_all_items()
	elif InventoryManager and InventoryManager.has_method("to_save_dict"):
		items = InventoryManager.to_save_dict().get("counts", {})
	var keys: Array = items.keys()
	keys.sort()
	for i in range(HOTBAR_SLOT_COUNT):
		if i >= _hotbar.get_child_count():
			continue
		var slot: PanelContainer = _hotbar.get_child(i)
		var icon: TextureRect = slot.get_node("VBox/Icon")
		var label: Label = slot.get_node("VBox/Count")
		if i < keys.size():
			var item_id: String = keys[i]
			var count: int = int(items[item_id])
			label.text = "x%d" % count
			var tex: Texture2D = null
			for cand in ["res://assets/16bit/items/icon_%s.png" % item_id, "res://assets/16bit/items/%s.png" % item_id]:
				if ResourceLoader.exists(cand):
					var maybe: Texture2D = load(cand)
					if maybe and maybe.get_image():
						tex = maybe
						break
			icon.texture = tex
			slot.visible = true
		else:
			label.text = ""
			icon.texture = null
			# Keep empty slots visible as wooden frames (spec: 8-slot hotbar always visible)
			slot.visible = true
			label.text = ""

func _on_item_changed(_item_id: String, _delta: int, _total: int) -> void:
	_refresh_hotbar()

func _on_gold_changed(new_gold: int) -> void:
	_gold_label.text = "%d G" % new_gold

func _on_stamina_changed(current: int, max_stamina: int) -> void:
	_stamina_bar.max_value = max_stamina
	_stamina_bar.value = current
	if current <= 0:
		_stamina_bar.modulate = Color(0.85, 0.2, 0.2)
	else:
		_stamina_bar.modulate = Color(1, 1, 1)

func _on_minute_passed(_hour: int, _minute: int) -> void:
	_refresh_clock()

func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	_refresh_date()

func _on_weather_changed(weather: String) -> void:
	var display_text := weather
	if WeatherManager and WeatherManager.has_method("is_storm_today") and WeatherManager.is_storm_today():
		display_text = "⛈️ %s" % weather
	var forecast := ""
	if WeatherManager and WeatherManager.has_method("get_weather_for_date") and TimeManager:
		var tomorrow_day := TimeManager.day_in_season + 1
		var tomorrow_season := TimeManager.current_season()
		if tomorrow_day > TimeManager.DAYS_PER_SEASON:
			tomorrow_day = 1
		forecast = WeatherManager.get_weather_for_date(tomorrow_season, tomorrow_day)
	if forecast != "":
		_weather_label.text = "%s | Next: %s" % [display_text, forecast]
	else:
		_weather_label.text = display_text

func _refresh_clock() -> void:
	_clock_label.text = format_clock(TimeManager.hour, TimeManager.minute)

func _refresh_date() -> void:
	_date_label.text = format_date(TimeManager.current_day_of_week(), TimeManager.current_season(),
		TimeManager.day_in_season, TimeManager.year)

static func format_clock(hour: int, minute: int) -> String:
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	var suffix := "AM" if hour < 12 else "PM"
	return "%d:%02d %s" % [display_hour, minute, suffix]

static func format_date(day_of_week: String, season: String, day_in_season: int, year: int) -> String:
	return "%s, %s %d (Yr %d)" % [day_of_week, season, day_in_season, year]
