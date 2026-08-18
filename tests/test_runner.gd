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
var _payout_fire_count := 0 ## same reason
var _payout_last_total := -1
var _payout_last_count := -1
var _quest_completed_events: Array = [] ## Array[Array] of [quest_id, unlock_flag], same reason
var _ore_added_events: Array = [] ## Array[Array] of [item_id, quantity, total], same reason
var _tool_upgraded_events: Array = [] ## Array[Array] of [tool_name, new_tier], same reason
var _xp_gained_events: Array = [] ## Array[Array] of [skill_name, amount, total_xp], same reason
var _level_changed_events: Array = [] ## Array[Array] of [skill_name, new_level, old_level], same reason
var _heart_events: Array = [] ## Array[Array] of [npc_name, heart_level], same reason
var _item_changed_events: Array = [] ## Array[Array] of [item_id, delta, total], same reason
var _crop_planted_events: Array = [] ## Array[Array] of [position, crop_id], same reason
var _crop_watered_events: Array = [] ## Array[Vector2i], same reason
var _crop_harvested_events: Array = [] ## Array[Array] of [position, item_id, quality, quantity], same reason
var _crop_withered_events: Array = [] ## Array[Array] of [position, crop_id], same reason
var _forage_gathered_events: Array = [] ## Array[Array] of [position, item_id, quantity], same reason
var _forage_rerolled_events: Array = [] ## Array[Array] of [position, item_id], same reason
var _intro_finished_count := 0 ## member, not a local — GDScript lambdas capture locals by value

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

	_test_ship_item_does_not_pay_out_immediately()
	_test_day_rollover_pays_out_and_clears_bin()
	_test_different_items_and_prices_sum_correctly()
	_test_no_payout_signal_when_bin_empty()
	_test_pass_out_penalty_deducts_gold_and_clamps_at_zero()
	_test_spend_succeeds_and_fails_correctly()
	_test_shipping_bin_save_round_trip()

	_test_deliver_item_quest_completes_at_target()
	_test_deliver_item_quest_ignores_other_items()
	_test_deliver_item_quest_does_not_re_fire_after_completion()
	_test_friendship_quest_completes_at_target_hearts()
	_test_reregistering_quest_preserves_completion_state()
	_test_evaluate_skill_level_completes_matching_quest()
	_test_quest_save_round_trip()

	_test_add_xp_accumulates_and_emits()
	_test_level_thresholds_match_cumulative_curve()
	_test_level_changed_fires_once_per_level_on_single_step()
	_test_level_changed_fires_for_each_crossed_level_on_big_jump()
	_test_add_xp_non_positive_is_noop()
	_test_level_up_drives_quest_skill_level_condition()
	_test_skill_save_round_trip()

	_test_new_tool_starts_at_copper_defaults()
	_test_add_ore_accumulates_and_emits()
	_test_cannot_upgrade_without_enough_ore()
	_test_cannot_upgrade_without_enough_gold()
	_test_failed_gold_spend_does_not_consume_ore()
	_test_successful_upgrade_deducts_costs_and_advances_tier()
	_test_tools_upgrade_independently()
	_test_cannot_upgrade_past_gold_tier()
	_test_tool_save_round_trip()

	_test_inventory_add_and_remove()
	_test_inventory_remove_fails_when_insufficient()
	_test_inventory_has_item()
	_test_inventory_sell_item_ships_and_removes()
	_test_inventory_sell_item_fails_without_removing_on_short_stock()
	_test_inventory_save_round_trip()

	_test_cannot_plant_wrong_season()
	_test_plant_and_water_and_growth_progresses_on_watered_days()
	_test_growth_does_not_progress_on_unwatered_days()
	_test_watered_today_resets_each_day()
	_test_cannot_water_twice_same_day()
	_test_harvest_credits_inventory_and_xp_and_clears_plot()
	_test_regrowable_crop_resets_instead_of_clearing()
	_test_forced_quality_skips_random_roll()
	_test_item_id_encodes_quality()
	_test_sell_price_applies_quality_multiplier()
	_test_crop_withers_when_season_ends_unharvested()
	_test_farm_plot_save_round_trip()

	_test_forage_register_node_seeds_season_valid_item()
	_test_forage_gather_credits_inventory_and_xp_and_sets_cooldown()
	_test_forage_gather_fails_when_unavailable()
	_test_forage_cooldown_counts_down_and_becomes_available_again()
	_test_forage_node_rerolls_when_season_ends()
	_test_forage_node_goes_dormant_with_no_season_valid_content()
	_test_forage_save_round_trip()

	_test_new_game_resets_state_to_defaults()
	_test_new_game_grants_starting_gold_and_copper_tools()
	_test_save_and_load_round_trip_persists_intro_seen()
	_test_load_game_returns_false_without_save_file()
	_test_intro_sequence_advances_through_lines_then_finishes()
	_test_intro_sequence_freezes_and_unfreezes_time_manager()

	_test_add_animal_requires_registered_species()
	_test_add_animal_rejects_duplicate_id()
	_test_feed_once_per_day()
	_test_brush_once_per_day()
	_test_product_progresses_only_on_fed_days()
	_test_neglect_reduces_happiness_no_progress()
	_test_collect_product_credits_inventory_and_xp()
	_test_collect_product_before_ready_returns_empty()
	_test_quality_tier_follows_happiness()
	_test_multi_day_producer_needs_multiple_fed_days()
	_test_animal_save_round_trip()

	_test_available_fish_filters_by_location_season_hour()
	_test_available_fish_sorted_and_ignores_unregistered()
	_test_attempt_catch_unregistered_fish_returns_empty()
	_test_attempt_catch_below_difficulty_escapes()
	_test_attempt_catch_success_credits_inventory_and_xp()
	_test_catch_quality_tiers_follow_performance()
	_test_item_id_encodes_quality_for_normal_catch()
	_test_sell_price_applies_quality_multiplier_for_fish()

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

## --- ENG-22: Shipping Bin economy ---

func _on_payout_for_test(total_earned: int, item_count: int) -> void:
	_payout_fire_count += 1
	_payout_last_total = total_earned
	_payout_last_count = item_count

func _reset_shipping_bin() -> void:
	var sb := ShippingBinManager
	sb.gold = 0
	sb._pending_shipments = []

func _test_ship_item_does_not_pay_out_immediately() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.ship_item("turnip", 5, 10)
	_check(sb.gold == 0, "shipping an item should not add gold until day rollover, gold=%d" % sb.gold)
	_check(sb.pending_item_count() == 5, "pending_item_count should reflect shipped quantity, got %d" % sb.pending_item_count())

func _test_day_rollover_pays_out_and_clears_bin() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.ship_item("turnip", 5, 10) # 50
	sb.ship_item("egg", 3, 20)    # 60
	_payout_fire_count = 0
	_payout_last_total = -1
	_payout_last_count = -1
	sb.payout_processed.connect(_on_payout_for_test)
	sb._on_day_started(1, "Spring", "Mon")
	sb.payout_processed.disconnect(_on_payout_for_test)

	_check(sb.gold == 110, "day rollover should pay out the sum of shipments, got gold=%d" % sb.gold)
	_check(sb._pending_shipments.is_empty(), "bin should clear after payout, still has %d entries" % sb._pending_shipments.size())
	_check(_payout_fire_count == 1, "payout_processed should fire exactly once, fired %d times" % _payout_fire_count)
	_check(_payout_last_total == 110 and _payout_last_count == 8,
		"payout_processed should report total=110/count=8, got total=%d count=%d" % [_payout_last_total, _payout_last_count])

func _test_different_items_and_prices_sum_correctly() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.ship_item("turnip", 2, 10) # normal-quality turnip: 20
	sb.ship_item("turnip", 1, 20) # gold-quality turnip, same item_id, different price: 20
	sb._on_day_started(1, "Spring", "Mon")
	_check(sb.gold == 40, "same item_id at two different quality-tier prices should sum, not average or collapse, got %d" % sb.gold)

func _test_no_payout_signal_when_bin_empty() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.gold = 100
	_payout_fire_count = 0
	sb.payout_processed.connect(_on_payout_for_test)
	sb._on_day_started(2, "Spring", "Tue")
	sb.payout_processed.disconnect(_on_payout_for_test)
	_check(_payout_fire_count == 0, "an empty bin should not emit payout_processed, fired %d times" % _payout_fire_count)
	_check(sb.gold == 100, "gold should be unchanged when there's nothing to pay out, got %d" % sb.gold)

