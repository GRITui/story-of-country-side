extends CanvasLayer
class_name CalendarOverlay
## Month view showing birthdays + festivals for the current season.
## Pure display layer over CalendarManager / TimeManager — no save logic.
## Spec: month view showing birthdays+festivals

signal closed

@onready var _title_label: Label = $Root/Panel/Margin/VBox/Header/TitleLabel
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton
@onready var _season_label: Label = $Root/Panel/Margin/VBox/SeasonLabel
@onready var _grid: GridContainer = $Root/Panel/Margin/VBox/DayGrid
@onready var _detail_label: Label = $Root/Panel/Margin/VBox/DetailLabel

var _day_buttons: Array[Button] = []

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_build_grid()
	_refresh()

func _build_grid() -> void:
	# 28 days, 7 columns
	for day in range(1, TimeManager.DAYS_PER_SEASON + 1):
		var btn := Button.new()
		btn.text = str(day)
		btn.custom_minimum_size = Vector2(48, 48)
		btn.pressed.connect(_on_day_pressed.bind(day))
		_grid.add_child(btn)
		_day_buttons.append(btn)

func _refresh() -> void:
	var season: String = TimeManager.current_season()
	var today: int = TimeManager.day_in_season
	_title_label.text = "Calendar"
	_season_label.text = "%s — Year %d  (Today: %s %d)" % [season, TimeManager.year, season, today]
	for i in range(_day_buttons.size()):
		var day: int = i + 1
		var btn: Button = _day_buttons[i]
		var birthdays: Array = CalendarManager.get_birthdays_for_date(season, day)
		var festivals: Array = CalendarManager.get_festivals_for_date(season, day)
		var label: String = str(day)
		if not birthdays.is_empty():
			label += "\n🎂"
		if not festivals.is_empty():
			label += "\n🎉"
		btn.text = label
		# Highlight today
		if day == today:
			btn.modulate = Color(1, 0.9, 0.6)
		else:
			btn.modulate = Color(1, 1, 1, 1)
		# Tooltip for hover
		var tip_parts: Array[String] = []
		for b in birthdays:
			tip_parts.append("🎂 %s's Birthday" % b)
		for f in festivals:
			tip_parts.append("🎉 %s" % f.display_name)
		btn.tooltip_text = ", ".join(tip_parts) if not tip_parts.is_empty() else ""
	_detail_label.text = "Select a day to see details.  🎂 = Birthday  🎉 = Festival"

func _on_day_pressed(day: int) -> void:
	var season: String = TimeManager.current_season()
	var birthdays: Array = CalendarManager.get_birthdays_for_date(season, day)
	var festivals: Array = CalendarManager.get_festivals_for_date(season, day)
	var parts: Array[String] = []
	parts.append("%s %d:" % [season, day])
	if birthdays.is_empty() and festivals.is_empty():
		parts.append("Nothing special — a good day to work the farm.")
	else:
		for b in birthdays:
			parts.append("🎂 %s's Birthday — gifts give 8× friendship!" % b)
		for f in festivals:
			parts.append("🎉 %s — %s" % [f.display_name, f.flavor_text])
	_detail_label.text = "\n".join(parts)
	# also handle wedding date hint
	if MarriageManager.is_engaged():
		var wd: Dictionary = MarriageManager.get_wedding_date()
		if wd.get("season") == season and wd.get("day") == day:
			_detail_label.text += "\n💒 Wedding day — %s!" % MarriageManager.engaged_to()

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	pass
