extends RefCounted
## Plain registry that aggregates birthdays + festivals for a given date.
const BirthdayRegistryRef = preload("res://scripts/social/birthday_registry.gd")

static func get_birthdays_for_date(season: String, day: int) -> Array:
	return BirthdayRegistryRef.get_birthdays_for_date(season, day)

static func get_festivals_for_date(season: String, day: int) -> Array:
	var result: Array = []
	if is_instance_valid(FestivalManager):
		var def = FestivalManager.get_festival_for_date(season, day)
		if def != null:
			result.append(def)
	return result

static func get_all_for_date(season: String, day: int) -> Dictionary:
	return {
		"birthdays": get_birthdays_for_date(season, day),
		"festivals": get_festivals_for_date(season, day),
	}