func _test_pass_out_penalty_deducts_gold_and_clamps_at_zero() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.gold = 30
	sb._on_passed_out(100)
	_check(sb.gold == 0, "pass-out penalty larger than current gold should clamp at 0, got %d" % sb.gold)

	sb.gold = 200
	sb._on_passed_out(50)
	_check(sb.gold == 150, "pass-out penalty should deduct normally when gold is sufficient, got %d" % sb.gold)

func _test_spend_succeeds_and_fails_correctly() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.gold = 100

	var ok := sb.spend(40)
	_check(ok and sb.gold == 60, "spend(40) from 100 should succeed leaving 60, got ok=%s gold=%d" % [ok, sb.gold])

	var ok2 := sb.spend(1000)
	_check(not ok2 and sb.gold == 60, "spending more than available should fail and leave gold unchanged, got ok=%s gold=%d" % [ok2, sb.gold])

	var ok3 := sb.spend(-5)
	_check(not ok3, "spending a non-positive amount should fail")

func _test_shipping_bin_save_round_trip() -> void:
	_reset_shipping_bin()
	var sb := ShippingBinManager
	sb.gold = 250
	sb.ship_item("wool", 4, 15)

	var saved := SaveManager.build_save_data()

	sb.gold = 0
	sb._pending_shipments = []

	SaveManager.apply_save_data(saved)

	_check(sb.gold == 250, "gold should round-trip through save/load, got %d" % sb.gold)
	_check(sb._pending_shipments.size() == 1
		and sb._pending_shipments[0]["item_id"] == "wool"
		and sb._pending_shipments[0]["quantity"] == 4
		and sb._pending_shipments[0]["unit_price"] == 15,
		"pending shipments should round-trip through save/load, got %s" % [sb._pending_shipments])

## --- ENG-31: Quest system foundation ---

func _reset_quest_manager() -> void:
	var qm := QuestManager
	qm._quests = {}
	qm._completed = {}
	qm._delivered_totals = {}
	qm._unlocked_flags = {}

func _reset_relationship_manager_for_quests() -> void:
	var rm := RelationshipManager
	rm._points = {}
	rm._highest_triggered_heart = {}
	rm._talked_today = {}
	rm._gifted_today = {}

func _make_deliver_quest(id: String, item_id: String, qty: int, flag: String) -> QuestDefinition:
	var cond := QuestCondition.new()
	cond.type = QuestCondition.ConditionType.DELIVER_ITEM
	cond.item_id = item_id
	cond.target_quantity = qty
	var q := QuestDefinition.new()
	q.quest_id = id
	q.condition = cond
	q.unlock_flag = flag
	return q

func _make_friendship_quest(id: String, npc: String, hearts: int, flag: String) -> QuestDefinition:
	var cond := QuestCondition.new()
	cond.type = QuestCondition.ConditionType.FRIENDSHIP_LEVEL
	cond.npc_name = npc
	cond.target_hearts = hearts
	var q := QuestDefinition.new()
	q.quest_id = id
	q.condition = cond
	q.unlock_flag = flag
	return q

func _make_skill_quest(id: String, skill: String, level: int, flag: String) -> QuestDefinition:
	var cond := QuestCondition.new()
	cond.type = QuestCondition.ConditionType.SKILL_LEVEL
	cond.skill_name = skill
	cond.target_level = level
	var q := QuestDefinition.new()
	q.quest_id = id
	q.condition = cond
	q.unlock_flag = flag
	return q

func _on_quest_completed_for_test(quest_id: String, unlock_flag: String) -> void:
	_quest_completed_events.append([quest_id, unlock_flag])

func _test_deliver_item_quest_completes_at_target() -> void:
	_reset_quest_manager()
	_reset_shipping_bin()
	var qm := QuestManager
	var quest := _make_deliver_quest("deliver_10_wool", "wool", 10, "sprinkler_tier_1")
	qm.register_quest(quest)
	_check(not qm.is_unlocked("sprinkler_tier_1"), "flag should start locked")

	ShippingBinManager.ship_item("wool", 6, 5)
	_check(not qm.is_completed("deliver_10_wool"), "quest should not complete before target reached")

	ShippingBinManager.ship_item("wool", 4, 5) # cumulative 10
	_check(qm.is_completed("deliver_10_wool"), "quest should complete once target quantity is delivered")
	_check(qm.is_unlocked("sprinkler_tier_1"), "unlock flag should flip on completion")

func _test_deliver_item_quest_ignores_other_items() -> void:
	_reset_quest_manager()
	_reset_shipping_bin()
	var qm := QuestManager
	var quest := _make_deliver_quest("deliver_5_egg", "egg", 5, "auto_feeder_tier_1")
	qm.register_quest(quest)
	ShippingBinManager.ship_item("wool", 100, 5) # unrelated item, large quantity
	_check(not qm.is_completed("deliver_5_egg"), "shipping an unrelated item should not progress or complete this quest")

func _test_deliver_item_quest_does_not_re_fire_after_completion() -> void:
	_reset_quest_manager()
	_reset_shipping_bin()
	var qm := QuestManager
	var quest := _make_deliver_quest("deliver_3_apple", "apple", 3, "flag_x")
	qm.register_quest(quest)
	_quest_completed_events = []
	qm.quest_completed.connect(_on_quest_completed_for_test)
	ShippingBinManager.ship_item("apple", 3, 2)
	ShippingBinManager.ship_item("apple", 5, 2) # already completed, should not re-fire
	qm.quest_completed.disconnect(_on_quest_completed_for_test)
	_check(_quest_completed_events.size() == 1,
		"quest_completed should fire exactly once, fired %d times" % _quest_completed_events.size())

func _test_friendship_quest_completes_at_target_hearts() -> void:
	_reset_quest_manager()
	_reset_relationship_manager_for_quests()
	var rm := RelationshipManager
	var qm := QuestManager
	var quest := _make_friendship_quest("elena_2_hearts", "Elena", 2, "collection_hub_tier_1")
	qm.register_quest(quest)

	rm._add_points("Elena", RelationshipManager.POINTS_PER_HEART) # 1 heart
	_check(not qm.is_completed("elena_2_hearts"), "should not complete at 1 heart when target is 2")

	rm._add_points("Elena", RelationshipManager.POINTS_PER_HEART) # 2 hearts
	_check(qm.is_completed("elena_2_hearts"), "should complete once target hearts is reached")
	_check(qm.is_unlocked("collection_hub_tier_1"), "unlock flag should flip on completion")

func _test_reregistering_quest_preserves_completion_state() -> void:
	_reset_quest_manager()
	_reset_shipping_bin()
	var qm := QuestManager
	var quest := _make_deliver_quest("deliver_1_stone", "stone", 1, "flag_y")
	qm.register_quest(quest)
	ShippingBinManager.ship_item("stone", 1, 1)
	_check(qm.is_completed("deliver_1_stone"), "sanity: quest should be completed before re-registering")

	qm.register_quest(quest) # simulate re-registering the same content on a later boot
	_check(qm.is_completed("deliver_1_stone"), "re-registering an already-completed quest should not reset its completion")

func _test_evaluate_skill_level_completes_matching_quest() -> void:
	_reset_quest_manager()
	var qm := QuestManager
	var quest := _make_skill_quest("farming_lvl_5", "Farming", 5, "flag_z")
	qm.register_quest(quest)

	qm.evaluate_skill_level("Fishing", 10) # wrong skill
	_check(not qm.is_completed("farming_lvl_5"), "a different skill's level-up should not complete this quest")

	qm.evaluate_skill_level("Farming", 3) # below target
	_check(not qm.is_completed("farming_lvl_5"), "a below-target level should not complete the quest")

	qm.evaluate_skill_level("Farming", 5)
	_check(qm.is_completed("farming_lvl_5"), "matching skill at/above target level should complete the quest")

func _test_quest_save_round_trip() -> void:
	_reset_quest_manager()
	_reset_shipping_bin()
	var qm := QuestManager
	var quest := _make_deliver_quest("deliver_2_milk", "milk", 2, "flag_save_test")
	qm.register_quest(quest)
	ShippingBinManager.ship_item("milk", 2, 3)
	_check(qm.is_completed("deliver_2_milk"), "sanity check before save")

	var saved := SaveManager.build_save_data()

	_reset_quest_manager()
	_check(not qm.is_completed("deliver_2_milk"), "sanity check: reset should clear completion before applying save data")

	SaveManager.apply_save_data(saved)

	_check(qm.is_completed("deliver_2_milk"), "completion should round-trip through save/load")
	_check(qm.is_unlocked("flag_save_test"), "unlock flag should round-trip through save/load")
	_check(qm.delivered_count("milk") == 2,
		"delivered totals should round-trip through save/load, got %d" % qm.delivered_count("milk"))

