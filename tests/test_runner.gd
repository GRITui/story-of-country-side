extends Node
## Headless test runner for the Engineer-Squad epics landed so far:
## ENG-12 (Time & Stamina foundation), ENG-18 (NPC Routines),
## ENG-19 (Relationship System).
##
## Run as its own scene (not via --script) so the engine's normal startup
## registers TimeManager/StaminaManager/SaveManager as autoloads first:
##   godot --headless --path . tests/TestRunner.tscn
##
## No test framework dependency — plain assertions. Worth switching to a
## real framework (GUT) once this file covers more than two or three
## systems; still small enough that the overhead isn't worth it yet.

var _failures: Array[String] = []
var _pass_count := 0
var _pass_out_fire_count := 0 ## member, not a local — GDScript lambdas capture locals by value
var _arrived_fire_count := 0 ## same reason
var _heart_events: Array = [] ## Array[Array] of [npc_name, heart_level], same reason

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

	_test_schedule_picks_current_entry()
	_test_schedule_wraps_to_previous_day_entry()
	_test_schedule_season_override_beats_any()
	_test_schedule_empty_for_no_matching_entries()
	_test_controller_walks_toward_target_and_arrives()
	_test_controller_pauses_while_time_frozen()
	_test_controller_retargets_on_schedule_change()

	_test_talk_awards_points_once_per_day()
	_test_gift_applies_preference_deltas()
	_test_gift_once_per_day()
	_test_points_clamp_between_zero_and_max()
	_test_heart_event_fires_once_per_threshold_crossed()
	_test_heart_event_handles_multi_threshold_jump()
	_test_relationship_save_round_trip()

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

## --- ENG-18: NPC Routines ---

func _on_arrived_for_test(_location_name: String) -> void:
	_arrived_fire_count += 1

func _make_entry(hour: int, minute: int, pos: Vector2, location: String, season: String = "Any") -> NPCScheduleEntry:
	var e := NPCScheduleEntry.new()
	e.hour = hour
	e.minute = minute
	e.position = pos
	e.location_name = location
	e.season = season
	return e

func _make_test_schedule() -> NPCSchedule:
	var s := NPCSchedule.new()
	s.entries = [
		_make_entry(6, 0, Vector2(0, 0), "home"),
		_make_entry(9, 0, Vector2(100, 0), "shop"),
		_make_entry(17, 0, Vector2(200, 0), "tavern"),
		_make_entry(22, 0, Vector2(0, 0), "home"),
	]
	return s

func _test_schedule_picks_current_entry() -> void:
	var s := _make_test_schedule()
	var e := s.get_target_for(10, 30, "Spring")
	_check(e != null and e.location_name == "shop", "10:30 should pick the 09:00 'shop' entry, got %s" % (e.location_name if e else "null"))

	e = s.get_target_for(17, 0, "Spring")
	_check(e != null and e.location_name == "tavern", "exact match at 17:00 should pick 'tavern', got %s" % (e.location_name if e else "null"))

func _test_schedule_wraps_to_previous_day_entry() -> void:
	var s := _make_test_schedule()
	var e := s.get_target_for(3, 0, "Spring") # before the 06:00 entry -> holds overnight position
	_check(e != null and e.location_name == "home", "03:00 (before first entry) should wrap to the last entry ('home' at 22:00), got %s" % (e.location_name if e else "null"))

func _test_schedule_season_override_beats_any() -> void:
	var s := NPCSchedule.new()
	s.entries = [
		_make_entry(6, 0, Vector2(0, 0), "home", "Any"),
		_make_entry(6, 0, Vector2(50, 50), "storm-shelter", "Winter"),
	]
	var winter_entry := s.get_target_for(6, 0, "Winter")
	_check(winter_entry != null and winter_entry.location_name == "storm-shelter",
		"Winter-specific entry should be findable at the same time slot as an 'Any' entry")

	var spring_entries := s.entries.filter(func(e: NPCScheduleEntry) -> bool: return e.matches("Spring", "Any"))
	_check(spring_entries.size() == 1 and spring_entries[0].location_name == "home",
		"Winter-only entry should not match Spring lookups")

