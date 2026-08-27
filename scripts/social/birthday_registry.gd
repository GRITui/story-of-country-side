class_name BirthdayRegistry
extends RefCounted
## Central birthday registry — npc_name -> {season, day}.
## Pure data lane, no scene logic. Keeps GIFT_PREFERENCE_PATHS's 6 NPCs.
## Dates are spread across the year so every season has a birthday.

const BIRTHDAYS: Dictionary = {
	"Elena": {"season": "Spring", "day": 6},
	"Marcus": {"season": "Summer", "day": 22},
	"Priya": {"season": "Fall", "day": 9},
	"Tobias": {"season": "Winter", "day": 14},
	"Sana": {"season": "Spring", "day": 18},
	"Colton": {"season": "Fall", "day": 3},
}

## Returns {season, day} for npc_name, or {} if unknown.
static func get_birthday(npc_name: String) -> Dictionary:
	return (BIRTHDAYS.get(npc_name, {}) as Dictionary).duplicate()

## True if today (TimeManager.current_season()/day_in_season) matches npc's birthday.
static func is_birthday_today(npc_name: String) -> bool:
	var b: Dictionary = BIRTHDAYS.get(npc_name, {})
	if b.is_empty():
		return false
	if not is_instance_valid(TimeManager):
		return false
	return TimeManager.current_season() == b["season"] and TimeManager.day_in_season == b["day"]

## Helper for tests / CalendarManager: does season/day match npc's birthday without reading TimeManager.
static func is_birthday_on(npc_name: String, season: String, day: int) -> bool:
	var b: Dictionary = BIRTHDAYS.get(npc_name, {})
	if b.is_empty():
		return false
	return b["season"] == season and b["day"] == day

## Returns array of npc_names whose birthday is season/day.
static func get_birthdays_for_date(season: String, day: int) -> Array:
	var result: Array = []
	for npc in BIRTHDAYS.keys():
		var b: Dictionary = BIRTHDAYS[npc]
		if b["season"] == season and b["day"] == day:
			result.append(npc)
	return result
