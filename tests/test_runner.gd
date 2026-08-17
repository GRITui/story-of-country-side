extends Node
## Headless test runner for ENG-12 (Time & Stamina foundation).
##
## Run as its own scene (not via --script) so the engine's normal startup
## registers TimeManager/StaminaManager/SaveManager as autoloads first:
##   godot --headless --path . tests/TestRunner.tscn
##
## No test framework dependency — plain assertions, since this is a small,
## fixed suite for two autoload singletons, not a growing test surface yet.

var _failures: Array[String] = []
var _pass_count := 0
var _pass_out_fire_count := 0 ## member, not a local — GDScript lambdas capture locals by value

func _ready() -> void:
	_test_minute_and_hour_wrap()
	_test_day_rollover_resets_clock()
	_test_season_and_year_rollover()
	_test_freeze_is_reason_counted()
	_test_stamina_spend_and_clamp()
	_test_pass_out_signal_fires_once()
	_test_pass_out_reduces_next_day_stamina()
	_test_normal_day_restores_full_stamina()
	_test_save_round_trip()

	if _failures.is_empty():
		print("ALL TESTS PASSED (%d checks)" % _pass_count)
		get_tree().quit(0)
	else:
		for f in _failures:
			printerr("FAIL: %s" % f)
		printerr("%d/%d check(s) failed" % [_failures.size(), _pass_count + _failures.size()])
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_failures.append(message)

func _test_minute_and_hour_wrap() -> void:
	var tm := TimeManager
	tm.hour = 23
	tm.minute = 59
	tm._advance_minute()
	_check(tm.hour == 0 and tm.minute == 0, "minute/hour should wrap 23:59 -> 00:00")

func _test_day_rollover_resets_clock() -> void:
	var tm := TimeManager
	tm.year = 1
	tm.season_index = 0
	tm.day_in_season = 5
	tm.hour = 1
	tm.minute = 59
	tm._advance_minute() # -> 02:00, triggers _end_day()
	_check(tm.hour == TimeManager.DAY_START_HOUR and tm.minute == 0,
		"day rollover should reset clock to %02d:00, got %02d:%02d" % [TimeManager.DAY_START_HOUR, tm.hour, tm.minute])
	_check(tm.day_in_season == 6, "day_in_season should increment on rollover, got %d" % tm.day_in_season)

func _test_season_and_year_rollover() -> void:
	var tm := TimeManager
	tm.year = 1
	tm.season_index = 3 # Winter
	tm.day_in_season = TimeManager.DAYS_PER_SEASON
	tm.hour = 1
	tm.minute = 59
	tm._advance_minute()
	_check(tm.season_index == 0, "season should wrap Winter -> Spring, got index %d" % tm.season_index)
	_check(tm.day_in_season == 1, "day_in_season should reset to 1 on season wrap, got %d" % tm.day_in_season)
	_check(tm.year == 2, "year should increment on season wrap-around, got %d" % tm.year)

func _test_freeze_is_reason_counted() -> void:
	var tm := TimeManager
	tm.freeze("menu")
	tm.freeze("festival")
	_check(tm.is_frozen(), "should be frozen with two active reasons")
	tm.unfreeze("menu")
	_check(tm.is_frozen(), "should stay frozen while 'festival' reason is still active")
	tm.unfreeze("festival")
	_check(not tm.is_frozen(), "should unfreeze once all reasons are cleared")

func _test_stamina_spend_and_clamp() -> void:
	var sm := StaminaManager
	sm.max_stamina = 100
	sm.current_stamina = 100
	sm._passed_out_today = false
	sm.spend(30)
	_check(sm.current_stamina == 70, "spend(30) from 100 should leave 70, got %d" % sm.current_stamina)
	sm.spend(1000)
	_check(sm.current_stamina == 0, "spend should clamp at 0, got %d" % sm.current_stamina)
	sm.restore(1000)
	_check(sm.current_stamina == 100, "restore should clamp at max_stamina, got %d" % sm.current_stamina)

func _on_passed_out_for_test(_penalty: int) -> void:
	_pass_out_fire_count += 1

func _test_pass_out_signal_fires_once() -> void:
	var sm := StaminaManager
	sm.max_stamina = 100
	sm.current_stamina = 10
	sm._passed_out_today = false
	_pass_out_fire_count = 0
	sm.passed_out.connect(_on_passed_out_for_test)
	sm.spend(10) # hits 0 -> should pass out once
	sm.spend(0)  # no-op, must not re-trigger
	sm.passed_out.disconnect(_on_passed_out_for_test)
	_check(_pass_out_fire_count == 1, "passed_out should fire exactly once per pass-out, fired %d times" % _pass_out_fire_count)
	_check(sm._passed_out_today, "_passed_out_today should be true after passing out")

func _test_pass_out_reduces_next_day_stamina() -> void:
	var sm := StaminaManager
	sm.max_stamina = 100
	sm.current_stamina = 0
	sm._passed_out_today = true
	sm._on_day_started(1, "Spring", "Mon")
	_check(sm.current_stamina == 50, "day after pass-out should start at 50%% max stamina, got %d" % sm.current_stamina)
	_check(not sm._passed_out_today, "_passed_out_today should reset after the penalty is applied")

func _test_normal_day_restores_full_stamina() -> void:
	var sm := StaminaManager
	sm.max_stamina = 100
	sm.current_stamina = 40
	sm._passed_out_today = false
	sm._on_day_started(2, "Spring", "Tue")
	_check(sm.current_stamina == 100, "normal day (no pass-out) should restore full stamina, got %d" % sm.current_stamina)

func _test_save_round_trip() -> void:
	var tm := TimeManager
	var sm := StaminaManager
	tm.year = 3
	tm.season_index = 2
	tm.day_in_season = 14
	tm.hour = 18
	tm.minute = 30
	sm.max_stamina = 120
	sm.current_stamina = 45
	sm._passed_out_today = true

	var saved := SaveManager.build_save_data()

	tm.year = 1
	tm.season_index = 0
	tm.day_in_season = 1
	tm.hour = TimeManager.DAY_START_HOUR
	tm.minute = 0
	sm.max_stamina = StaminaManager.MAX_STAMINA_DEFAULT
	sm.current_stamina = StaminaManager.MAX_STAMINA_DEFAULT
	sm._passed_out_today = false

	SaveManager.apply_save_data(saved)

	_check(tm.year == 3 and tm.season_index == 2 and tm.day_in_season == 14 \
		and tm.hour == 18 and tm.minute == 30, "TimeManager state should round-trip through save/load")
	_check(sm.max_stamina == 120 and sm.current_stamina == 45 and sm._passed_out_today == true,
		"StaminaManager state should round-trip through save/load")