func _test_schedule_empty_for_no_matching_entries() -> void:
	var s := NPCSchedule.new()
	s.entries = [_make_entry(6, 0, Vector2.ZERO, "home", "Winter")]
	var e := s.get_target_for(6, 0, "Summer")
	_check(e == null, "no Winter-only entries should match a Summer lookup")

func _test_controller_walks_toward_target_and_arrives() -> void:
	var npc := NPCController.new()
	npc.schedule = _make_test_schedule()
	npc.move_speed_px_per_sec = 1000.0 # fast, so a handful of frames covers the distance
	add_child(npc)

	_arrived_fire_count = 0
	npc.arrived_at.connect(_on_arrived_for_test)

	npc._refresh_target(TimeManager.hour, TimeManager.minute) # picks up whatever the clock is at
	# Force a known target regardless of the shared TimeManager's current state.
	npc._current_target = npc.schedule.entries[1] # "shop" at (100, 0)
	npc._was_at_target = false
	npc.position = Vector2.ZERO

	for i in range(200):
		npc._process(0.1)

	_check(npc.is_at_target(), "NPC should reach its target after enough frames, ended at %s (target %s)" % [npc.position, npc._current_target.position])
	_check(_arrived_fire_count >= 1, "arrived_at should fire once the NPC reaches its target")

	npc.queue_free()

func _test_controller_pauses_while_time_frozen() -> void:
	var npc := NPCController.new()
	npc.schedule = _make_test_schedule()
	npc.move_speed_px_per_sec = 1000.0
	add_child(npc)

	npc._current_target = npc.schedule.entries[1] # (100, 0)
	npc.position = Vector2.ZERO

	TimeManager.freeze("test-pause")
	npc._process(1.0) # would easily cover the distance if not frozen
	var moved := npc.position != Vector2.ZERO
	TimeManager.unfreeze("test-pause")

	_check(not moved, "NPC should not move at all while TimeManager is frozen, position was %s" % npc.position)
	npc.queue_free()

func _test_controller_retargets_on_schedule_change() -> void:
	var npc := NPCController.new()
	npc.schedule = _make_test_schedule()
	add_child(npc)

	npc._refresh_target(8, 0)
	var target_before := npc._current_target
	npc._refresh_target(9, 0)
	var target_after := npc._current_target

	_check(target_before != null and target_before.location_name == "home", "08:00 should still target 'home' (before the 09:00 shop entry)")
	_check(target_after != null and target_after.location_name == "shop", "09:00 should retarget to 'shop'")
	_check(target_before != target_after, "retargeting should replace the entry reference, not just mutate in place")

	npc.queue_free()

## --- ENG-19: Relationship System ---

func _reset_relationship_manager() -> void:
	var rm := RelationshipManager
	rm._points = {}
	rm._highest_triggered_heart = {}
	rm._talked_today = {}
	rm._gifted_today = {}

func _make_gift_table() -> GiftPreferenceTable:
	var t := GiftPreferenceTable.new()
	t.loved_items = ["apple_pie"]
	t.liked_items = ["egg"]
	t.disliked_items = ["quartz"]
	t.hated_items = ["trash"]
	return t

func _on_heart_event_for_test(npc_name: String, heart_level: int) -> void:
	_heart_events.append([npc_name, heart_level])

func _test_talk_awards_points_once_per_day() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	var accepted := rm.talk_to("Elena")
	_check(accepted, "first talk_to() today should be accepted")
	_check(rm.get_points("Elena") == RelationshipManager.TALK_POINTS,
		"talking once should award TALK_POINTS, got %d" % rm.get_points("Elena"))

	var accepted_again := rm.talk_to("Elena")
	_check(not accepted_again, "second talk_to() the same day should be rejected")
	_check(rm.get_points("Elena") == RelationshipManager.TALK_POINTS,
		"a rejected same-day talk should not add more points, got %d" % rm.get_points("Elena"))

	rm._on_day_started(1, "Spring", "Mon")
	var accepted_next_day := rm.talk_to("Elena")
	_check(accepted_next_day, "talk_to() should be accepted again after a day rollover")
	_check(rm.get_points("Elena") == RelationshipManager.TALK_POINTS * 2,
		"a second day's talk should add another TALK_POINTS, got %d" % rm.get_points("Elena"))

