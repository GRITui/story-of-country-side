extends Node
## Shim: social/calendar_manager.gd exists so the spec's
## scripts/social/calendar_manager.gd path resolves.
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