## --- ENG-25: Skill Leveling ---

func _on_xp_gained_for_test(skill_name: String, amount: int, total_xp: int) -> void:
	_xp_gained_events.append([skill_name, amount, total_xp])

func _on_level_changed_for_test(skill_name: String, new_level: int, old_level: int) -> void:
	_level_changed_events.append([skill_name, new_level, old_level])

func _test_add_xp_accumulates_and_emits() -> void:
	var sm := SkillManager
	sm._xp = {}
	_xp_gained_events = []
	sm.xp_gained.connect(_on_xp_gained_for_test)
	sm.add_xp("Fishing", 40)
	sm.add_xp("Fishing", 35)
	sm.xp_gained.disconnect(_on_xp_gained_for_test)

	_check(sm.get_xp("Fishing") == 75, "XP should accumulate across calls, got %d" % sm.get_xp("Fishing"))
	_check(_xp_gained_events.size() == 2
		and _xp_gained_events[0] == ["Fishing", 40, 40]
		and _xp_gained_events[1] == ["Fishing", 35, 75],
		"xp_gained should report per-call amount and running total, got %s" % [_xp_gained_events])

func _test_level_thresholds_match_cumulative_curve() -> void:
	var sm := SkillManager
	sm._xp = {}

	sm._xp["Farming"] = 99
	_check(sm.get_level("Farming") == 0, "99 XP should be level 0, got %d" % sm.get_level("Farming"))
	sm._xp["Farming"] = 100
	_check(sm.get_level("Farming") == 1, "100 XP should be exactly level 1, got %d" % sm.get_level("Farming"))
	sm._xp["Farming"] = 299
	_check(sm.get_level("Farming") == 1, "299 XP should still be level 1, got %d" % sm.get_level("Farming"))
	sm._xp["Farming"] = 300
	_check(sm.get_level("Farming") == 2, "300 XP should be exactly level 2, got %d" % sm.get_level("Farming"))
	sm._xp["Farming"] = 600
	_check(sm.get_level("Farming") == 3, "600 XP should be exactly level 3, got %d" % sm.get_level("Farming"))

func _test_level_changed_fires_once_per_level_on_single_step() -> void:
	var sm := SkillManager
	sm._xp = {}
	_level_changed_events = []
	sm.level_changed.connect(_on_level_changed_for_test)
	sm.add_xp("Mining", 100) # crosses 0 -> 1 exactly
	sm.level_changed.disconnect(_on_level_changed_for_test)

	_check(_level_changed_events.size() == 1 and _level_changed_events[0] == ["Mining", 1, 0],
		"a single-level step should fire level_changed once with (new=1, old=0), got %s" % [_level_changed_events])

func _test_level_changed_fires_for_each_crossed_level_on_big_jump() -> void:
	var sm := SkillManager
	sm._xp = {}
	_level_changed_events = []
	sm.level_changed.connect(_on_level_changed_for_test)
	sm.add_xp("Foraging", 600) # 0 straight to level 3 in one grant
	sm.level_changed.disconnect(_on_level_changed_for_test)

	_check(_level_changed_events.size() == 3
		and _level_changed_events[0] == ["Foraging", 1, 0]
		and _level_changed_events[1] == ["Foraging", 2, 1]
		and _level_changed_events[2] == ["Foraging", 3, 2],
		"a multi-level jump should fire level_changed once per crossed level, in order, got %s" % [_level_changed_events])

func _test_add_xp_non_positive_is_noop() -> void:
	var sm := SkillManager
	sm._xp = {}
	sm.add_xp("Farming", 0)
	sm.add_xp("Farming", -10)
	_check(sm.get_xp("Farming") == 0, "non-positive XP grants should be a no-op, got %d" % sm.get_xp("Farming"))

func _test_level_up_drives_quest_skill_level_condition() -> void:
	_reset_quest_manager()
	var sm := SkillManager
	sm._xp = {}
	var qm := QuestManager
	var quest := _make_skill_quest("farming_lvl_1", "Farming", 1, "flag_skill_test")
	qm.register_quest(quest)
	_check(not qm.is_completed("farming_lvl_1"), "sanity: quest should not be completed before leveling up")

	SkillManager.add_xp("Farming", 100) # crosses to level 1

	_check(qm.is_completed("farming_lvl_1"),
		"leveling Farming to 1 should complete the matching SKILL_LEVEL quest via SkillManager's QuestManager hook")
	_check(qm.is_unlocked("flag_skill_test"), "unlock flag should flip as a result of the skill-driven quest completion")

func _test_skill_save_round_trip() -> void:
	var sm := SkillManager
	sm._xp = {}
	sm._xp["Fishing"] = 250 # level 1: >= cumulative(1)=100, < cumulative(2)=300

	var saved := SaveManager.build_save_data()

	sm._xp = {}
	_check(sm.get_xp("Fishing") == 0, "sanity check: reset should clear XP before applying save data")

	SaveManager.apply_save_data(saved)

	_check(sm.get_xp("Fishing") == 250, "XP should round-trip through save/load, got %d" % sm.get_xp("Fishing"))
	_check(sm.get_level("Fishing") == 1, "level should be correctly derived after round-trip, got %d" % sm.get_level("Fishing"))

## --- ENG-23: Tool Upgrades ---

func _reset_tool_manager() -> void:
	var tm := ToolManager
	tm._tool_tiers = {}
	tm._ore_counts = {}

func _on_ore_added_for_test(item_id: String, quantity: int, total: int) -> void:
	_ore_added_events.append([item_id, quantity, total])

func _on_tool_upgraded_for_test(tool_name: String, new_tier: int) -> void:
	_tool_upgraded_events.append([tool_name, new_tier])

func _test_new_tool_starts_at_copper_defaults() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	_check(tm.get_tool_tier("Hoe") == ToolManager.TIER_COPPER,
		"an unregistered tool should default to Copper, got %d" % tm.get_tool_tier("Hoe"))
	_check(tm.get_aoe_offsets("Hoe") == ToolManager.COPPER_AOE_OFFSETS,
		"Copper AoE should be the single-tile default")
	_check(tm.get_stamina_cost("Hoe") == ToolManager.COPPER_STAMINA_COST,
		"Copper stamina cost should be the default, got %d" % tm.get_stamina_cost("Hoe"))

func _test_add_ore_accumulates_and_emits() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	_ore_added_events = []
	tm.ore_added.connect(_on_ore_added_for_test)
	tm.add_ore("iron_ore", 3)
	tm.add_ore("iron_ore", 2)
	tm.ore_added.disconnect(_on_ore_added_for_test)

	_check(tm.get_ore_count("iron_ore") == 5, "ore should accumulate across calls, got %d" % tm.get_ore_count("iron_ore"))
	_check(_ore_added_events.size() == 2
		and _ore_added_events[0] == ["iron_ore", 3, 3]
		and _ore_added_events[1] == ["iron_ore", 2, 5],
		"ore_added should report per-call amount and running total, got %s" % [_ore_added_events])

func _test_cannot_upgrade_without_enough_ore() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	ShippingBinManager.gold = 1000 # gold is not the limiting factor here
	tm.add_ore("iron_ore", 2) # Iron tier needs 5

	_check(not tm.can_upgrade("Hoe"), "can_upgrade should be false with insufficient ore")
	var ok := tm.upgrade_tool("Hoe")
	_check(not ok, "upgrade_tool should fail with insufficient ore")
	_check(tm.get_tool_tier("Hoe") == ToolManager.TIER_COPPER, "tier should remain unchanged on a failed upgrade")

func _test_cannot_upgrade_without_enough_gold() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	ShippingBinManager.gold = 0
	tm.add_ore("iron_ore", 10) # plenty of ore

	_check(not tm.can_upgrade("Hoe"), "can_upgrade should be false with insufficient gold")
	var ok := tm.upgrade_tool("Hoe")
	_check(not ok, "upgrade_tool should fail with insufficient gold")

func _test_failed_gold_spend_does_not_consume_ore() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	ShippingBinManager.gold = 0
	tm.add_ore("iron_ore", 10)
	tm.upgrade_tool("Hoe")

	_check(tm.get_ore_count("iron_ore") == 10,
		"a failed upgrade (insufficient gold) should not consume any ore, got %d" % tm.get_ore_count("iron_ore"))

