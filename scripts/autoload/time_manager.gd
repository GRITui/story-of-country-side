extends Node
## Autoload: TimeManager
##
## Owns the day/time clock (ENG-12): a 6:00 AM - 2:00 AM in-game day that
## auto-advances unless frozen (menus, cutscenes, festivals). Single-client
## clock only per Decision D (single-player v1, no server-authority layer).

signal minute_passed(hour: int, minute: int)
signal day_started(day_in_season: int, season: String, day_of_week: String)
signal day_ended(day_in_season: int, season: String)

const SEASONS: Array[String] = ["Spring", "Summer", "Fall", "Winter"]
const DAYS_PER_SEASON := 28
const DAY_START_HOUR := 6
const DAY_END_HOUR := 2 ## day rolls over at 2:00 AM, then resets to DAY_START_HOUR
const MINUTES_PER_REAL_SECOND := 7.0 ## tuning constant, not final balance
const DAYS_OF_WEEK: Array[String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

var year: int = 1
var season_index: int = 0
var day_in_season: int = 1
var hour: int = DAY_START_HOUR
var minute: int = 0

var _freeze_reasons: Array[String] = []
var _minute_accum: float = 0.0

func _process(delta: float) -> void:
	if is_frozen():
		return
	_minute_accum += delta * MINUTES_PER_REAL_SECOND
	while _minute_accum >= 1.0:
		_minute_accum -= 1.0
		_advance_minute()

func _advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour = (hour + 1) % 24
	minute_passed.emit(hour, minute)
	if hour == DAY_END_HOUR and minute == 0:
		_end_day()

func _end_day() -> void:
	day_ended.emit(day_in_season, current_season())
	_advance_day()
	hour = DAY_START_HOUR
	minute = 0
	day_started.emit(day_in_season, current_season(), current_day_of_week())

## Public API: advance to the next day immediately (sleep / day-skip).
func advance_day() -> void:
	day_ended.emit(day_in_season, current_season())
	_advance_day()
	hour = DAY_START_HOUR
	minute = 0
	day_started.emit(day_in_season, current_season(), current_day_of_week())

func _advance_day() -> void:
	day_in_season += 1
	if day_in_season > DAYS_PER_SEASON:
		day_in_season = 1
		season_index += 1
		if season_index >= SEASONS.size():
			season_index = 0
			year += 1

func current_season() -> String:
	return SEASONS[season_index]

func current_day_of_week() -> String:
	var absolute_day := (year - 1) * DAYS_PER_SEASON * SEASONS.size() \
		+ season_index * DAYS_PER_SEASON + (day_in_season - 1)
	return DAYS_OF_WEEK[absolute_day % 7]

## Freeze is reference-counted by reason so menus, cutscenes, and festivals
## (each their own reason string) can overlap without one unfreezing early.
func freeze(reason: String) -> void:
	if not _freeze_reasons.has(reason):
		_freeze_reasons.append(reason)

func unfreeze(reason: String) -> void:
	_freeze_reasons.erase(reason)

func is_frozen() -> bool:
	return not _freeze_reasons.is_empty()

## Squad Alpha (P0 #93): sleep / day-skip.
## can_sleep() is the public gate — sleeping is only allowed when the
## clock is not frozen (menus, festivals, cutscenes). sleep() and
## sleep_until_morning() both respect this gate and return false if frozen.
## When allowed, they force a single clean day rollover: emit day_ended,
## reuse _advance_day() for season/year arithmetic, reset hour/minute to
## 6:00 AM, clear _minute_accum, emit day_started. Stamina restore happens
## reactively via StaminaManager's day_started listener (no direct
## StaminaManager field access here — SQUAD-SPLIT contract).
## Reference-counted freeze does not block the forced rollover once
## can_sleep() has passed — sleep bypasses _process()'s early return and
## drives the transition directly.
func can_sleep() -> bool:
	return not is_frozen()

func sleep() -> bool:
	return sleep_until_morning()

func sleep_until_morning() -> bool:
	if not can_sleep():
		return false
	_minute_accum = 0.0
	day_ended.emit(day_in_season, current_season())
	_advance_day()
	hour = DAY_START_HOUR
	minute = 0
	day_started.emit(day_in_season, current_season(), current_day_of_week())
	return true

func to_save_dict() -> Dictionary:
	return {
		"year": year,
		"season_index": season_index,
		"day_in_season": day_in_season,
		"hour": hour,
		"minute": minute,
	}

func from_save_dict(data: Dictionary) -> void:
	year = data.get("year", 1)
	season_index = data.get("season_index", 0)
	day_in_season = data.get("day_in_season", 1)
	hour = data.get("hour", DAY_START_HOUR)
	minute = data.get("minute", 0)
