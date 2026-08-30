extends CanvasLayer
class_name HUD
## Always-on gameplay HUD (design/ui-flows/menu-hud-flow-spec.md §2/§4).
##
## Pure display layer: every value shown here is read from a backend autoload
## at scene-ready time and then kept in sync via that autoload's own signals
## (TimeManager.minute_passed/day_started, StaminaManager.stamina_changed,
## ShippingBinManager.gold_changed) -- no HUD-local duplicate state, per the
## spec's §2 rule against the "two clocks / two gold counters" bug class.
##
## Layout is a placeholder per the spec's §2 diagram (top-left date/season
## cluster, top-right gold/clock cluster, bottom-left stamina bar, bottom-
## right hotbar) -- exact colors/typography/iconography are explicitly out
## of scope for the flow spec (blocked on Decision E, art style) so this
## uses default theme styling and plain rectangles/labels. A later UX-UI
## visual pass should restyle these nodes without needing to touch the
## binding logic below.
##
## Content gaps, called out rather than fabricated:
## - The hotbar has no real item-slot binding: InventoryManager is a plain
##   item_id -> count ledger with no "assigned to hotbar slot N" concept and
##   no item metadata (icon/display name). §4 leaves slot count as an open
##   variable for Engineer squad; this ships a fixed-size placeholder strip
##   of empty slot visuals so the layout region exists, and does not fake a
##   binding to specific items.

const HOTBAR_SLOT_COUNT := 9

@onready var _date_label: Label = $TopBar/DateCluster/Row/DateLabel
@onready var _weather_label: Label = $TopBar/DateCluster/Row/WeatherLabel
@onready var _gold_label: Label = $TopBar/GoldClockCluster/GoldLabel
@onready var _clock_label: Label = $TopBar/GoldClockCluster/ClockLabel
@onready var _stamina_bar: ProgressBar = $BottomBar/StaminaCluster/StaminaBar
@onready var _hotbar: HBoxContainer = $BottomBar/HotbarCluster/Hotbar

func _ready() -> void:
	_build_hotbar()

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

func _build_hotbar() -> void:
	for i in range(HOTBAR_SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.name = "Slot%d" % i
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
		slot.add_child(vbox)
		_hotbar.add_child(slot)

func _refresh_hotbar() -> void:
	var items := InventoryManager.get_all_items()
	var keys := items.keys()
	for i in range(HOTBAR_SLOT_COUNT):
		var slot: PanelContainer = _hotbar.get_child(i)
		var icon: TextureRect = slot.get_node("VBox/Icon")
		var label: Label = slot.get_node("VBox/Count")
		if i < keys.size():
			var item_id: String = keys[i]
			var count: int = items[item_id]
			label.text = "x%d" % count
			icon.texture = null
			slot.visible = true
		else:
			label.text = ""
			icon.texture = null
			slot.visible = false

func _on_item_changed(_item_id: String, _delta: int, _total: int) -> void:
	_refresh_hotbar()

func _on_gold_changed(new_gold: int) -> void:
	_gold_label.text = "%d G" % new_gold

func _on_stamina_changed(current: int, max_stamina: int) -> void:
	_stamina_bar.max_value = max_stamina
	_stamina_bar.value = current
	# Pass-out threshold gets a distinct visual state per §2, not just an
	# empty bar -- swap the fill tint rather than inventing a second widget.
	if current <= 0:
		_stamina_bar.modulate = Color(0.85, 0.2, 0.2)
	else:
		_stamina_bar.modulate = Color(1, 1, 1)

func _on_minute_passed(_hour: int, _minute: int) -> void:
	_refresh_clock()

func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	_refresh_date()

func _on_weather_changed(weather: String) -> void:
	_weather_label.text = weather

func _refresh_clock() -> void:
	_clock_label.text = format_clock(TimeManager.hour, TimeManager.minute)

func _refresh_date() -> void:
	_date_label.text = format_date(TimeManager.current_day_of_week(), TimeManager.current_season(),
		TimeManager.day_in_season, TimeManager.year)

## Pure formatting helpers, split out so tests can check the string logic
## without needing a running scene tree.
static func format_clock(hour: int, minute: int) -> String:
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	var suffix := "AM" if hour < 12 else "PM"
	return "%d:%02d %s" % [display_hour, minute, suffix]

static func format_date(day_of_week: String, season: String, day_in_season: int, year: int) -> String:
	return "%s, %s %d (Yr %d)" % [day_of_week, season, day_in_season, year]