func _test_successful_upgrade_deducts_costs_and_advances_tier() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	var sb := ShippingBinManager
	sb.gold = 1000
	tm.add_ore("iron_ore", 10)
	_tool_upgraded_events = []
	tm.tool_upgraded.connect(_on_tool_upgraded_for_test)
	var ok := tm.upgrade_tool("Hoe")
	tm.tool_upgraded.disconnect(_on_tool_upgraded_for_test)

	_check(ok, "upgrade should succeed with sufficient ore and gold")
	_check(tm.get_tool_tier("Hoe") == 1, "tier should advance to Iron (1), got %d" % tm.get_tool_tier("Hoe"))
	_check(tm.get_ore_count("iron_ore") == 5, "ore should be deducted by the tier's cost, got %d" % tm.get_ore_count("iron_ore"))
	_check(sb.gold == 800, "gold should be deducted by the tier's cost, got %d" % sb.gold)
	_check(_tool_upgraded_events.size() == 1 and _tool_upgraded_events[0] == ["Hoe", 1],
		"tool_upgraded should fire once with (Hoe, 1), got %s" % [_tool_upgraded_events])
	_check(tm.get_aoe_offsets("Hoe").size() == 5,
		"Iron tier AoE should be the 5-tile cross pattern, got %d tiles" % tm.get_aoe_offsets("Hoe").size())
	_check(tm.get_stamina_cost("Hoe") == 4, "Iron tier stamina cost should be 4, got %d" % tm.get_stamina_cost("Hoe"))

func _test_tools_upgrade_independently() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	ShippingBinManager.gold = 1000
	tm.add_ore("iron_ore", 10)
	tm.upgrade_tool("Hoe")

	_check(tm.get_tool_tier("Hoe") == 1, "sanity: Hoe should be upgraded")
	_check(tm.get_tool_tier("Pickaxe") == ToolManager.TIER_COPPER,
		"Pickaxe should remain at Copper -- tools upgrade independently, got %d" % tm.get_tool_tier("Pickaxe"))

func _test_cannot_upgrade_past_gold_tier() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	ShippingBinManager.gold = 100000
	tm.add_ore("iron_ore", 100)
	tm.add_ore("gold_ore", 100)
	tm.upgrade_tool("Hoe") # -> Iron
	tm.upgrade_tool("Hoe") # -> Gold
	_check(tm.get_tool_tier("Hoe") == 2, "sanity: Hoe should be at Gold tier, got %d" % tm.get_tool_tier("Hoe"))

	var ok := tm.upgrade_tool("Hoe") # no tier 3 defined
	_check(not ok, "upgrading past Gold (no further tier defined) should fail")
	_check(tm.get_tool_tier("Hoe") == 2, "tier should remain at Gold after a failed further-upgrade attempt")

func _test_tool_save_round_trip() -> void:
	_reset_tool_manager()
	var tm := ToolManager
	ShippingBinManager.gold = 1000
	tm.add_ore("iron_ore", 10)
	tm.upgrade_tool("Hoe")
	tm.add_ore("gold_ore", 3) # leftover unspent ore of a different type

	var saved := SaveManager.build_save_data()

	_reset_tool_manager()
	_check(tm.get_tool_tier("Hoe") == ToolManager.TIER_COPPER, "sanity: reset should clear tier before applying save data")

	SaveManager.apply_save_data(saved)

	_check(tm.get_tool_tier("Hoe") == 1, "tool tier should round-trip through save/load, got %d" % tm.get_tool_tier("Hoe"))
	_check(tm.get_ore_count("iron_ore") == 5, "remaining ore should round-trip through save/load, got %d" % tm.get_ore_count("iron_ore"))
	_check(tm.get_ore_count("gold_ore") == 3, "unspent different-ore-type count should round-trip, got %d" % tm.get_ore_count("gold_ore"))

## --- ENG-13: Inventory ledger ---

func _on_item_changed_for_test(item_id: String, delta: int, total: int) -> void:
	_item_changed_events.append([item_id, delta, total])

func _reset_inventory_manager() -> void:
	InventoryManager._counts = {}

func _test_inventory_add_and_remove() -> void:
	_reset_inventory_manager()
	var im := InventoryManager
	_item_changed_events = []
	im.item_changed.connect(_on_item_changed_for_test)
	im.add_item("parsnip", 3)
	im.add_item("parsnip", 2)
	var removed := im.remove_item("parsnip", 4)
	im.item_changed.disconnect(_on_item_changed_for_test)

	_check(removed, "removing an in-stock quantity should succeed")
	_check(im.get_count("parsnip") == 1, "count should reflect adds minus removes, got %d" % im.get_count("parsnip"))
	_check(_item_changed_events.size() == 3
		and _item_changed_events[0] == ["parsnip", 3, 3]
		and _item_changed_events[1] == ["parsnip", 2, 5]
		and _item_changed_events[2] == ["parsnip", -4, 1],
		"item_changed should report per-call delta and running total, got %s" % [_item_changed_events])

func _test_inventory_remove_fails_when_insufficient() -> void:
	_reset_inventory_manager()
	var im := InventoryManager
	im.add_item("egg", 2)
	var ok := im.remove_item("egg", 5)
	_check(not ok, "removing more than in stock should fail")
	_check(im.get_count("egg") == 2, "a failed removal should not change the count, got %d" % im.get_count("egg"))

func _test_inventory_has_item() -> void:
	_reset_inventory_manager()
	var im := InventoryManager
	im.add_item("wool", 3)
	_check(im.has_item("wool"), "has_item defaults to checking for at least 1")
	_check(im.has_item("wool", 3), "has_item(3) should be true with exactly 3 on hand")
	_check(not im.has_item("wool", 4), "has_item(4) should be false with only 3 on hand")

func _test_inventory_sell_item_ships_and_removes() -> void:
	_reset_inventory_manager()
	_reset_shipping_bin()
	var im := InventoryManager
	im.add_item("turnip", 5)
	var ok := im.sell_item("turnip", 3, 10)
	_check(ok, "selling in-stock quantity should succeed")
	_check(im.get_count("turnip") == 2, "sell_item should remove the sold quantity from inventory, got %d" % im.get_count("turnip"))
	_check(ShippingBinManager.pending_item_count() == 3, "sell_item should forward the sale to ShippingBinManager, got %d pending" % ShippingBinManager.pending_item_count())

func _test_inventory_sell_item_fails_without_removing_on_short_stock() -> void:
	_reset_inventory_manager()
	_reset_shipping_bin()
	var im := InventoryManager
	im.add_item("turnip", 1)
	var ok := im.sell_item("turnip", 5, 10)
	_check(not ok, "selling more than on hand should fail")
	_check(im.get_count("turnip") == 1, "a failed sale should not touch inventory, got %d" % im.get_count("turnip"))
	_check(ShippingBinManager.pending_item_count() == 0, "a failed sale should not reach the shipping bin")

func _test_inventory_save_round_trip() -> void:
	_reset_inventory_manager()
	var im := InventoryManager
	im.add_item("milk", 7)

	var saved := SaveManager.build_save_data()
	_reset_inventory_manager()
	_check(im.get_count("milk") == 0, "sanity check: reset should clear inventory before applying save data")

	SaveManager.apply_save_data(saved)
	_check(im.get_count("milk") == 7, "inventory counts should round-trip through save/load, got %d" % im.get_count("milk"))

## --- ENG-13: Agriculture (FarmPlotManager) ---

func _reset_farm_plot_manager() -> void:
	FarmPlotManager._plots = {}

func _on_crop_planted_for_test(position: Vector2i, crop_id: String) -> void:
	_crop_planted_events.append([position, crop_id])

func _on_crop_watered_for_test(position: Vector2i) -> void:
	_crop_watered_events.append(position)

func _on_crop_harvested_for_test(position: Vector2i, item_id: String, quality: String, quantity: int) -> void:
	_crop_harvested_events.append([position, item_id, quality, quantity])

func _on_crop_withered_for_test(position: Vector2i, crop_id: String) -> void:
	_crop_withered_events.append([position, crop_id])

func _test_cannot_plant_wrong_season() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 1 # Summer; Parsnip is Spring-only
	var ok := FarmPlotManager.plant(Vector2i(0, 0), "parsnip")
	_check(not ok, "planting a Spring-only crop outside Spring should fail")
	_check(not FarmPlotManager.is_planted(Vector2i(0, 0)), "a rejected plant() should leave the plot empty")

