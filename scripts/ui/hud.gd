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
## Hotbar (S-Tier Zeta #94): live display of selected inventory item + count,
## reactive via InventoryManager.item_changed. The selected item is the most
## recently changed non-zero item; if that item is depleted, falls back to
## the first remaining item, otherwise shows empty. Slot 0 is the "selected"
## highlight; remaining slots stay as plain visuals so the layout region is
## not rewritten away from the placeholder spec.

const HOTBAR_SLOT_COUNT := 8

@onready var _date_label: Label = $TopBar/DateCluster/Row/DateLabel
@onready var _weather_label: Label = $TopBar/DateCluster/Row/WeatherLabel
@onready var _gold_label: Label = $TopBar/GoldClockCluster/GoldLabel
@onready var _clock_label: Label = $TopBar/GoldClockCluster/ClockLabel
@onready var _stamina_bar: ProgressBar = $BottomBar/StaminaCluster/StaminaBar
@onready var _hotbar: HBoxContainer = $BottomBar/HotbarCluster/Hotbar

var _selected_item_id: String = ""
var _hotbar_slots: Array[Panel] = []
var _hotbar_labels: Array[Label] = []

func _ready() -> void:
	_build_hotbar_placeholder()
	_prime_hotbar_from_inventory()

	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_started.connect(_on_day_started)
	StaminaManager.stamina_changed.connect(_on_stamina_changed)
	ShippingBinManager.gold_changed.connect(_on_gold_changed)
	WeatherManager.weather_changed.connect(_on_weather_changed)
	InventoryManager.item_changed.connect(_on_inventory_changed)

	# Prime every cluster with current state immediately -- don't wait for
	# the first signal fire after the HUD enters the tree, or the player
	# would see stale/placeholder text for up to a minute.
	_refresh_clock()
	_refresh_date()
	_on_stamina_changed(StaminaManager.current_stamina, StaminaManager.max_stamina)
	_on_gold_changed(ShippingBinManager.gold)
	_on_weather_changed(WeatherManager.get_current_weather())

func _exit_tree() -> void:
	if InventoryManager.item_changed.is_connected(_on_inventory_changed):
		InventoryManager.item_changed.disconnect(_on_inventory_changed)
	if TimeManager.minute_passed.is_connected(_on_minute_passed):
		TimeManager.minute_passed.disconnect(_on_minute_passed)
	if TimeManager.day_started.is_connected(_on_day_started):
		TimeManager.day_started.disconnect(_on_day_started)
	if StaminaManager.stamina_changed.is_connected(_on_stamina_changed):
		StaminaManager.stamina_changed.disconnect(_on_stamina_changed)
	if ShippingBinManager.gold_changed.is_connected(_on_gold_changed):
		ShippingBinManager.gold_changed.disconnect(_on_gold_changed)
	if WeatherManager.weather_changed.is_connected(_on_weather_changed):
		WeatherManager.weather_changed.disconnect(_on_weather_changed)

func _build_hotbar_placeholder() -> void:
	for i in range(HOTBAR_SLOT_COUNT):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.name = "Slot%d" % i
		var label := Label.new()
		label.name = "SlotLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = ""
		# Center label inside panel via anchors
		slot.add_child(label)
		label.anchors_preset = 15
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0
		label.offset_left = 2
		label.offset_top = 2
		label.offset_right = -2
		label.offset_bottom = -2
		_hotbar.add_child(slot)
		_hotbar_slots.append(slot)
		_hotbar_labels.append(label)
	_update_hotbar_display()

func _prime_hotbar_from_inventory() -> void:
	var counts: Dictionary = InventoryManager.to_save_dict().get("counts", {})
	if counts.is_empty():
		_selected_item_id = ""
		return
	# Pick first non-zero as selected for initial display
	for item_id in counts.keys():
		if int(counts[item_id]) > 0:
			_selected_item_id = item_id
			break
	_update_hotbar_display()

func _on_inventory_changed(item_id: String, _delta: int, total: int) -> void:
	if total > 0:
		_selected_item_id = item_id
	else:
		if item_id == _selected_item_id:
			# Fallback to first remaining item, or empty
			var counts: Dictionary = InventoryManager.to_save_dict().get("counts", {})
			_selected_item_id = ""
			for key in counts.keys():
				if key != item_id and int(counts[key]) > 0:
					_selected_item_id = key
					break
			# Also handle case where counts hasn't yet removed the depleted key
			if _selected_item_id == "" and not counts.has(item_id):
				# try any remaining
				for key in counts.keys():
					_selected_item_id = key
					break
	_update_hotbar_display()

func _update_hotbar_display() -> void:
	if _hotbar_labels.is_empty():
		return
	# Slot 0 is the selected item highlight
	for i in range(_hotbar_labels.size()):
		var lbl: Label = _hotbar_labels[i]
		var slot: Panel = _hotbar_slots[i]
		if i == 0:
			if _selected_item_id.is_empty():
				lbl.text = ""
				slot.modulate = Color(1, 1, 1, 0.6)
			else:
				var count := InventoryManager.get_count(_selected_item_id)
				if count <= 0:
					lbl.text = ""
					slot.modulate = Color(1, 1, 1, 0.6)
				else:
					lbl.text = "%s x%d" % [_selected_item_id, count]
					slot.modulate = Color(1, 1, 0.9)
		else:
			lbl.text = ""
			slot.modulate = Color(1, 1, 1, 0.4)

## Exposed for tests: what item the hotbar currently shows as selected.
func get_selected_item() -> String:
	return _selected_item_id

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
