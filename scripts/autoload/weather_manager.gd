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

##
## Epsilon depth-pass branch commentary (unioned per QA merge guidance; the
## merged file ships base's weather model -- see _apply_weather_effects()):
## Depth pass per #112: deterministic seed for tests, storm flag,
## is_raining_today(), get_weather_for_date(), rain waters crops.
##
## The Epsilon iteration owned a RandomNumberGenerator so tests could call
## set_weather_seed() for deterministic rolls while keeping the same
## weighted distribution: mostly Sunny, occasional Rainy/Snowy, rare Storm
## (1/20). Rain watering: when the rolled weather was Rainy/Snowy/Storm,
## every active FarmPlot was watered via FarmPlotManager.water() at day
## start -- gameplay-affecting, matching #112's acceptance: "rain waters
## crops". Storm was a rare texture flag (1/20 chance, independent roll)
## consumers (HUD/FX) could read via is_storm_today(), piggybacking on
## rainy/snowy weather rather than replacing the Sunny weight.

signal weather_changed(weather: String)
signal weather_depth_applied(weather: String, crops_watered: int, stamina_lost: int)

const SUNNY := "Sunny"
const RAINY := "Rainy"
const SNOWY := "Snowy"
const STORMY := "Stormy"

## Winter swaps Rainy for Snowy; every other season rolls Sunny/Rainy.
## Weighted so most days are Sunny, same "mostly good weather, occasional
## rain" genre norm as Stardew Valley's own weather table -- placeholder
## odds, not final balance, same honesty as every other content table in
## this repo.
const SUNNY_WEIGHT := 0.7

## Chance that a Rainy day (non-Winter precipitation) becomes Stormy
## instead. Rare texture event, not final balance.
const STORM_WEIGHT := 0.05

## Thematic health cost of a Stormy day, spent via StaminaManager at day
## start like any other action cost.
const STORM_STAMINA_COST := 20

var _current_weather: String = SUNNY

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
	_roll_weather(TimeManager.current_season() if TimeManager else "Spring")

func get_current_weather() -> String:
	return _current_weather

func _on_day_started(_day_in_season: int, season: String, _day_of_week: String) -> void:
	_roll_weather(season)
	_apply_weather_effects()

func _roll_weather(season: String) -> void:
	var rainy_alt := SNOWY if season == "Winter" else RAINY
	var storm_roll := 1.0
	if season != "Winter" and randf() >= SUNNY_WEIGHT:
		storm_roll = randf()
	var new_weather := SUNNY
	if randf() < SUNNY_WEIGHT:
		new_weather = SUNNY
	elif season == "Winter":
		new_weather = SNOWY
	elif storm_roll < STORM_WEIGHT:
		new_weather = STORMY
	else:
		new_weather = RAINY
	if new_weather == _current_weather:
		return
	_current_weather = new_weather
	weather_changed.emit(_current_weather)

## Rain auto-waters every planted plot at day start, mirroring
## InfrastructureManager's sprinkler_system automation. A Stormy day is
## still heavy precipitation, so it waters too. Snowy does not -- crops
## are dormant in Winter. FarmPlotManager.water() is a safe no-op on
## invalid/already-watered plots, so no filtering is needed here beyond
## "is today a precipitating day".
func _apply_weather_effects() -> void:
	var crops_watered := 0
	var stamina_lost := 0
	
	if _current_weather == RAINY or _current_weather == STORMY:
		if FarmPlotManager:
			for position in FarmPlotManager.get_all_positions():
				FarmPlotManager.water(position)
				crops_watered += 1
	
	if _current_weather == STORMY:
		if StaminaManager:
			StaminaManager.spend(STORM_STAMINA_COST)
			stamina_lost = STORM_STAMINA_COST
	
	if crops_watered > 0 or stamina_lost > 0:
		weather_depth_applied.emit(_current_weather, crops_watered, stamina_lost)

func to_save_dict() -> Dictionary:
	return {
		"current_weather": _current_weather,
	}

func from_save_dict(data: Dictionary) -> void:
	_current_weather = data.get("current_weather", SUNNY)