func _test_plant_and_water_and_growth_progresses_on_watered_days() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var fpm := FarmPlotManager
	_crop_planted_events = []
	fpm.crop_planted.connect(_on_crop_planted_for_test)
	var ok := fpm.plant(Vector2i(1, 1), "parsnip")
	fpm.crop_planted.disconnect(_on_crop_planted_for_test)
	_check(ok, "planting a valid crop in-season should succeed")
	_check(_crop_planted_events.size() == 1 and _crop_planted_events[0] == [Vector2i(1, 1), "parsnip"],
		"crop_planted should fire once with (position, crop_id), got %s" % [_crop_planted_events])

	# Parsnip takes 4 watered days to grow.
	for i in range(4):
		var watered := fpm.water(Vector2i(1, 1))
		_check(watered, "water() should succeed on an unwatered, not-yet-ready plot (day %d)" % i)
		fpm._on_day_started(i + 1, "Spring", "Mon")

	var plot := fpm.get_plot(Vector2i(1, 1))
	_check(plot.harvest_ready, "plot should be harvest_ready after 4 watered days (days_to_grow), got days_grown=%d" % plot.days_grown)

func _test_growth_does_not_progress_on_unwatered_days() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(2, 2), "parsnip")
	fpm._on_day_started(1, "Spring", "Mon") # never watered
	var plot := fpm.get_plot(Vector2i(2, 2))
	_check(plot.days_grown == 0, "an unwatered day should not advance growth, got days_grown=%d" % plot.days_grown)
	_check(not plot.harvest_ready, "an unwatered plot should never become harvest_ready")

func _test_watered_today_resets_each_day() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(3, 3), "parsnip")
	fpm.water(Vector2i(3, 3))
	fpm._on_day_started(1, "Spring", "Mon")
	var plot := fpm.get_plot(Vector2i(3, 3))
	_check(not plot.watered_today, "watered_today should reset to false after a day rollover, matching #13's reset requirement")

func _test_cannot_water_twice_same_day() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(4, 4), "parsnip")
	var first := fpm.water(Vector2i(4, 4))
	var second := fpm.water(Vector2i(4, 4))
	_check(first, "first water() this day should succeed")
	_check(not second, "a second water() the same day should be rejected")

func _grow_to_harvest(position: Vector2i, days: int) -> void:
	var fpm := FarmPlotManager
	for i in range(days):
		fpm.water(position)
		fpm._on_day_started(i + 1, TimeManager.current_season(), "Mon")

func _test_harvest_credits_inventory_and_xp_and_clears_plot() -> void:
	_reset_farm_plot_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	SkillManager._xp = {}
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(5, 5), "parsnip")
	_grow_to_harvest(Vector2i(5, 5), 4)
	_check(fpm.get_plot(Vector2i(5, 5)).harvest_ready, "sanity: plot should be ready to harvest")

	_crop_harvested_events = []
	fpm.crop_harvested.connect(_on_crop_harvested_for_test)
	var result := fpm.harvest(Vector2i(5, 5), FarmPlotManager.QUALITY_NORMAL)
	fpm.crop_harvested.disconnect(_on_crop_harvested_for_test)

	_check(result.get("item_id") == "parsnip" and result.get("crop_id") == "parsnip" and result.get("quantity") == 1,
		"harvest() should return the harvested item_id/crop_id/quantity, got %s" % [result])
	_check(InventoryManager.get_count("parsnip") == 1, "harvest should credit InventoryManager, got %d" % InventoryManager.get_count("parsnip"))
	_check(SkillManager.get_xp("Farming") == fpm.get_crop_definition("parsnip").xp_reward,
		"harvest should award the crop's xp_reward into SkillManager's Farming skill, got %d" % SkillManager.get_xp("Farming"))
	_check(not fpm.is_planted(Vector2i(5, 5)), "a non-regrowable crop's plot should clear after harvest")
	_check(_crop_harvested_events.size() == 1 and _crop_harvested_events[0] == [Vector2i(5, 5), "parsnip", "normal", 1],
		"crop_harvested should fire once with (position, item_id, quality, quantity), got %s" % [_crop_harvested_events])

func _test_regrowable_crop_resets_instead_of_clearing() -> void:
	_reset_farm_plot_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 1 # Summer, Tomato
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(6, 6), "tomato")
	_grow_to_harvest(Vector2i(6, 6), 5) # tomato days_to_grow
	fpm.harvest(Vector2i(6, 6), FarmPlotManager.QUALITY_NORMAL)

	var plot := fpm.get_plot(Vector2i(6, 6))
	_check(plot != null and not plot.is_empty(), "a regrowable crop's plot should still exist after harvest, not clear")
	_check(plot.is_regrowing, "plot should flag is_regrowing after its first harvest")
	_check(plot.days_grown == 0 and not plot.harvest_ready, "plot should reset progress to start its regrow cycle")

	_grow_to_harvest(Vector2i(6, 6), 3) # tomato regrow_days
	_check(fpm.get_plot(Vector2i(6, 6)).harvest_ready, "plot should become harvest_ready again after regrow_days watered days")

	var result := fpm.harvest(Vector2i(6, 6), FarmPlotManager.QUALITY_GOLD)
	_check(result.get("crop_id") == "tomato", "second harvest should still report the same crop_id")
	_check(fpm.is_planted(Vector2i(6, 6)), "regrowable plot should remain planted after a second harvest too")

func _test_forced_quality_skips_random_roll() -> void:
	_reset_farm_plot_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(7, 7), "parsnip")
	_grow_to_harvest(Vector2i(7, 7), 4)
	var result := fpm.harvest(Vector2i(7, 7), FarmPlotManager.QUALITY_GOLD)
	_check(result.get("quality") == "gold", "forced_quality should bypass the random roll, got %s" % result.get("quality"))
	_check(result.get("item_id") == "parsnip_gold", "a forced gold-quality harvest should use the gold-suffixed item_id")

func _test_item_id_encodes_quality() -> void:
	var fpm := FarmPlotManager
	_check(fpm.get_item_id("parsnip", FarmPlotManager.QUALITY_NORMAL) == "parsnip",
		"normal quality should use the bare crop_id as item_id")
	_check(fpm.get_item_id("parsnip", FarmPlotManager.QUALITY_SILVER) == "parsnip_silver",
		"silver quality should suffix the item_id")
	_check(fpm.get_item_id("parsnip", FarmPlotManager.QUALITY_GOLD) == "parsnip_gold",
		"gold quality should suffix the item_id")

func _test_sell_price_applies_quality_multiplier() -> void:
	var fpm := FarmPlotManager
	_check(fpm.get_sell_price("parsnip", FarmPlotManager.QUALITY_NORMAL) == 35,
		"normal quality should sell at the crop's base_sell_price, got %d" % fpm.get_sell_price("parsnip", FarmPlotManager.QUALITY_NORMAL))
	_check(fpm.get_sell_price("parsnip", FarmPlotManager.QUALITY_SILVER) == 44,
		"silver quality should sell at 1.25x base (round(35*1.25)=44), got %d" % fpm.get_sell_price("parsnip", FarmPlotManager.QUALITY_SILVER))
	_check(fpm.get_sell_price("parsnip", FarmPlotManager.QUALITY_GOLD) == 53,
		"gold quality should sell at 1.5x base (round(35*1.5)=53), got %d" % fpm.get_sell_price("parsnip", FarmPlotManager.QUALITY_GOLD))

func _test_crop_withers_when_season_ends_unharvested() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(8, 8), "parsnip")
	fpm.water(Vector2i(8, 8))

	_crop_withered_events = []
	fpm.crop_withered.connect(_on_crop_withered_for_test)
	fpm._on_day_started(1, "Summer", "Mon") # season rolled past Spring before harvest
	fpm.crop_withered.disconnect(_on_crop_withered_for_test)

	_check(not fpm.is_planted(Vector2i(8, 8)), "a plot whose crop's season has ended should clear (wither)")
	_check(_crop_withered_events.size() == 1 and _crop_withered_events[0] == [Vector2i(8, 8), "parsnip"],
		"crop_withered should fire once with (position, crop_id), got %s" % [_crop_withered_events])

