class_name NPCScheduleEntry
extends Resource
## One entry in an NPC's daily schedule: "at this time, be at this position."
## Designers can author these as .tres resources without touching code.

@export var hour: int = 6
@export var minute: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var location_name: String = ""

## "Any" matches every season; a specific season only matches that season,
## so a schedule can override e.g. a Winter routine without duplicating
## every other entry.
@export var season: String = "Any"

## Same idea for weather. No WeatherManager exists yet in this repo — this
## field is forward-compatible scaffolding, not a claim that weather-driven
## routines work today. NPCSchedule.get_target_for() accepts "Any" as the
## only weather value until a real weather system lands.
@export var weather: String = "Any"

func matches(for_season: String, for_weather: String) -> bool:
	var season_ok := season == "Any" or season == for_season
	var weather_ok := weather == "Any" or weather == for_weather
	return season_ok and weather_ok

func time_key() -> int:
	return hour * 60 + minute
