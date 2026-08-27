extends Node
## Autoload: WeatherManager — S-Tier P2 (Epsilon)
##
## Depth pass per #112: deterministic seed for tests, storm flag,
## is_raining_today(), get_weather_for_date(), rain waters crops.
##
## Rolls one weather value per in-game day. Previously used global randf(),
## now owns a RandomNumberGenerator so tests can call set_weather_seed()
## for deterministic rolls while keeping the same weighted distribution:
## mostly Sunny, occasional Rainy/Snowy, rare Storm (1/20).
##
## Rain watering: when the rolled weather is Rainy/Snowy/Storm, every
## active FarmPlot is watered via FarmPlotManager.water() at day start.
## This is gameplay-affecting (crops advance without manual watering) and
## matches #112's acceptance: "rain waters crops".
##
## Storm is a rare texture flag (1/20 chance, independent roll) that
## consumers (HUD/FX) can read via is_storm_today(). It piggybacks on
## rainy/snowy weather rather than replacing the Sunny weight.

signal weather_changed(weather: String)

const SUNNY := "Sunny"
const RAINY := "Rainy"
const SNOWY := "Snowy"
const STORM := "Storm"

## Winter swaps Rainy for Snowy; every other season rolls Sunny/Rainy.
const SUNNY_WEIGHT := 0.7
## 1 in 20 days is a storm texture variant.
const STORM_CHANCE := 0.05

var _current_weather: String = SUNNY
var _is_storm: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
	_roll_weather(TimeManager.current_season() if TimeManager else "Spring")

# ------------------------------------------------------------------ #
# Deterministic seed control (tests)                                   #
# ------------------------------------------------------------------ #

func set_weather_seed(seed: int) -> void:
	_rng.seed = seed

func get_weather_seed() -> int:
	return int(_rng.seed)

# ------------------------------------------------------------------ #
# Public getters                                                       #
# ------------------------------------------------------------------ #

func get_current_weather() -> String:
	return _current_weather

func is_raining_today() -> bool:
	return _current_weather in [RAINY, SNOWY, STORM]

func is_storm_today() -> bool:
	return _is_storm

func is_snowy_today() -> bool:
	return _current_weather == SNOWY

## Pure/deterministic query: what *would* the weather be for a given
## season+day without mutating live state. Uses a throwaway RNG seeded
## from the date + the manager's current seed so tests get stable
## results while still varying across dates.
## Optional `seed_override` lets tests pin the base seed explicitly.
## Returns only Sunny/Rainy/Snowy (never Storm) so existing contracts
## stay stable; storm is a texture flag exposed via
## get_weather_details_for_date().
func get_weather_for_date(season: String, day_of_season: int, seed_override: int = -1) -> String:
	var details := get_weather_details_for_date(season, day_of_season, seed_override)
	return details["weather"]

## Extended query that also reports whether the date would be a storm
## day. Returning a dictionary keeps the common single-value getter
## simple while still exposing the texture flag for deterministic tests.
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

# ------------------------------------------------------------------ #
# Day lifecycle                                                        #
# ------------------------------------------------------------------ #

func _on_day_started(_day_in_season: int, season: String, _day_of_week: String) -> void:
	_roll_weather(season)
	if is_raining_today():
		_water_all_plots()

func _roll_weather(season: String) -> void:
	# Storm is a texture flag; weather stays Sunny/Rainy/Snowy so existing
	# contracts (tests, NPC schedule gating) remain stable.
	var storm_roll := _rng.randf()
	var will_be_storm := storm_roll < STORM_CHANCE

	var rainy_alt := SNOWY if season == "Winter" else RAINY
	var new_weather := SUNNY if _rng.randf() < SUNNY_WEIGHT else rainy_alt
	var new_is_storm := will_be_storm and new_weather != SUNNY

	if new_weather == _current_weather:
		# Still update storm flag silently; only weather string drives
		# weather_changed (preserves existing test invariant).
		_is_storm = new_is_storm
		return
	_current_weather = new_weather
	_is_storm = new_is_storm
	weather_changed.emit(_current_weather)

func _water_all_plots() -> void:
	if FarmPlotManager == null:
		return
	# FarmPlotManager is autoload; guard for headless ordering during boot.
	var positions: Array = FarmPlotManager.get_all_positions()
	for pos in positions:
		# water() is idempotent per day (rejects already-watered),
		# so calling blindly is safe.
		FarmPlotManager.water(pos)

# ------------------------------------------------------------------ #
# Persistence                                                          #
# ------------------------------------------------------------------ #

func to_save_dict() -> Dictionary:
	return {
		"current_weather": _current_weather,
		"is_storm": _is_storm,
		"rng_seed": int(_rng.seed),
	}

func from_save_dict(data: Dictionary) -> void:
	_current_weather = data.get("current_weather", SUNNY)
	_is_storm = data.get("is_storm", false)
	if data.has("rng_seed"):
		_rng.seed = int(data["rng_seed"])