func _test_farm_plot_save_round_trip() -> void:
	_reset_farm_plot_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var fpm := FarmPlotManager
	fpm.plant(Vector2i(9, 9), "parsnip")
	fpm.water(Vector2i(9, 9))
	fpm._on_day_started(1, "Spring", "Mon")

	var saved := SaveManager.build_save_data()
	_reset_farm_plot_manager()
	_check(not fpm.is_planted(Vector2i(9, 9)), "sanity check: reset should clear plots before applying save data")

	SaveManager.apply_save_data(saved)

	var plot := fpm.get_plot(Vector2i(9, 9))
	_check(plot != null and plot.crop_id == "parsnip" and plot.days_grown == 1 and not plot.watered_today,
		"farm plot state should round-trip through save/load, got %s" % [plot.to_dict() if plot else null])

## --- ENG-17: Foraging (ForagingManager) ---

func _reset_forage_manager() -> void:
	ForagingManager._nodes = {}

func _on_forage_gathered_for_test(position: Vector2i, item_id: String, quantity: int) -> void:
	_forage_gathered_events.append([position, item_id, quantity])

func _on_forage_rerolled_for_test(position: Vector2i, item_id: String) -> void:
	_forage_rerolled_events.append([position, item_id])

func _test_forage_register_node_seeds_season_valid_item() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	var fm := ForagingManager
	fm.register_node(Vector2i(0, 0))
	var node := fm.get_forage_node(Vector2i(0, 0))
	_check(node != null and not node.is_empty(), "register_node should immediately seed a season-valid item")
	var def := fm.get_forageable_definition(node.item_id)
	_check(def != null and def.valid_seasons.has("Spring"),
		"a freshly seeded node's item should be valid for the current season, got '%s'" % node.item_id)
	_check(fm.is_available(Vector2i(0, 0)), "a freshly seeded node should be immediately available")

func _test_forage_gather_credits_inventory_and_xp_and_sets_cooldown() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	SkillManager._xp = {}
	TimeManager.season_index = 0 # Spring
	var fm := ForagingManager
	fm.register_node(Vector2i(1, 1))
	var item_id := fm.get_forage_node(Vector2i(1, 1)).item_id
	var def := fm.get_forageable_definition(item_id)

	_forage_gathered_events = []
	fm.forage_gathered.connect(_on_forage_gathered_for_test)
	var result := fm.gather(Vector2i(1, 1))
	fm.forage_gathered.disconnect(_on_forage_gathered_for_test)

	_check(result.get("item_id") == item_id and result.get("quantity") == 1,
		"gather() should return the gathered item_id/quantity, got %s" % [result])
	_check(InventoryManager.get_count(item_id) == 1, "gather should credit InventoryManager, got %d" % InventoryManager.get_count(item_id))
	_check(SkillManager.get_xp("Foraging") == def.xp_reward,
		"gather should award the item's xp_reward into SkillManager's Foraging skill, got %d" % SkillManager.get_xp("Foraging"))
	_check(fm.get_forage_node(Vector2i(1, 1)).cooldown_days_remaining == def.respawn_days,
		"gather should put the node on cooldown for the item's respawn_days, got %d" % fm.get_forage_node(Vector2i(1, 1)).cooldown_days_remaining)
	_check(not fm.is_available(Vector2i(1, 1)), "a just-gathered node should not be available")
	_check(_forage_gathered_events.size() == 1 and _forage_gathered_events[0] == [Vector2i(1, 1), item_id, 1],
		"forage_gathered should fire once with (position, item_id, quantity), got %s" % [_forage_gathered_events])

func _test_forage_gather_fails_when_unavailable() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var fm := ForagingManager
	var missing_result := fm.gather(Vector2i(2, 2))
	_check(missing_result.is_empty(), "gathering an unregistered position should return an empty Dictionary")

	fm.register_node(Vector2i(3, 3))
	fm.gather(Vector2i(3, 3))
	var second_result := fm.gather(Vector2i(3, 3))
	_check(second_result.is_empty(), "gathering an on-cooldown node should return an empty Dictionary")

func _test_forage_cooldown_counts_down_and_becomes_available_again() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var fm := ForagingManager
	fm.register_node(Vector2i(4, 4))
	var def := fm.get_forageable_definition(fm.get_forage_node(Vector2i(4, 4)).item_id)
	fm.gather(Vector2i(4, 4))
	var respawn_days := def.respawn_days

	for i in range(respawn_days - 1):
		fm._on_day_started(i + 1, "Spring", "Mon")
		_check(not fm.is_available(Vector2i(4, 4)),
			"node should still be on cooldown after %d/%d day(s)" % [i + 1, respawn_days])

	fm._on_day_started(respawn_days, "Spring", "Mon")
	_check(fm.is_available(Vector2i(4, 4)),
		"node should become available again once its full respawn_days have elapsed")

func _test_forage_node_rerolls_when_season_ends() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	var fm := ForagingManager
	fm.register_node(Vector2i(5, 5))
	var node := fm.get_forage_node(Vector2i(5, 5))
	node.item_id = "wild_flower" # Spring-only placeholder item, forced for a deterministic test
	node.cooldown_days_remaining = 0

	_forage_rerolled_events = []
	fm.forage_node_rerolled.connect(_on_forage_rerolled_for_test)
	fm._on_day_started(1, "Summer", "Mon") # season rolled past Spring
	fm.forage_node_rerolled.disconnect(_on_forage_rerolled_for_test)

	_check(node.item_id != "wild_flower", "a node holding an out-of-season item should reroll rather than sit stale, got '%s'" % node.item_id)
	var new_def := fm.get_forageable_definition(node.item_id)
	_check(new_def != null and new_def.valid_seasons.has("Summer"),
		"the rerolled item should be valid for the new season, got '%s'" % node.item_id)
	_check(_forage_rerolled_events.size() == 1 and _forage_rerolled_events[0][0] == Vector2i(5, 5),
		"forage_node_rerolled should fire once for the rerolled position, got %s" % [_forage_rerolled_events])

func _test_forage_node_goes_dormant_with_no_season_valid_content() -> void:
	_reset_forage_manager()
	var fm := ForagingManager
	var original_definitions: Dictionary = fm._definitions.duplicate()
	fm._definitions = {}
	var spring_only := ForageableDefinition.new()
	spring_only.item_id = "test_spring_only"
	spring_only.valid_seasons = ["Spring"]
	spring_only.base_sell_price = 1
	spring_only.xp_reward = 1
	spring_only.respawn_days = 1
	fm.register_forageable(spring_only)

	TimeManager.season_index = 3 # Winter -- nothing registered is valid here
	fm.register_node(Vector2i(50, 50))
	var node := fm.get_forage_node(Vector2i(50, 50))
	_check(node.is_empty(), "a node should go dormant (empty item_id) when nothing is valid for the current season, got item_id='%s'" % node.item_id)
	_check(not fm.is_available(Vector2i(50, 50)), "a dormant node should not be available")

	fm._definitions = original_definitions

func _test_forage_save_round_trip() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var fm := ForagingManager
	fm.register_node(Vector2i(9, 9))
	var item_id := fm.get_forage_node(Vector2i(9, 9)).item_id
	var def := fm.get_forageable_definition(item_id)
	fm.gather(Vector2i(9, 9))

	var saved := SaveManager.build_save_data()
	_reset_forage_manager()
	_check(fm.get_forage_node(Vector2i(9, 9)) == null, "sanity check: reset should clear nodes before applying save data")

	SaveManager.apply_save_data(saved)

	var node := fm.get_forage_node(Vector2i(9, 9))
	_check(node != null and node.item_id == item_id and node.cooldown_days_remaining == def.respawn_days,
		"forage node state should round-trip through save/load, got %s" % [node.to_dict() if node else null])

## --- ENG-26: Opening hook (intro sequence + new_game/save/load) ---

