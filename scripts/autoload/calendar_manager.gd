extends Node
## Autoload: CalendarManager
## Aggregates birthdays (BirthdayRegistry) + festivals (FestivalManager) for UI.
const BirthdayRegistryRef = preload("res://scripts/social/birthday_registry.gd")

func get_birthdays_for_date(season: String, day: int) -> Array:
	return BirthdayRegistryRef.get_birthdays_for_date(season, day)

func get_festivals_for_date(season: String, day: int) -> Array:
	var result: Array = []
	if is_instance_valid(FestivalManager):
		var def = FestivalManager.get_festival_for_date(season, day)
		if def != null:
			result.append(def)
	return result

func get_birthdays_today() -> Array:
	if not is_instance_valid(TimeManager):
		return []
	return get_birthdays_for_date(TimeManager.current_season(), TimeManager.day_in_season)

func get_festivals_today() -> Array:
	if not is_instance_valid(TimeManager):
		return []
	return get_festivals_for_date(TimeManager.current_season(), TimeManager.day_in_season)

func is_birthday_today(npc_name: String) -> bool:
	return BirthdayRegistryRef.is_birthday_today(npc_name)

func is_any_birthday_today() -> bool:
	return not get_birthdays_today().is_empty()

func is_festival_today() -> bool:
	return not get_festivals_today().is_empty()
