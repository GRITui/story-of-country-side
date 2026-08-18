extends Node
## Autoload: WeatherManager
##
## Rolls one weather value per in-game day, closing a gap flagged in two
## places: NPCScheduleEntry.weather (#18) has been dead scaffolding since
## it landed -- "No WeatherManager exists yet... only weather value until
## a real weather system lands" -- and issue #52's own text flags weather
## as missing from the HUD. This is intentionally the minimal real system:
## one string value, rolled once a day, read via a public getter/signal.
## No rain-affects-crops/no-need-to-water mechanic, no umbrella item, no
## weather forecast UI -- none of that is asked for anywhere in the design
## doc or either issue; fabricating it here would be unrequested scope.
##
## Same "content reloads every boot, don't fabricate save-worthy structure
## nothing needs" instinct as FestivalManager's own docstring, but weather
## genuinely IS mid-day state a save must round-trip (unlike a festival,
## which is fully re-derivable from date alone) -- so, unlike
## FestivalManager, this DOES have a to_save_dict()/from_save_dict() pair.

signal weather_changed(weather: String)

const SUNNY := "Sunny"
const RAINY := "Rainy"
const SNOWY := "Snowy"

## Winter swaps Rainy for Snowy; every other season rolls Sunny/Rainy.
## Weighted so most days are Sunny, same "mostly good weather, occasional
## rain" genre norm as Stardew Valley's own weather table -- placeholder
## odds, not final balance, same honesty as every other content table in
## this repo.
const SUNNY_WEIGHT := 0.7

var _current_weather: String = SUNNY

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
	_roll_weather(TimeManager.current_season() if TimeManager else "Spring")

func get_current_weather() -> String:
	return _current_weather

func _on_day_started(_day_in_season: int, season: String, _day_of_week: String) -> void:
	_roll_weather(season)

func _roll_weather(season: String) -> void:
	var rainy_alt := SNOWY if season == "Winter" else RAINY
	var new_weather := SUNNY if randf() < SUNNY_WEIGHT else rainy_alt
	if new_weather == _current_weather:
		return
	_current_weather = new_weather
	weather_changed.emit(_current_weather)

func to_save_dict() -> Dictionary:
	return {
		"current_weather": _current_weather,
	}

func from_save_dict(data: Dictionary) -> void:
	_current_weather = data.get("current_weather", SUNNY)