func _test_new_game_resets_state_to_defaults() -> void:
	# Dirty every system's state first.
	TimeManager.year = 5
	TimeManager.day_in_season = 20
	StaminaManager.current_stamina = 1
	ShippingBinManager.gold = 0
	ShippingBinManager.ship_item("wool", 1, 1)
	RelationshipManager._add_points("Elena", 500)
	SkillManager.add_xp("Farming", 999)
	ToolManager.add_ore("iron_ore", 10)
	SaveManager.intro_seen = true
	TimeManager.season_index = 0 # Spring
	ForagingManager.register_node(Vector2i(99, 99))

	SaveManager.new_game()

	_check(TimeManager.year == 1 and TimeManager.day_in_season == 1,
		"new_game should reset TimeManager to defaults, got year=%d day=%d" % [TimeManager.year, TimeManager.day_in_season])
	_check(StaminaManager.current_stamina == StaminaManager.MAX_STAMINA_DEFAULT,
		"new_game should reset StaminaManager to full default stamina, got %d" % StaminaManager.current_stamina)
	_check(RelationshipManager.get_points("Elena") == 0,
		"new_game should reset RelationshipManager points, got %d" % RelationshipManager.get_points("Elena"))
	_check(SkillManager.get_xp("Farming") == 0,
		"new_game should reset SkillManager XP, got %d" % SkillManager.get_xp("Farming"))
	_check(ToolManager.get_ore_count("iron_ore") == 0,
		"new_game should reset ToolManager ore counts, got %d" % ToolManager.get_ore_count("iron_ore"))
	_check(ForagingManager.get_forage_node(Vector2i(99, 99)) == null,
		"new_game should reset ForagingManager nodes, got %s" % [ForagingManager.get_forage_node(Vector2i(99, 99))])
	_check(not SaveManager.has_seen_intro(),
		"new_game should reset intro_seen to false so the intro plays again on a fresh save")

func _test_new_game_grants_starting_gold_and_copper_tools() -> void:
	ShippingBinManager.gold = 12345
	SaveManager.new_game()
	_check(ShippingBinManager.gold == ShippingBinManager.STARTING_GOLD,
		"new_game should grant STARTING_GOLD, got %d" % ShippingBinManager.gold)
	_check(ToolManager.get_tool_tier("Hoe") == ToolManager.TIER_COPPER,
		"new_game should leave tools at their free Copper starting tier, got %d" % ToolManager.get_tool_tier("Hoe"))

func _test_save_and_load_round_trip_persists_intro_seen() -> void:
	SaveManager.delete_save_file()
	SaveManager.new_game() # writes a fresh save file with intro_seen = false
	_check(not SaveManager.has_seen_intro(), "sanity: new_game should start with intro not yet seen")

	SaveManager.mark_intro_seen() # persists intro_seen = true to disk
	_check(SaveManager.has_seen_intro(), "mark_intro_seen should flip has_seen_intro() immediately")

	# Simulate a fresh boot: clear in-memory state, then reload from disk.
	SaveManager.intro_seen = false
	TimeManager.year = 99
	var loaded := SaveManager.load_game()

	_check(loaded, "load_game should succeed when a save file exists")
	_check(SaveManager.has_seen_intro(),
		"intro_seen should round-trip through save/load so the intro doesn't replay on a later boot")
	_check(TimeManager.year == 1, "load_game should restore other system state alongside intro_seen, got year=%d" % TimeManager.year)

	SaveManager.delete_save_file()

func _test_load_game_returns_false_without_save_file() -> void:
	SaveManager.delete_save_file()
	var loaded := SaveManager.load_game()
	_check(not loaded, "load_game should return false when no save file exists on disk")

func _on_intro_finished_for_test() -> void:
	_intro_finished_count += 1

func _test_intro_sequence_advances_through_lines_then_finishes() -> void:
	TimeManager.unfreeze("intro") # in case a prior failing test left this set
	var intro := IntroSequence.new()
	intro.lines = ["one", "two", "three"]
	_intro_finished_count = 0
	intro.finished.connect(_on_intro_finished_for_test)
	add_child(intro)

	_check(intro.current_line() == "one", "intro should start on the first line, got '%s'" % intro.current_line())
	intro.advance()
	_check(intro.current_line() == "two", "advance() should move to the next line, got '%s'" % intro.current_line())
	intro.advance()
	_check(intro.current_line() == "three", "advance() should move to the third line, got '%s'" % intro.current_line())
	_check(not intro.is_finished(), "intro should not be finished while a line is still showing")

	intro.advance() # advances past the last line -> finishes
	_check(intro.is_finished(), "intro should be finished once every line has been advanced past")
	_check(_intro_finished_count == 1, "finished signal should fire exactly once, fired %d times" % _intro_finished_count)

	intro.advance() # should be a no-op once finished
	_check(_intro_finished_count == 1, "advance() after finishing should not re-fire the finished signal")

	intro.finished.disconnect(_on_intro_finished_for_test)
	intro.queue_free()

func _test_intro_sequence_freezes_and_unfreezes_time_manager() -> void:
	TimeManager.unfreeze("intro") # in case a prior failing test left this set
	var was_frozen_before := TimeManager.is_frozen()
	var intro := IntroSequence.new()
	intro.lines = ["only line"]
	add_child(intro)

	_check(TimeManager.is_frozen(), "starting the intro sequence should freeze TimeManager")
	intro.advance() # past the only line -> finishes
	_check(TimeManager.is_frozen() == was_frozen_before,
		"finishing the intro sequence should unfreeze TimeManager's 'intro' reason")

	intro.queue_free()

## --- ENG-14: Ranching (AnimalManager) ---

func _reset_animal_manager() -> void:
	AnimalManager._animals = {}

func _test_add_animal_requires_registered_species() -> void:
	_reset_animal_manager()
	var bad := AnimalManager.add_animal("hen1", "dragon")
	_check(not bad, "adding an animal with an unregistered species should fail")

	var ok := AnimalManager.add_animal("hen1", "chicken")
	_check(ok, "adding an animal with a registered species should succeed")
	_check(AnimalManager.has_animal("hen1"), "animal should be tracked after a successful add")

func _test_add_animal_rejects_duplicate_id() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("hen1", "chicken")
	var dup := AnimalManager.add_animal("hen1", "cow")
	_check(not dup, "adding an animal with an already-used id should fail")
	_check(AnimalManager.get_animal("hen1").species_id == "chicken",
		"the original animal should be unchanged after a rejected duplicate add")

func _test_feed_once_per_day() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("hen1", "chicken")
	var first := AnimalManager.feed("hen1")
	var second := AnimalManager.feed("hen1")
	_check(first, "first feeding of the day should succeed")
	_check(not second, "a second feeding the same day should be rejected")

	AnimalManager._on_day_started(1, "Spring", "Mon")
	var next_day := AnimalManager.feed("hen1")
	_check(next_day, "feeding should be accepted again after a day rollover")

func _test_brush_once_per_day() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("hen1", "chicken")
	var first := AnimalManager.brush("hen1")
	var second := AnimalManager.brush("hen1")
	_check(first, "first brushing of the day should succeed")
	_check(not second, "a second brushing the same day should be rejected")

	AnimalManager._on_day_started(1, "Spring", "Mon")
	var next_day := AnimalManager.brush("hen1")
	_check(next_day, "brushing should be accepted again after a day rollover")

func _test_product_progresses_only_on_fed_days() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("hen1", "chicken") # 1-day producer
	AnimalManager._on_day_started(1, "Spring", "Mon") # not fed
	_check(not AnimalManager.get_animal("hen1").product_ready, "an unfed chicken should not produce")

	AnimalManager.feed("hen1")
	AnimalManager._on_day_started(2, "Spring", "Tue")
	_check(AnimalManager.get_animal("hen1").product_ready,
		"a fed chicken (1-day producer) should be ready after one fed day")

func _test_neglect_reduces_happiness_no_progress() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("cow1", "cow")
	var before: int = AnimalManager.get_animal("cow1").happiness
	AnimalManager._on_day_started(1, "Spring", "Mon") # not fed
	var after: int = AnimalManager.get_animal("cow1").happiness

	_check(after == before - AnimalManager.NEGLECT_HAPPINESS_DELTA,
		"an unfed day should reduce happiness by NEGLECT_HAPPINESS_DELTA, got %d -> %d" % [before, after])
	_check(AnimalManager.get_animal("cow1").days_since_product == 0,
		"an unfed day should not progress toward the next product")

func _test_collect_product_credits_inventory_and_xp() -> void:
	_reset_animal_manager()
	_reset_inventory_manager()
	SkillManager._xp = {}
	AnimalManager.add_animal("hen1", "chicken")
	AnimalManager.feed("hen1")
	AnimalManager._on_day_started(1, "Spring", "Mon") # happiness 50 -> 60 (fed, unbrushed), ready (1-day producer)

	var result := AnimalManager.collect_product("hen1")
	_check(not result.is_empty(), "collect_product should succeed once ready")
	_check(result["item_id"] == "egg_silver",
		"happiness 60 should harvest Silver-quality egg, got %s" % [result])
	_check(InventoryManager.get_count("egg_silver") == 1,
		"collect_product should credit InventoryManager, got %d" % InventoryManager.get_count("egg_silver"))
	_check(SkillManager.get_xp("Farming") == 3,
		"collect_product should credit Farming XP (ranching feeds Farming, not a separate skill), got %d" % SkillManager.get_xp("Farming"))
	_check(not AnimalManager.get_animal("hen1").product_ready,
		"collecting should clear product_ready until the next cycle")

