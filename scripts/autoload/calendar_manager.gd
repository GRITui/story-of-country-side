extends Node
## Autoload: CalendarManager
## Implements #110: Birthdays + Season Calendar Overlay.

signal date_changed(day: int, season: String)
signal birthday_today(npc_name: String)

var _birthdays: Dictionary = {} ## npc_name -> {season: String, day: int}

func _ready() -> void:
	_register_default_birthdays()
	TimeManager.day_started.connect(_on_day_started)

func _register_default_birthdays() -> void:
	_birthdays = {
		"Elena": {"season": "Spring", "day": 5},
		"Marcus": {"season": "Summer", "day": 12},
		"Priya": {"season": "Fall", "day": 20},
		"Tobias": {"season": "Winter", "day": 15},
		"Sana": {"season": "Spring", "day": 22},
		"Colton": {"season": "Summer", "day": 8}
	}

func _on_day_started(_day: int, season: String, _dow: String) -> void:
	for npc in _birthdays:
		var bday = _birthdays[npc]
		if bday.season == season and bday.day == TimeManager.day_in_season:
			birthday_today.emit(npc)

func get_birthdays_for_season(season: String) -> Array:
	var list = []
	for npc in _birthdays:
		if _birthdays[npc].season == season:
			list.append({"npc": npc, "day": _birthdays[npc].day})
	return list
