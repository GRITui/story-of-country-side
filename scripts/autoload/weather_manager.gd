extends Node
## Autoload: WeatherManager — S-Tier P2 (Epsilon)
##
## Depth pass per #112: deterministic seed for tests, storm flag,
## is_raining_today(), get_weather_for_date(), rain waters crops.
##
## Rolls one weather value per in-game day.
## Rain watering: when the rolled weather is Rainy/Snowy/Storm, 
## every active FarmPlot is watered via FarmPlotManager.water() at day start.
##
## Storm is a rare texture flag (1/20 chance) that HUD/FX can read.

signal weather_changed(weather: String)
signal weather_depth_applied(weather: String, crops_watered: int, stamina_lost: int)

const SUNNY := "Sunny"
const RAINY := "Rainy"
const SNOWY := "Snowy"
const STORM := "Storm"

const SUNNY_WEIGHT := 0.7
const STORM_CHANCE := 0.05
const STORM_STAMINA_COST := 20

var _current_weather: String = SUNNY
var _is_storm: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
	_roll_weather(TimeManager.current_season() if TimeManager else "Spring")

func get_current_weather() -> String:
	return _current_weather

func is_raining_today() -> bool:
	return _current_weather in [RAINY, SNOWY, STORM]

func is_storm_today() -> bool:
	return _is_storm

func is_snowy_today() -> bool:
	return _current_weather == SNOWY

func get_weather_for_date(season: String, day_of_season: int, seed_override: int = -1) -> String:
	var details := get_weather_details_for_date(season, day_of_season, seed_override)
	return details["weather"]

func get_weather_details_for_date(season: String, day_of_season: int, seed_override: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	var base_seed: int = seed_override if seed_override >= 0 else int(_rng.seed)
	var h: int = base_seed
	for c in season.to_ascii_buffer():
		h = (h * 31 + c) & 0x7fffffff
	h = (h * 131 + day_of_season) & 0x7fffffff
	rng.seed = h if h != 0 else 1
	var storm_roll := rng.randf()
	var will_be_storm := storm_roll < STORM_CHANCE
	var rainy_alt := SNOWY if season == "Winter" else RAINY
	var weather := SUNNY if rng.randf() < SUNNY_WEIGHT else rainy_alt
	var is_storm := will_be_storm and weather != SUNNY
	return {"weather": weather, "is_storm": is_storm}

func _on_day_started(_day: int, season: String, _dow: String) -> void:
	_roll_weather(season)
	_apply_weather_effects()

func _roll_weather(season: String) -> void:
	var storm_roll := _rng.randf()
	var will_be_storm := storm_roll < STORM_CHANCE
	var rainy_alt := SNOWY if season == "Winter" else RAINY
	var new_weather := SUNNY if _rng.randf() < SUNNY_WEIGHT else rainy_alt
	var new_is_storm := will_be_storm and new_weather != SUNNY
	
	if new_weather == _current_weather:
		_is_storm = new_is_storm
		return
	_current_weather = new_weather
	_is_storm = new_is_storm
	weather_changed.emit(_current_weather)

func _apply_weather_effects() -> void:
	var crops_watered := 0
	var stamina_lost := 0
	
	if is_raining_today():
		if FarmPlotManager:
			for position in FarmPlotManager.get_all_positions():
				FarmPlotManager.water(position)
				crops_watered += 1
	
	if _is_storm:
		if StaminaManager:
			StaminaManager.spend(STORM_STAMINA_COST)
			stamina_lost = STORM_STAMINA_COST
	
	if crops_watered > 0 or stamina_lost > 0:
		weather_depth_applied.emit(_current_weather, crops_watered, stamina_lost)

func to_save_dict() -> Dictionary:
	return {"weather": _current_weather, "is_storm": _is_storm}

func from_save_dict(data: Dictionary) -> void:
	_current_weather = data.get("weather", SUNNY)
	_is_storm = data.get("is_storm", false)