func _test_collect_product_before_ready_returns_empty() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("hen1", "chicken")
	var result := AnimalManager.collect_product("hen1")
	_check(result.is_empty(), "collecting before a product is ready should return an empty dict")

func _test_quality_tier_follows_happiness() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("cow1", "cow")
	var gold_animal := AnimalManager.get_animal("cow1")
	gold_animal.happiness = 90
	gold_animal.product_ready = true
	var gold_result := AnimalManager.collect_product("cow1")
	_check(gold_result["quality"] == AnimalManager.QUALITY_GOLD,
		"happiness 90 should harvest Gold quality, got %s" % [gold_result])

	AnimalManager.add_animal("cow2", "cow")
	var silver_animal := AnimalManager.get_animal("cow2")
	silver_animal.happiness = 60
	silver_animal.product_ready = true
	var silver_result := AnimalManager.collect_product("cow2")
	_check(silver_result["quality"] == AnimalManager.QUALITY_SILVER,
		"happiness 60 should harvest Silver quality, got %s" % [silver_result])

	AnimalManager.add_animal("cow3", "cow")
	var normal_animal := AnimalManager.get_animal("cow3")
	normal_animal.happiness = 10
	normal_animal.product_ready = true
	var normal_result := AnimalManager.collect_product("cow3")
	_check(normal_result["quality"] == AnimalManager.QUALITY_NORMAL,
		"happiness 10 should harvest Normal quality, got %s" % [normal_result])

func _test_multi_day_producer_needs_multiple_fed_days() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("sheep1", "sheep") # 3-day producer
	for i in range(2):
		AnimalManager.feed("sheep1")
		AnimalManager._on_day_started(i + 1, "Spring", "Mon")
	_check(not AnimalManager.get_animal("sheep1").product_ready,
		"sheep should not be ready after only 2 of 3 required fed days")

	AnimalManager.feed("sheep1")
	AnimalManager._on_day_started(3, "Spring", "Mon")
	_check(AnimalManager.get_animal("sheep1").product_ready, "sheep should be ready after 3 fed days")

	var result := AnimalManager.collect_product("sheep1")
	_check(not result.is_empty(), "sanity: collect should succeed once ready")
	_check(not AnimalManager.get_animal("sheep1").product_ready, "collecting should reset product_ready")
	_check(AnimalManager.get_animal("sheep1").days_since_product == 0,
		"collecting should reset days_since_product for the next cycle")

func _test_animal_save_round_trip() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("hen1", "chicken")
	AnimalManager.feed("hen1")
	AnimalManager._on_day_started(1, "Spring", "Mon") # happiness -> 60, product_ready -> true

	var saved := SaveManager.build_save_data()

	_reset_animal_manager()
	_check(not AnimalManager.has_animal("hen1"), "sanity check: reset should clear animals before applying save data")

	SaveManager.apply_save_data(saved)

	_check(AnimalManager.has_animal("hen1"), "animal should round-trip through save/load")
	_check(AnimalManager.get_animal("hen1").happiness == 60,
		"happiness should round-trip through save/load, got %d" % AnimalManager.get_animal("hen1").happiness)
	_check(AnimalManager.get_animal("hen1").product_ready, "product_ready should round-trip through save/load")

## --- ENG-15: Fishing (FishingManager) ---

func _test_available_fish_filters_by_location_season_hour() -> void:
	var fm := FishingManager
	var pool := fm.get_available_fish("river", "Spring", 8)
	_check(pool == ["carp", "trout"], "river/Spring/08:00 should surface exactly carp and trout, got %s" % [pool])

	var pool_fall := fm.get_available_fish("river", "Fall", 8)
	_check(pool_fall.has("salmon") and pool_fall.has("trout") and pool_fall.has("carp"),
		"river/Fall/08:00 should include carp, trout, and salmon, got %s" % [pool_fall])

	var pool_outside_hour := fm.get_available_fish("river", "Spring", 15)
	_check(not pool_outside_hour.has("trout"),
		"trout should not be available outside its 06:00-11:00 window, got %s" % [pool_outside_hour])
	_check(pool_outside_hour.has("carp"), "carp (all-day) should remain available at hour 15")

func _test_available_fish_sorted_and_ignores_unregistered() -> void:
	var fm := FishingManager
	var pool := fm.get_available_fish("ocean", "Summer", 10)
	_check(pool == ["tuna"], "ocean/Summer/10:00 should surface only tuna, got %s" % [pool])

	var empty_pool := fm.get_available_fish("volcano", "Summer", 10)
	_check(empty_pool.is_empty(), "a location no fish is registered for should return an empty pool, got %s" % [empty_pool])

func _test_attempt_catch_unregistered_fish_returns_empty() -> void:
	var result := FishingManager.attempt_catch("dragon", 1.0)
	_check(result.is_empty(), "attempting to catch an unregistered fish_id should return an empty dict")

func _test_attempt_catch_below_difficulty_escapes() -> void:
	_reset_inventory_manager()
	var result := FishingManager.attempt_catch("trout", 0.1) # difficulty 0.5
	_check(not result["success"], "a performance below difficulty should fail to catch")
	_check(result["fish_id"] == "trout", "an escaped result should still report the fish_id, got %s" % [result])
	_check(InventoryManager.get_count("trout") == 0, "an escaped catch should not add anything to inventory")

func _test_attempt_catch_success_credits_inventory_and_xp() -> void:
	_reset_inventory_manager()
	SkillManager._xp = {}
	var result := FishingManager.attempt_catch("trout", 0.55) # difficulty 0.5, below the 0.6 Silver threshold
	_check(result["success"], "a performance at/above difficulty should succeed")
	_check(result["item_id"] == "trout", "a Normal-quality catch should use the bare fish_id as item_id, got %s" % result["item_id"])
	_check(InventoryManager.get_count("trout") == 1,
		"a successful catch should credit InventoryManager, got %d" % InventoryManager.get_count("trout"))
	_check(SkillManager.get_xp("Fishing") == 5,
		"a successful catch should credit Fishing XP, got %d" % SkillManager.get_xp("Fishing"))

func _test_catch_quality_tiers_follow_performance() -> void:
	_reset_inventory_manager()
	var gold := FishingManager.attempt_catch("carp", 0.95) # difficulty 0.2
	_check(gold["quality"] == FishingManager.QUALITY_GOLD, "performance 0.95 should be Gold quality, got %s" % [gold])

	var silver := FishingManager.attempt_catch("carp", 0.65)
	_check(silver["quality"] == FishingManager.QUALITY_SILVER, "performance 0.65 should be Silver quality, got %s" % [silver])

	var normal := FishingManager.attempt_catch("carp", 0.3)
	_check(normal["quality"] == FishingManager.QUALITY_NORMAL, "performance 0.3 should be Normal quality, got %s" % [normal])

func _test_item_id_encodes_quality_for_normal_catch() -> void:
	_reset_inventory_manager()
	var gold_result := FishingManager.attempt_catch("carp", 0.95)
	_check(gold_result["item_id"] == "carp_gold", "Gold-quality catch should encode quality in the item_id, got %s" % gold_result["item_id"])

	var normal_result := FishingManager.attempt_catch("carp", 0.25)
	_check(normal_result["item_id"] == "carp", "Normal-quality catch should use the bare fish_id as item_id, got %s" % normal_result["item_id"])

func _test_sell_price_applies_quality_multiplier_for_fish() -> void:
	var fm := FishingManager
	_check(fm.get_sell_price("trout", FishingManager.QUALITY_NORMAL) == 40,
		"Normal trout should sell at base price 40, got %d" % fm.get_sell_price("trout", FishingManager.QUALITY_NORMAL))
	_check(fm.get_sell_price("trout", FishingManager.QUALITY_SILVER) == 50,
		"Silver trout should sell at 1.25x base (50), got %d" % fm.get_sell_price("trout", FishingManager.QUALITY_SILVER))
	_check(fm.get_sell_price("trout", FishingManager.QUALITY_GOLD) == 60,
		"Gold trout should sell at 1.5x base (60), got %d" % fm.get_sell_price("trout", FishingManager.QUALITY_GOLD))
	_check(fm.get_sell_price("dragon", FishingManager.QUALITY_GOLD) == 0,
		"an unregistered fish_id should report 0 sell price")