func _test_gift_applies_preference_deltas() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	var table := _make_gift_table()

	rm.give_gift("Elena", "apple_pie", table)
	_check(rm.get_points("Elena") == 80, "a loved gift should add 80 points, got %d" % rm.get_points("Elena"))

	rm.give_gift("Marcus", "quartz", table)
	_check(rm.get_points("Marcus") == 0,
		"a disliked gift (-20) from 0 points should clamp at 0, got %d" % rm.get_points("Marcus"))

func _test_gift_once_per_day() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	var table := _make_gift_table()

	var first := rm.give_gift("Elena", "egg", table)
	_check(first, "first gift today should be accepted")
	var second := rm.give_gift("Elena", "apple_pie", table)
	_check(not second, "a second gift the same day should be rejected")
	_check(rm.get_points("Elena") == 45,
		"a rejected second gift should not add its points, got %d" % rm.get_points("Elena"))

func _test_points_clamp_between_zero_and_max() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	rm._add_points("Elena", -1000)
	_check(rm.get_points("Elena") == 0, "points should clamp at 0, got %d" % rm.get_points("Elena"))
	rm._add_points("Elena", 1000000)
	_check(rm.get_points("Elena") == RelationshipManager.MAX_POINTS,
		"points should clamp at MAX_POINTS, got %d" % rm.get_points("Elena"))

func _test_heart_event_fires_once_per_threshold_crossed() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	_heart_events = []
	rm.heart_event_triggered.connect(_on_heart_event_for_test)

	rm._add_points("Elena", RelationshipManager.POINTS_PER_HEART) # exactly 1 heart
	_check(_heart_events.size() == 1 and _heart_events[0] == ["Elena", 1],
		"crossing into heart 1 should fire exactly once, got %s" % [_heart_events])

	rm._add_points("Elena", 10) # still within heart 1, no new crossing
	_check(_heart_events.size() == 1,
		"points that don't cross a new heart threshold should not re-fire, got %d events" % _heart_events.size())

	rm.heart_event_triggered.disconnect(_on_heart_event_for_test)

func _test_heart_event_handles_multi_threshold_jump() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	_heart_events = []
	rm.heart_event_triggered.connect(_on_heart_event_for_test)

	rm._add_points("Marcus", RelationshipManager.POINTS_PER_HEART * 3) # jump straight to 3 hearts
	_check(_heart_events.size() == 3, "a multi-heart jump should fire once per crossed heart, got %d" % _heart_events.size())
	_check(_heart_events[0] == ["Marcus", 1] and _heart_events[1] == ["Marcus", 2] and _heart_events[2] == ["Marcus", 3],
		"multi-heart jump should fire hearts in order 1,2,3, got %s" % [_heart_events])

	rm.heart_event_triggered.disconnect(_on_heart_event_for_test)

func _test_relationship_save_round_trip() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager
	rm._add_points("Elena", 500)
	rm.talk_to("Elena")
	rm.give_gift("Marcus", "trash", _make_gift_table())

	var saved := SaveManager.build_save_data()

	_reset_relationship_manager()
	_check(rm.get_points("Elena") == 0, "sanity check: reset should clear points before applying save data")

	SaveManager.apply_save_data(saved)

	_check(rm.get_points("Elena") == 520,
		"RelationshipManager points should round-trip through save/load, got %d" % rm.get_points("Elena"))
	_check(rm.get_hearts("Elena") == 2, "hearts should be derivable from restored points, got %d" % rm.get_hearts("Elena"))
	_check(rm.get_points("Marcus") == 0,
		"Marcus's hated-gift points should round-trip clamped at 0 (started at 0, -40 delta), got %d" % rm.get_points("Marcus"))
	_check(not rm.has_talked_today("Elena"),
		"daily talk/gift flags should NOT round-trip through save/load — they're day-scoped, not save-scoped")
