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
var _proposal_rejected_events: Array = [] ## Array[Array] of [npc_name, reason], same reason
var _wedding_scheduled_events: Array = [] ## Array[Array] of [npc_name, days_until], same reason
var _married_events: Array = [] ## Array[String] of npc_name, same reason
var _child_born_events: Array = [] ## Array[Array] of [npc_name, total_children], same reason
var _festival_started_events: Array = [] ## Array[String] of festival_id, same reason
var _festival_ended_events: Array = [] ## Array[String] of festival_id, same reason
var _mini_game_result_events: Array = [] ## Array[Array] of [festival_id, score, success], same reason
var _bundle_contribution_events: Array = [] ## Array[Array] of [bundle_id, item_id, quantity], same reason
var _bundle_completed_events: Array = [] ## Array[String] of bundle_id, same reason
var _year_three_evaluation_events: Array = [] ## Array[Array] of [challenge_mode, completed, total, passed], same reason
var _game_over_events: Array = [] ## Array[String] of reason, same reason
var _weather_changed_events: Array = [] ## Array[String] of weather, same reason
var _inventory_overlay_closed_count := 0 ## member, not a local -- GDScript lambdas capture locals by value
var _skills_overlay_closed_count := 0 ## same reason

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
	_test_gift_by_npc_name_looks_up_real_preferences()
	_test_gift_by_npc_name_unknown_npc_is_graceful_noop()
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

	_test_hud_format_clock()
	_test_hud_format_date()
	_test_hud_gold_label_updates_on_signal()
	_test_hud_stamina_bar_updates_on_signal()
	_test_hud_clock_label_updates_on_minute_passed()
	_test_hud_initial_state_reflects_current_backend_values()
	_test_hud_weather_label_primed_on_ready()
	_test_hud_weather_label_updates_on_signal()

	_test_pause_menu_open_and_close_toggle_state()
	_test_pause_menu_freezes_and_unfreezes_time_manager()
	_test_pause_menu_resume_button_closes_and_unfreezes()
	_test_pause_menu_inventory_button_shows_overlay_and_hides_menu_panel()
	_test_pause_menu_still_frozen_while_inventory_overlay_open()
	_test_inventory_overlay_lists_current_items_on_ready()
	_test_inventory_overlay_updates_reactively_on_item_changed()
	_test_inventory_overlay_removes_row_when_item_reaches_zero()
	_test_inventory_overlay_close_emits_closed_signal()
	_test_skills_overlay_lists_all_known_skills_on_ready()
	_test_skills_overlay_updates_reactively_on_xp_gained()
	_test_skills_overlay_close_emits_closed_signal()
	_test_pause_menu_skills_button_shows_overlay_and_hides_menu_panel()
	_test_pause_menu_still_frozen_while_skills_overlay_open()
	_test_pause_menu_map_and_settings_buttons_stay_disabled()

	_test_farm_scene_instantiates_without_error()
	_test_farm_scene_renders_empty_grid_on_ready()
	_test_farm_scene_renders_already_planted_plot_on_ready()
	_test_farm_scene_updates_on_crop_planted_signal()
	_test_farm_scene_updates_on_crop_watered_signal()
	_test_farm_scene_updates_on_crop_harvested_signal()
	_test_farm_scene_updates_on_crop_withered_signal()
	_test_farm_scene_click_plants_empty_tile()
	_test_farm_scene_click_ignores_out_of_grid_position()
	_test_ranch_scene_instantiates_without_error()
	_test_ranch_scene_renders_empty_grid_on_ready()
	_test_ranch_scene_renders_already_occupied_pen_on_ready()
	_test_ranch_scene_updates_on_animal_added_signal()
	_test_ranch_scene_updates_on_animal_fed_signal()
	_test_ranch_scene_updates_on_animal_brushed_signal()
	_test_ranch_scene_updates_on_product_collected_signal()
	_test_ranch_scene_click_adds_animal_to_empty_pen()
	_test_ranch_scene_click_feeds_then_brushes_then_collects()
	_test_ranch_scene_click_ignores_out_of_grid_position()
	_test_forage_scene_instantiates_without_error()
	_test_forage_scene_populates_and_renders_available_nodes_on_ready()
	_test_forage_scene_renders_already_registered_cooldown_node_on_ready()
	_test_forage_scene_updates_on_forage_gathered_signal()
	_test_forage_scene_updates_on_forage_node_rerolled_signal()
	_test_forage_scene_click_gathers_available_tile()
	_test_forage_scene_click_ignores_cooldown_tile()
	_test_forage_scene_click_ignores_out_of_grid_position()
	_test_mine_scene_instantiates_without_error()
	_test_mine_scene_renders_ladder_and_rock_on_ready()
	_test_mine_scene_updates_on_rock_broken_signal()
	_test_mine_scene_updates_on_floor_descended_signal()
	_test_mine_scene_click_breaks_rock_tile()
	_test_mine_scene_click_ladder_descends()
	_test_mine_scene_click_ignores_out_of_grid_position()

	_test_available_fish_filters_by_location_season_hour()
	_test_available_fish_sorted_and_ignores_unregistered()
	_test_attempt_catch_unregistered_fish_returns_empty()
	_test_attempt_catch_below_difficulty_escapes()
	_test_attempt_catch_success_credits_inventory_and_xp()
	_test_catch_quality_tiers_follow_performance()
	_test_item_id_encodes_quality_for_normal_catch()
	_test_sell_price_applies_quality_multiplier_for_fish()

	_test_cannot_upgrade_house_without_quest_unlock()
	_test_cannot_upgrade_house_without_material()
	_test_cannot_upgrade_house_without_gold()
	_test_house_upgrade_succeeds_and_deducts_costs()
	_test_coop_capacity_starts_at_base_and_increases_per_tier()
	_test_cannot_build_machine_without_quest_unlock()
	_test_build_machine_succeeds_and_deducts_costs()
	_test_start_job_fails_without_machine_built()
	_test_start_job_fails_without_enough_input()
	_test_start_job_consumes_input_and_ticks_to_ready()
	_test_collect_job_before_ready_returns_empty()
	_test_start_job_rejects_duplicate_job_id()
	_test_infrastructure_save_round_trip()
	_test_marriage_cannot_propose_ineligible_npc()
	_test_marriage_cannot_propose_without_enough_hearts()
	_test_marriage_cannot_propose_without_item()
	_test_marriage_propose_consumes_item_and_schedules_wedding()
	_test_marriage_cannot_propose_twice_while_engaged()
	_test_marriage_wedding_countdown_finalizes_marriage()
	_test_marriage_marry_directly_for_ceremony_scene_hook()
	_test_marriage_daily_gold_bonus_only_when_married()
	_test_marriage_child_born_rolls_once_per_season_start()
	_test_marriage_save_round_trip()
	_test_is_festival_day_matches_registered_date()
	_test_get_festival_for_date_returns_null_off_date()
	_test_start_festival_freezes_time_and_emits()
	_test_start_festival_unregistered_id_fails()
	_test_start_festival_while_another_active_fails()
	_test_start_festival_idempotent_for_same_id()
	_test_end_festival_unfreezes_time_and_emits()
	_test_end_festival_noop_when_none_active()
	_test_day_started_auto_triggers_registered_festival()
	_test_day_started_does_not_trigger_on_non_festival_day()
	_test_submit_mini_game_result_unregistered_returns_empty()
	_test_submit_mini_game_result_pass_and_fail()

	_test_generate_floor_places_ladder_without_rock()
	_test_generate_floor_all_other_tiles_start_as_unbroken_rock()
	_test_break_rock_credits_stone_or_ore_and_xp()
	_test_break_rock_twice_returns_empty_second_time()
	_test_break_rock_on_ladder_tile_returns_empty()
	_test_roll_ore_respects_min_floor_gating()
	_test_descend_ladder_advances_floor_and_regenerates()
	_test_mining_save_round_trip()

	_test_bundle_registration_preserves_progress_on_reregister()
	_test_contribute_item_success_and_clamps_to_remaining()
	_test_contribute_item_fails_unknown_bundle()
	_test_contribute_item_fails_bundle_not_owning_item()
	_test_contribute_item_fails_insufficient_inventory_stock()
	_test_contribute_item_fails_once_bundle_complete()
	_test_bundle_completion_fires_signal_once()
	_test_year_three_evaluation_open_ended_is_non_terminal()
	_test_year_three_evaluation_challenge_mode_pass()
	_test_year_three_evaluation_challenge_mode_fail_triggers_game_over()
	_test_community_goal_save_round_trip()

	_test_weather_rolls_valid_values_for_non_winter_season()
	_test_weather_winter_uses_snowy_not_rainy()
	_test_weather_changed_only_fires_on_actual_change()
	_test_weather_save_round_trip()
	_test_npc_schedule_entry_weather_gating()

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

func _test_gift_by_npc_name_looks_up_real_preferences() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager

	# elena.tres (PR #58): loved_items includes "wild_flower", hated_items
	# includes "eel". No table is passed in here -- give_gift_by_npc_name()
	# must load elena.tres itself via GIFT_PREFERENCE_PATHS.
	var accepted := rm.give_gift_by_npc_name("Elena", "wild_flower")
	_check(accepted, "give_gift_by_npc_name() should succeed for a known NPC")
	_check(rm.get_points("Elena") == 80,
		"a loved gift looked up from elena.tres should add 80 points, got %d" % rm.get_points("Elena"))

	rm._on_day_started(1, "Spring", "Mon")
	rm.give_gift_by_npc_name("Elena", "eel")
	_check(rm.get_points("Elena") == 40,
		"a hated gift looked up from elena.tres should subtract 40 points, got %d" % rm.get_points("Elena"))

func _test_gift_by_npc_name_unknown_npc_is_graceful_noop() -> void:
	_reset_relationship_manager()
	var rm := RelationshipManager

	var accepted := rm.give_gift_by_npc_name("NotARealNPC", "wild_flower")
	_check(not accepted, "give_gift_by_npc_name() should return false for an NPC with no known preference table")
	_check(rm.get_points("NotARealNPC") == 0,
		"an unknown NPC should not gain points or crash, got %d" % rm.get_points("NotARealNPC"))
	_check(not rm.has_gifted_today("NotARealNPC"),
		"a graceful no-op should not consume the once-per-day gift slot")

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

## --- Frontend: HUD (design/ui-flows/menu-hud-flow-spec.md) ---
##
## Godot UI scenes are hard to meaningfully assert on headlessly beyond
## "does the bound Label/ProgressBar text or value match backend state after
## a signal fires" -- exact pixel layout, colors, and iconography are not
## asserted here (there are none yet; see hud.gd's docstring on the
## placeholder-layout content gap) and can only really be verified by
## looking at a running scene.

func _make_hud() -> HUD:
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud: HUD = hud_scene.instantiate()
	add_child(hud)
	return hud

func _test_hud_format_clock() -> void:
	_check(HUD.format_clock(6, 0) == "6:00 AM", "6:00 should format as '6:00 AM', got '%s'" % HUD.format_clock(6, 0))
	_check(HUD.format_clock(0, 0) == "12:00 AM", "midnight (hour=0) should format as '12:00 AM', got '%s'" % HUD.format_clock(0, 0))
	_check(HUD.format_clock(12, 30) == "12:30 PM", "noon should format as '12:30 PM', got '%s'" % HUD.format_clock(12, 30))
	_check(HUD.format_clock(23, 5) == "11:05 PM", "23:05 should format as '11:05 PM', got '%s'" % HUD.format_clock(23, 5))

func _test_hud_format_date() -> void:
	var s := HUD.format_date("Mon", "Spring", 1, 1)
	_check(s == "Mon, Spring 1 (Yr 1)", "format_date should produce 'Mon, Spring 1 (Yr 1)', got '%s'" % s)

func _test_hud_gold_label_updates_on_signal() -> void:
	_reset_shipping_bin()
	var hud := _make_hud()
	ShippingBinManager.gold = 250
	ShippingBinManager.gold_changed.emit(250)
	_check(hud.get_node("TopBar/GoldClockCluster/GoldLabel").text == "250 G",
		"gold label should update when gold_changed fires, got '%s'" % hud.get_node("TopBar/GoldClockCluster/GoldLabel").text)
	hud.queue_free()

func _test_hud_stamina_bar_updates_on_signal() -> void:
	var hud := _make_hud()
	StaminaManager.stamina_changed.emit(30, 100)
	var bar: ProgressBar = hud.get_node("BottomBar/StaminaCluster/StaminaBar")
	_check(bar.value == 30 and bar.max_value == 100,
		"stamina bar should reflect stamina_changed payload, got value=%s max=%s" % [bar.value, bar.max_value])

	StaminaManager.stamina_changed.emit(0, 100)
	_check(bar.value == 0, "stamina bar should reflect a pass-out (0) value, got %s" % bar.value)
	hud.queue_free()

func _test_hud_clock_label_updates_on_minute_passed() -> void:
	var hud := _make_hud()
	var tm := TimeManager
	tm.hour = 14
	tm.minute = 45
	TimeManager.minute_passed.emit(14, 45)
	_check(hud.get_node("TopBar/GoldClockCluster/ClockLabel").text == "2:45 PM",
		"clock label should update from TimeManager's current hour/minute when minute_passed fires, got '%s'" % hud.get_node("TopBar/GoldClockCluster/ClockLabel").text)
	hud.queue_free()

func _test_hud_initial_state_reflects_current_backend_values() -> void:
	_reset_shipping_bin()
	ShippingBinManager.gold = 777
	StaminaManager.max_stamina = 100
	StaminaManager.current_stamina = 55
	var hud := _make_hud() # _ready() should prime labels from current state, not wait for a signal
	_check(hud.get_node("TopBar/GoldClockCluster/GoldLabel").text == "777 G",
		"gold label should be primed from current ShippingBinManager.gold on _ready(), got '%s'" % hud.get_node("TopBar/GoldClockCluster/GoldLabel").text)
	var bar: ProgressBar = hud.get_node("BottomBar/StaminaCluster/StaminaBar")
	_check(bar.value == 55, "stamina bar should be primed from current StaminaManager.current_stamina on _ready(), got %s" % bar.value)
	hud.queue_free()

func _test_hud_weather_label_primed_on_ready() -> void:
	var hud := _make_hud() # _ready() should prime the label from WeatherManager.get_current_weather(), not wait for a signal
	_check(hud.get_node("TopBar/DateCluster/Row/WeatherLabel").text == WeatherManager.get_current_weather(),
		"weather label should be primed from current WeatherManager.get_current_weather() on _ready(), got '%s'" % hud.get_node("TopBar/DateCluster/Row/WeatherLabel").text)
	hud.queue_free()

func _test_hud_weather_label_updates_on_signal() -> void:
	var hud := _make_hud()
	WeatherManager.weather_changed.emit("Rainy")
	_check(hud.get_node("TopBar/DateCluster/Row/WeatherLabel").text == "Rainy",
		"weather label should update when weather_changed fires, got '%s'" % hud.get_node("TopBar/DateCluster/Row/WeatherLabel").text)
	WeatherManager.weather_changed.emit("Sunny")
	_check(hud.get_node("TopBar/DateCluster/Row/WeatherLabel").text == "Sunny",
		"weather label should update again on a second weather_changed emission, got '%s'" % hud.get_node("TopBar/DateCluster/Row/WeatherLabel").text)
	hud.queue_free()

## --- Frontend: Pause menu + Inventory overlay (menu-hud-flow-spec.md §1/§3) ---
##
## Same discipline as the HUD block above: what's asserted here is signal
## wiring, freeze/unfreeze pairing, and reactive label state -- exact
## layout/visuals can only be verified by looking at a running scene (see
## pause_menu.gd / inventory_overlay.gd docstrings for the content gaps).

func _make_pause_menu() -> PauseMenu:
	var scene: PackedScene = load("res://scenes/ui/PauseMenu.tscn")
	var menu: PauseMenu = scene.instantiate()
	add_child(menu)
	return menu

func _make_inventory_overlay() -> InventoryOverlay:
	var scene: PackedScene = load("res://scenes/ui/InventoryOverlay.tscn")
	var overlay: InventoryOverlay = scene.instantiate()
	add_child(overlay)
	return overlay

## The ui_cancel input binding itself (_unhandled_input) isn't exercised
## here -- simulating a real input event headlessly through the viewport is
## not meaningfully testable this way; this only asserts the open()/close()
## API surface that _unhandled_input calls into. Verifying Escape actually
## toggles the menu requires looking at a running scene.
func _test_pause_menu_open_and_close_toggle_state() -> void:
	var menu := _make_pause_menu()
	_check(not menu.is_open(), "pause menu should start closed")
	menu.open()
	_check(menu.is_open(), "open() should mark the menu open")
	menu.close()
	_check(not menu.is_open(), "close() should mark the menu closed")
	menu.queue_free()

func _test_pause_menu_freezes_and_unfreezes_time_manager() -> void:
	TimeManager.unfreeze(PauseMenu.PAUSE_REASON) # in case a prior failing test left this set
	var menu := _make_pause_menu()
	menu.open()
	_check(TimeManager.is_frozen(), "opening the pause menu should freeze TimeManager")
	menu.close()
	_check(not TimeManager.is_frozen(), "closing the pause menu should unfreeze TimeManager")
	menu.queue_free()

func _test_pause_menu_resume_button_closes_and_unfreezes() -> void:
	TimeManager.unfreeze(PauseMenu.PAUSE_REASON)
	var menu := _make_pause_menu()
	menu.open()
	menu.get_node("Root/MenuPanel/Margin/VBox/ResumeButton").pressed.emit()
	_check(not menu.is_open(), "Resume button should close the pause menu")
	_check(not TimeManager.is_frozen(), "Resume button should unfreeze TimeManager")
	menu.queue_free()

func _test_pause_menu_inventory_button_shows_overlay_and_hides_menu_panel() -> void:
	TimeManager.unfreeze(PauseMenu.PAUSE_REASON)
	var menu := _make_pause_menu()
	menu.open()
	menu.get_node("Root/MenuPanel/Margin/VBox/InventoryButton").pressed.emit()
	_check(not menu.get_node("Root/MenuPanel").visible,
		"opening Inventory should hide the main pause menu panel")
	_check(menu.get_node("InventoryOverlay") != null,
		"opening Inventory should instantiate the InventoryOverlay as a child")
	menu.close()
	menu.queue_free()

func _test_pause_menu_still_frozen_while_inventory_overlay_open() -> void:
	TimeManager.unfreeze(PauseMenu.PAUSE_REASON)
	var menu := _make_pause_menu()
	menu.open()
	menu.get_node("Root/MenuPanel/Margin/VBox/InventoryButton").pressed.emit()
	_check(TimeManager.is_frozen(),
		"TimeManager should stay frozen while the Inventory overlay is open (single pause-reason)")
	menu.close()
	_check(not TimeManager.is_frozen(), "closing from within the Inventory overlay should still fully unfreeze")
	menu.queue_free()

func _test_inventory_overlay_lists_current_items_on_ready() -> void:
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 3)
	InventoryManager.add_item("egg", 2)
	var overlay := _make_inventory_overlay() # _ready() should prime from current InventoryManager state
	_check(overlay.get_node("Root/Panel/Margin/VBox/ItemList/Item_parsnip").text == "parsnip  x3",
		"overlay should list parsnip x3 primed from current state")
	_check(overlay.get_node("Root/Panel/Margin/VBox/ItemList/Item_egg").text == "egg  x2",
		"overlay should list egg x2 primed from current state")
	overlay.queue_free()

func _test_inventory_overlay_updates_reactively_on_item_changed() -> void:
	_reset_inventory_manager()
	var overlay := _make_inventory_overlay()
	InventoryManager.add_item("wood", 5)
	_check(overlay.get_node("Root/Panel/Margin/VBox/ItemList/Item_wood").text == "wood  x5",
		"overlay should add a row reactively when item_changed fires for a new item")
	InventoryManager.add_item("wood", 4)
	_check(overlay.get_node("Root/Panel/Margin/VBox/ItemList/Item_wood").text == "wood  x9",
		"overlay row should update to the new running total")
	overlay.queue_free()

func _test_inventory_overlay_removes_row_when_item_reaches_zero() -> void:
	_reset_inventory_manager()
	InventoryManager.add_item("stone", 2)
	var overlay := _make_inventory_overlay()
	InventoryManager.remove_item("stone", 2)
	_check(not overlay.get_node("Root/Panel/Margin/VBox/ItemList").has_node("Item_stone"),
		"overlay row should be removed once an item's count reaches zero")
	overlay.queue_free()

func _on_inventory_overlay_closed_for_test() -> void:
	_inventory_overlay_closed_count += 1

func _test_inventory_overlay_close_emits_closed_signal() -> void:
	_reset_inventory_manager()
	_inventory_overlay_closed_count = 0
	var overlay := _make_inventory_overlay()
	overlay.closed.connect(_on_inventory_overlay_closed_for_test)
	overlay.get_node("Root/Panel/Margin/VBox/Header/CloseButton").pressed.emit()
	_check(_inventory_overlay_closed_count == 1, "pressing Close should emit the closed signal exactly once")
	overlay.queue_free()

## --- Frontend: Skills overlay (#52 sub-scope, menu-hud-flow-spec.md
## §1/§3) ---
##
## Same discipline as the Inventory overlay block above.

func _make_skills_overlay() -> SkillsOverlay:
	var scene: PackedScene = load("res://scenes/ui/SkillsOverlay.tscn")
	var overlay: SkillsOverlay = scene.instantiate()
	add_child(overlay)
	return overlay

func _test_skills_overlay_lists_all_known_skills_on_ready() -> void:
	SkillManager._xp = {}
	var overlay := _make_skills_overlay() # _ready() should prime every known skill, even with zero XP
	for skill_name in SkillsOverlay.SKILL_NAMES:
		_check(overlay.get_node("Root/Panel/Margin/VBox/SkillList/Skill_%s" % skill_name).text == "%s  Lv 0  (0 XP)" % skill_name,
			"overlay should list %s at Lv 0 (0 XP) when primed with no XP" % skill_name)
	overlay.queue_free()

func _test_skills_overlay_updates_reactively_on_xp_gained() -> void:
	SkillManager._xp = {}
	var overlay := _make_skills_overlay()
	SkillManager.add_xp("Farming", 50)
	_check(overlay.get_node("Root/Panel/Margin/VBox/SkillList/Skill_Farming").text == "Farming  Lv 0  (50 XP)",
		"overlay row should update reactively when xp_gained fires")
	SkillManager.add_xp("Farming", 100) # 150 total crosses the level-1 threshold (100)
	_check(overlay.get_node("Root/Panel/Margin/VBox/SkillList/Skill_Farming").text == "Farming  Lv 1  (150 XP)",
		"overlay row should reflect the new level once a level_changed-crossing xp_gained fires")
	overlay.queue_free()

func _on_skills_overlay_closed_for_test() -> void:
	_skills_overlay_closed_count += 1

func _test_skills_overlay_close_emits_closed_signal() -> void:
	_skills_overlay_closed_count = 0
	var overlay := _make_skills_overlay()
	overlay.closed.connect(_on_skills_overlay_closed_for_test)
	overlay.get_node("Root/Panel/Margin/VBox/Header/CloseButton").pressed.emit()
	_check(_skills_overlay_closed_count == 1, "pressing Close should emit the closed signal exactly once")
	overlay.queue_free()

func _test_pause_menu_skills_button_shows_overlay_and_hides_menu_panel() -> void:
	TimeManager.unfreeze(PauseMenu.PAUSE_REASON)
	var menu := _make_pause_menu()
	menu.open()
	menu.get_node("Root/MenuPanel/Margin/VBox/SkillsButton").pressed.emit()
	_check(not menu.get_node("Root/MenuPanel").visible,
		"opening Skills should hide the main pause menu panel")
	_check(menu.get_node("SkillsOverlay") != null,
		"opening Skills should instantiate the SkillsOverlay as a child")
	menu.close()
	menu.queue_free()

func _test_pause_menu_still_frozen_while_skills_overlay_open() -> void:
	TimeManager.unfreeze(PauseMenu.PAUSE_REASON)
	var menu := _make_pause_menu()
	menu.open()
	menu.get_node("Root/MenuPanel/Margin/VBox/SkillsButton").pressed.emit()
	_check(TimeManager.is_frozen(),
		"TimeManager should stay frozen while the Skills overlay is open (single pause-reason)")
	menu.close()
	_check(not TimeManager.is_frozen(), "closing from within the Skills overlay should still fully unfreeze")
	menu.queue_free()

func _test_pause_menu_map_and_settings_buttons_stay_disabled() -> void:
	var menu := _make_pause_menu()
	_check(menu.get_node("Root/MenuPanel/Margin/VBox/MapButton").disabled,
		"Map has no backing system yet and should stay a disabled placeholder")
	_check(menu.get_node("Root/MenuPanel/Margin/VBox/SettingsButton").disabled,
		"Settings has no backing system yet and should stay a disabled placeholder")
	menu.queue_free()

## --- Frontend: FarmScene (#52 sub-scope, world/tile-rendering for
## FarmPlotManager, design/art/isometric-grid-spec.md) ---
##
## Same discipline as the HUD/pause-menu blocks above: what's meaningfully
## testable headlessly is scene instantiation, TileSet/TileMap wiring, and
## that a signal fires -> the right tile's TileMap cell reflects the state
## FarmPlotManager reports. Exact pixel rendering/isometric layout can only
## be verified by looking at a running scene (see farm_scene.gd's
## docstring for the placeholder-visual content gap).

func _make_farm_scene() -> FarmScene:
	var scene: PackedScene = load("res://scenes/world/FarmScene.tscn")
	var farm_scene: FarmScene = scene.instantiate()
	add_child(farm_scene)
	return farm_scene

func _farm_scene_cell_source(farm_scene: FarmScene, position: Vector2i) -> Vector2i:
	var tilemap: TileMap = farm_scene.get_node("TileMap")
	return tilemap.get_cell_atlas_coords(0, position)

func _test_farm_scene_instantiates_without_error() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var farm_scene := _make_farm_scene()
	_check(farm_scene.get_node("TileMap") is TileMap, "FarmScene should contain a TileMap node")
	_check(farm_scene.get_node("TileMap").tile_set != null, "FarmScene's TileMap should have a TileSet assigned on _ready()")
	farm_scene.queue_free()

func _test_farm_scene_renders_empty_grid_on_ready() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var farm_scene := _make_farm_scene()
	_check(_farm_scene_cell_source(farm_scene, Vector2i(0, 0)) == Vector2i(FarmScene.STATE_EMPTY, 0),
		"an unplanted plot should render as STATE_EMPTY on ready")
	farm_scene.queue_free()

func _test_farm_scene_renders_already_planted_plot_on_ready() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	FarmPlotManager.plant(Vector2i(2, 3), "parsnip")
	var farm_scene := _make_farm_scene()
	_check(_farm_scene_cell_source(farm_scene, Vector2i(2, 3)) == Vector2i(FarmScene.STATE_PLANTED, 0),
		"a plot already planted before the scene enters the tree should render as STATE_PLANTED on ready, using get_plot() -- no 'get all plots' API needed")
	farm_scene.queue_free()

func _test_farm_scene_updates_on_crop_planted_signal() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var farm_scene := _make_farm_scene()
	FarmPlotManager.plant(Vector2i(1, 1), "parsnip")
	_check(_farm_scene_cell_source(farm_scene, Vector2i(1, 1)) == Vector2i(FarmScene.STATE_PLANTED, 0),
		"planting should reactively update the tile to STATE_PLANTED via crop_planted")
	farm_scene.queue_free()

func _test_farm_scene_updates_on_crop_watered_signal() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	FarmPlotManager.plant(Vector2i(4, 4), "parsnip")
	var farm_scene := _make_farm_scene()
	FarmPlotManager.water(Vector2i(4, 4))
	_check(_farm_scene_cell_source(farm_scene, Vector2i(4, 4)) == Vector2i(FarmScene.STATE_WATERED, 0),
		"watering should reactively update the tile to STATE_WATERED via crop_watered")
	farm_scene.queue_free()

func _test_farm_scene_updates_on_crop_harvested_signal() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	_reset_inventory_manager()
	FarmPlotManager.plant(Vector2i(5, 5), "parsnip")
	FarmPlotManager.get_plot(Vector2i(5, 5)).watered_today = true
	FarmPlotManager.get_plot(Vector2i(5, 5)).days_grown = 4
	FarmPlotManager.get_plot(Vector2i(5, 5)).harvest_ready = true
	var farm_scene := _make_farm_scene()
	_check(_farm_scene_cell_source(farm_scene, Vector2i(5, 5)) == Vector2i(FarmScene.STATE_READY, 0),
		"a ready-to-harvest plot should render as STATE_READY on ready")
	FarmPlotManager.harvest(Vector2i(5, 5))
	_check(_farm_scene_cell_source(farm_scene, Vector2i(5, 5)) == Vector2i(FarmScene.STATE_EMPTY, 0),
		"harvesting a one-shot (non-regrowable) crop should reactively clear the tile back to STATE_EMPTY via crop_harvested")
	farm_scene.queue_free()

func _test_farm_scene_updates_on_crop_withered_signal() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	FarmPlotManager.plant(Vector2i(6, 6), "parsnip")
	var farm_scene := _make_farm_scene()
	FarmPlotManager._plots.erase(Vector2i(6, 6)) # mirror what FarmPlotManager._on_day_started does before it emits crop_withered
	FarmPlotManager.crop_withered.emit(Vector2i(6, 6), "parsnip")
	_check(_farm_scene_cell_source(farm_scene, Vector2i(6, 6)) == Vector2i(FarmScene.STATE_WITHERED, 0),
		"a withered plot should render as STATE_WITHERED via crop_withered, even though get_plot() already reports empty by the time the signal fires")
	farm_scene.queue_free()

func _test_farm_scene_click_plants_empty_tile() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var farm_scene := _make_farm_scene()
	_check(FarmPlotManager.get_plot(Vector2i(0, 0)) == null, "sanity: tile should start unplanted")
	farm_scene._handle_tile_click(Vector2i(0, 0))
	var plot := FarmPlotManager.get_plot(Vector2i(0, 0))
	_check(plot != null and plot.crop_id == FarmScene.PLACEHOLDER_PLANT_CROP_ID,
		"clicking an empty in-season tile should plant the placeholder crop via FarmPlotManager.plant()")
	farm_scene.queue_free()

func _test_farm_scene_click_ignores_out_of_grid_position() -> void:
	_reset_farm_plot_manager()
	TimeManager.season_index = 0 # Spring
	var farm_scene := _make_farm_scene()
	farm_scene._handle_tile_click(Vector2i(-1, -1)) # outside the GRID_WIDTH x GRID_HEIGHT bounds
	_check(FarmPlotManager.get_plot(Vector2i(-1, -1)) == null,
		"a click outside the rendered grid should be a no-op, not reach FarmPlotManager")
	farm_scene.queue_free()

## --- Frontend: RanchScene (#52 sub-scope, world/tile-rendering for
## AnimalManager, design/art/isometric-grid-spec.md) ---
##
## Same discipline as the FarmScene block above. AnimalManager has no
## positional concept of its own, so RanchScene derives each pen's
## animal_id from its grid position ("pen_<x>_<y>") -- these tests exercise
## that derivation together with the signal-driven tile refresh.

func _make_ranch_scene() -> RanchScene:
	var scene: PackedScene = load("res://scenes/world/RanchScene.tscn")
	var ranch_scene: RanchScene = scene.instantiate()
	add_child(ranch_scene)
	return ranch_scene

func _ranch_scene_cell_source(ranch_scene: RanchScene, position: Vector2i) -> Vector2i:
	var tilemap: TileMap = ranch_scene.get_node("TileMap")
	return tilemap.get_cell_atlas_coords(0, position)

func _test_ranch_scene_instantiates_without_error() -> void:
	_reset_animal_manager()
	var ranch_scene := _make_ranch_scene()
	_check(ranch_scene.get_node("TileMap") is TileMap, "RanchScene should contain a TileMap node")
	_check(ranch_scene.get_node("TileMap").tile_set != null, "RanchScene's TileMap should have a TileSet assigned on _ready()")
	ranch_scene.queue_free()

func _test_ranch_scene_renders_empty_grid_on_ready() -> void:
	_reset_animal_manager()
	var ranch_scene := _make_ranch_scene()
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(0, 0)) == Vector2i(RanchScene.STATE_EMPTY, 0),
		"a pen with no animal should render as STATE_EMPTY on ready")
	ranch_scene.queue_free()

func _test_ranch_scene_renders_already_occupied_pen_on_ready() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("pen_2_1", "chicken")
	var ranch_scene := _make_ranch_scene()
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(2, 1)) == Vector2i(RanchScene.STATE_UNFED, 0),
		"a pen already occupied before the scene enters the tree should render as STATE_UNFED on ready, using get_animal() -- no 'get all animals' API needed")
	ranch_scene.queue_free()

func _test_ranch_scene_updates_on_animal_added_signal() -> void:
	_reset_animal_manager()
	var ranch_scene := _make_ranch_scene()
	AnimalManager.add_animal("pen_1_1", "chicken")
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(1, 1)) == Vector2i(RanchScene.STATE_UNFED, 0),
		"adding an animal should reactively update the tile to STATE_UNFED via animal_added")
	ranch_scene.queue_free()

func _test_ranch_scene_updates_on_animal_fed_signal() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("pen_3_2", "chicken")
	var ranch_scene := _make_ranch_scene()
	AnimalManager.feed("pen_3_2")
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(3, 2)) == Vector2i(RanchScene.STATE_FED, 0),
		"feeding should reactively update the tile to STATE_FED via animal_fed")
	ranch_scene.queue_free()

func _test_ranch_scene_updates_on_animal_brushed_signal() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("pen_0_3", "chicken")
	var ranch_scene := _make_ranch_scene()
	AnimalManager.brush("pen_0_3")
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(0, 3)) == Vector2i(RanchScene.STATE_UNFED, 0),
		"brushing alone (not fed) should leave the tile at STATE_UNFED -- brushing only affects happiness, not the fed-today state this scene renders")
	ranch_scene.queue_free()

func _test_ranch_scene_updates_on_product_collected_signal() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("pen_4_3", "chicken")
	var animal: Animal = AnimalManager.get_animal("pen_4_3")
	animal.fed_today = true
	animal.product_ready = true
	var ranch_scene := _make_ranch_scene()
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(4, 3)) == Vector2i(RanchScene.STATE_READY, 0),
		"a pen with a ready product should render as STATE_READY on ready")
	AnimalManager.collect_product("pen_4_3")
	_check(_ranch_scene_cell_source(ranch_scene, Vector2i(4, 3)) == Vector2i(RanchScene.STATE_FED, 0),
		"collecting should reactively update the tile away from STATE_READY via product_collected -- back to STATE_FED since fed_today is untouched by collection")
	ranch_scene.queue_free()

func _test_ranch_scene_click_adds_animal_to_empty_pen() -> void:
	_reset_animal_manager()
	var ranch_scene := _make_ranch_scene()
	_check(not AnimalManager.has_animal("pen_0_0"), "sanity: pen should start empty")
	ranch_scene._handle_tile_click(Vector2i(0, 0))
	_check(AnimalManager.has_animal("pen_0_0"), "clicking an empty pen should add the placeholder species via AnimalManager.add_animal()")
	ranch_scene.queue_free()

func _test_ranch_scene_click_feeds_then_brushes_then_collects() -> void:
	_reset_animal_manager()
	AnimalManager.add_animal("pen_1_0", "chicken")
	var animal: Animal = AnimalManager.get_animal("pen_1_0")
	var ranch_scene := _make_ranch_scene()

	ranch_scene._handle_tile_click(Vector2i(1, 0))
	_check(animal.fed_today, "first click on an occupied, unfed pen should feed it")

	ranch_scene._handle_tile_click(Vector2i(1, 0))
	_check(animal.brushed_today, "second click on a fed, unbrushed pen should brush it")

	animal.product_ready = true
	ranch_scene._handle_tile_click(Vector2i(1, 0))
	_check(not animal.product_ready, "third click on a fed, brushed, ready pen should collect its product")
	ranch_scene.queue_free()

func _test_ranch_scene_click_ignores_out_of_grid_position() -> void:
	_reset_animal_manager()
	var ranch_scene := _make_ranch_scene()
	ranch_scene._handle_tile_click(Vector2i(-1, -1)) # outside GRID_WIDTH x GRID_HEIGHT bounds
	_check(not AnimalManager.has_animal("pen_-1_-1"),
		"a click outside the rendered grid should be a no-op, not reach AnimalManager")
	ranch_scene.queue_free()

## --- Frontend: ForageScene (#52 sub-scope, world/tile-rendering for
## ForagingManager, design/art/isometric-grid-spec.md) ---
##
## Same discipline as the FarmScene/RanchScene blocks above. Unlike those
## two managers, ForagingManager hands node placement to the caller, so
## ForageScene both populates the grid (register_node per cell) and
## renders it -- these tests exercise both halves.

func _make_forage_scene() -> ForageScene:
	var scene: PackedScene = load("res://scenes/world/ForageScene.tscn")
	var forage_scene: ForageScene = scene.instantiate()
	add_child(forage_scene)
	return forage_scene

func _forage_scene_cell_source(forage_scene: ForageScene, position: Vector2i) -> Vector2i:
	var tilemap: TileMap = forage_scene.get_node("TileMap")
	return tilemap.get_cell_atlas_coords(0, position)

func _test_forage_scene_instantiates_without_error() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	var forage_scene := _make_forage_scene()
	_check(forage_scene.get_node("TileMap") is TileMap, "ForageScene should contain a TileMap node")
	_check(forage_scene.get_node("TileMap").tile_set != null, "ForageScene's TileMap should have a TileSet assigned on _ready()")
	forage_scene.queue_free()

func _test_forage_scene_populates_and_renders_available_nodes_on_ready() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	_check(ForagingManager.get_forage_node(Vector2i(0, 0)) == null, "sanity: node should not exist before the scene registers it")
	var forage_scene := _make_forage_scene()
	_check(ForagingManager.get_forage_node(Vector2i(0, 0)) != null,
		"_ready() should register a node for every grid cell, since ForagingManager hands placement to the caller")
	_check(_forage_scene_cell_source(forage_scene, Vector2i(0, 0)) == Vector2i(ForageScene.STATE_AVAILABLE, 0),
		"a freshly-registered in-season node should render as STATE_AVAILABLE on ready")
	forage_scene.queue_free()

func _test_forage_scene_renders_already_registered_cooldown_node_on_ready() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	ForagingManager.register_node(Vector2i(2, 3))
	ForagingManager.get_forage_node(Vector2i(2, 3)).cooldown_days_remaining = 2
	var forage_scene := _make_forage_scene()
	_check(_forage_scene_cell_source(forage_scene, Vector2i(2, 3)) == Vector2i(ForageScene.STATE_COOLDOWN, 0),
		"a node already registered and on cooldown before the scene enters the tree should render as STATE_COOLDOWN on ready, and register_node() should be a no-op that doesn't reset its cooldown")
	forage_scene.queue_free()

func _test_forage_scene_updates_on_forage_gathered_signal() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var forage_scene := _make_forage_scene()
	_check(_forage_scene_cell_source(forage_scene, Vector2i(1, 1)) == Vector2i(ForageScene.STATE_AVAILABLE, 0),
		"sanity: node should start available")
	ForagingManager.gather(Vector2i(1, 1))
	_check(_forage_scene_cell_source(forage_scene, Vector2i(1, 1)) == Vector2i(ForageScene.STATE_COOLDOWN, 0),
		"gathering should reactively update the tile to STATE_COOLDOWN via forage_gathered")
	forage_scene.queue_free()

func _test_forage_scene_updates_on_forage_node_rerolled_signal() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	var forage_scene := _make_forage_scene()
	var node := ForagingManager.get_forage_node(Vector2i(4, 4))
	node.item_id = "" # force dormant, bypassing the always-in-season four_leaf_clover candidate
	forage_scene._refresh_tile(Vector2i(4, 4)) # mirror what a real reroll-to-dormant would leave rendered
	_check(_forage_scene_cell_source(forage_scene, Vector2i(4, 4)) == Vector2i(ForageScene.STATE_DORMANT, 0),
		"sanity: a forced-empty node should render as STATE_DORMANT")
	ForagingManager.forage_node_rerolled.emit(Vector2i(4, 4), "wild_flower")
	node.item_id = "wild_flower" # the signal alone doesn't mutate node state; mirror what ForagingManager._reroll_node already did before emitting in the real flow
	forage_scene._refresh_tile(Vector2i(4, 4))
	_check(_forage_scene_cell_source(forage_scene, Vector2i(4, 4)) == Vector2i(ForageScene.STATE_AVAILABLE, 0),
		"a reroll back to an in-season item should render as STATE_AVAILABLE")
	forage_scene.queue_free()

func _test_forage_scene_click_gathers_available_tile() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var forage_scene := _make_forage_scene()
	var item_id := ForagingManager.get_forage_node(Vector2i(0, 0)).item_id
	forage_scene._handle_tile_click(Vector2i(0, 0))
	_check(InventoryManager.get_count(item_id) == 1,
		"clicking an available tile should gather it via ForagingManager.gather(), crediting InventoryManager")
	forage_scene.queue_free()

func _test_forage_scene_click_ignores_cooldown_tile() -> void:
	_reset_forage_manager()
	_reset_inventory_manager()
	TimeManager.season_index = 0 # Spring
	var forage_scene := _make_forage_scene()
	ForagingManager.get_forage_node(Vector2i(3, 3)).cooldown_days_remaining = 2
	forage_scene._handle_tile_click(Vector2i(3, 3))
	_check(InventoryManager.get_count("wild_flower") == 0 and InventoryManager.get_count("wild_berries") == 0
		and InventoryManager.get_count("spring_onion") == 0 and InventoryManager.get_count("four_leaf_clover") == 0,
		"clicking a tile on cooldown should be a no-op, not reach ForagingManager.gather()")
	forage_scene.queue_free()

func _test_forage_scene_click_ignores_out_of_grid_position() -> void:
	_reset_forage_manager()
	TimeManager.season_index = 0 # Spring
	var forage_scene := _make_forage_scene()
	forage_scene._handle_tile_click(Vector2i(-1, -1)) # outside the GRID_WIDTH x GRID_HEIGHT bounds
	_check(ForagingManager.get_forage_node(Vector2i(-1, -1)) == null,
		"a click outside the rendered grid should be a no-op, not reach ForagingManager")
	forage_scene.queue_free()

## --- Frontend: MineScene (#52 sub-scope, world/tile-rendering for
## MiningManager, design/art/isometric-grid-spec.md) ---
##
## Same discipline as the FarmScene/RanchScene/ForageScene blocks above.
## Uses generate_floor(1, <seed>) for deterministic layouts (same pattern
## the ENG-16 Mining tests above already establish), then queries
## get_ladder_position()/_first_rock_tile() rather than hardcoding
## RNG-dependent coordinates.

func _make_mine_scene() -> MineScene:
	var scene: PackedScene = load("res://scenes/world/MineScene.tscn")
	var mine_scene: MineScene = scene.instantiate()
	add_child(mine_scene)
	return mine_scene

func _mine_scene_cell_source(mine_scene: MineScene, tile: Vector2i) -> Vector2i:
	var tilemap: TileMap = mine_scene.get_node("TileMap")
	return tilemap.get_cell_atlas_coords(0, tile)

func _test_mine_scene_instantiates_without_error() -> void:
	MiningManager.generate_floor(1, 42)
	var mine_scene := _make_mine_scene()
	_check(mine_scene.get_node("TileMap") is TileMap, "MineScene should contain a TileMap node")
	_check(mine_scene.get_node("TileMap").tile_set != null, "MineScene's TileMap should have a TileSet assigned on _ready()")
	mine_scene.queue_free()

func _test_mine_scene_renders_ladder_and_rock_on_ready() -> void:
	MiningManager.generate_floor(1, 42)
	var ladder := MiningManager.get_ladder_position()
	var rock := _first_rock_tile()
	var mine_scene := _make_mine_scene()
	_check(_mine_scene_cell_source(mine_scene, ladder) == Vector2i(MineScene.STATE_LADDER, 0),
		"the ladder tile should render as STATE_LADDER on ready")
	_check(_mine_scene_cell_source(mine_scene, rock) == Vector2i(MineScene.STATE_ROCK, 0),
		"an intact rock tile should render as STATE_ROCK on ready")
	mine_scene.queue_free()

func _test_mine_scene_updates_on_rock_broken_signal() -> void:
	_reset_inventory_manager()
	SkillManager._xp = {}
	MiningManager.generate_floor(1, 42)
	var rock := _first_rock_tile()
	var mine_scene := _make_mine_scene()
	MiningManager.break_rock(rock)
	_check(_mine_scene_cell_source(mine_scene, rock) == Vector2i(MineScene.STATE_FLOOR, 0),
		"breaking a rock should reactively update the tile to STATE_FLOOR via rock_broken")
	mine_scene.queue_free()

func _test_mine_scene_updates_on_floor_descended_signal() -> void:
	MiningManager.generate_floor(1, 7)
	var mine_scene := _make_mine_scene()
	MiningManager.descend_ladder()
	var new_ladder := MiningManager.get_ladder_position()
	_check(_mine_scene_cell_source(mine_scene, new_ladder) == Vector2i(MineScene.STATE_LADDER, 0),
		"descending should reactively re-render the whole floor via floor_descended, including the new ladder position")
	mine_scene.queue_free()

func _test_mine_scene_click_breaks_rock_tile() -> void:
	_reset_inventory_manager()
	SkillManager._xp = {}
	MiningManager.generate_floor(1, 42)
	var rock := _first_rock_tile()
	var mine_scene := _make_mine_scene()
	mine_scene._handle_tile_click(rock)
	_check(not MiningManager.has_rock(rock), "clicking a rock tile should break it via MiningManager.break_rock()")
	mine_scene.queue_free()

func _test_mine_scene_click_ladder_descends() -> void:
	MiningManager.generate_floor(1, 42)
	var ladder := MiningManager.get_ladder_position()
	var starting_floor := MiningManager.floor_index
	var mine_scene := _make_mine_scene()
	mine_scene._handle_tile_click(ladder)
	_check(MiningManager.floor_index == starting_floor + 1,
		"clicking the ladder tile should descend via MiningManager.descend_ladder()")
	mine_scene.queue_free()

func _test_mine_scene_click_ignores_out_of_grid_position() -> void:
	MiningManager.generate_floor(1, 42)
	var starting_floor := MiningManager.floor_index
	var mine_scene := _make_mine_scene()
	var size := MiningManager.get_floor_size()
	mine_scene._handle_tile_click(Vector2i(size.x, size.y)) # outside the floor's own bounds
	_check(MiningManager.floor_index == starting_floor,
		"a click outside the rendered grid should be a no-op, not reach MiningManager")
	mine_scene.queue_free()

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

## --- ENG-24: Infrastructure Upgrades (InfrastructureManager) ---
##
## Content-gap honesty note (see infrastructure_manager.gd's top-of-file
## docstring): the tier costs/capacities/recipes under test here are this
## PR's own placeholder defaults, not externally-specified numbers.

func _reset_infrastructure_manager() -> void:
	var im := InfrastructureManager
	im._house_tier = InfrastructureManager.HOUSE_TIER_START
	im._coop_tier = InfrastructureManager.COOP_TIER_START
	im._built_machines = {}
	im._jobs = {}

func _reset_infra_gates() -> void:
	_reset_infrastructure_manager()
	_reset_quest_manager()
	_reset_shipping_bin()
	_reset_inventory_manager()

func _test_cannot_upgrade_house_without_quest_unlock() -> void:
	_reset_infra_gates()
	ShippingBinManager.gold = 100000
	InventoryManager.add_item("wood", 500)
	_check(not InfrastructureManager.can_upgrade_house(),
		"house tier 1 should stay locked without the quest unlock flag even with plenty of gold/material")
	_check(not InfrastructureManager.upgrade_house(), "upgrade_house should fail without the quest unlock")
	_check(InfrastructureManager.get_house_tier() == 0, "house tier should remain 0 on a failed upgrade")

func _test_cannot_upgrade_house_without_material() -> void:
	_reset_infra_gates()
	QuestManager._unlocked_flags["house_tier_1_unlocked"] = true
	ShippingBinManager.gold = 100000
	_check(not InfrastructureManager.can_upgrade_house(),
		"house tier 1 should stay locked without enough material even when quest-unlocked and gold-rich")
	_check(not InfrastructureManager.upgrade_house(), "upgrade_house should fail without enough material")

func _test_cannot_upgrade_house_without_gold() -> void:
	_reset_infra_gates()
	QuestManager._unlocked_flags["house_tier_1_unlocked"] = true
	InventoryManager.add_item("wood", 500)
	ShippingBinManager.gold = 0
	_check(not InfrastructureManager.can_upgrade_house(), "house tier 1 should stay locked without enough gold")
	_check(not InfrastructureManager.upgrade_house(), "upgrade_house should fail without enough gold")

func _test_house_upgrade_succeeds_and_deducts_costs() -> void:
	_reset_infra_gates()
	QuestManager._unlocked_flags["house_tier_1_unlocked"] = true
	ShippingBinManager.gold = 5000
	InventoryManager.add_item("wood", 500)
	_check(not InfrastructureManager.is_cooking_unlocked(), "cooking should be locked before any house tier is reached")

	var ok := InfrastructureManager.upgrade_house()
	_check(ok, "upgrade_house should succeed once quest-unlocked and affordable")
	_check(InfrastructureManager.get_house_tier() == 1, "house tier should advance to 1, got %d" % InfrastructureManager.get_house_tier())
	_check(ShippingBinManager.gold == 4000, "gold should be deducted by tier 1's cost, got %d" % ShippingBinManager.gold)
	_check(InventoryManager.get_count("wood") == 450, "material should be deducted by tier 1's cost, got %d" % InventoryManager.get_count("wood"))
	_check(InfrastructureManager.is_cooking_unlocked(), "cooking should be unlocked once house tier 1 is reached")

func _test_coop_capacity_starts_at_base_and_increases_per_tier() -> void:
	_reset_infra_gates()
	_check(InfrastructureManager.get_max_animal_capacity() == InfrastructureManager.BASE_ANIMAL_CAPACITY,
		"unupgraded coop should report the base capacity, got %d" % InfrastructureManager.get_max_animal_capacity())

	QuestManager._unlocked_flags["coop_tier_1_unlocked"] = true
	ShippingBinManager.gold = 5000
	InventoryManager.add_item("wood", 500)
	InfrastructureManager.upgrade_coop()
	_check(InfrastructureManager.get_max_animal_capacity() == 8,
		"coop tier 1 should raise max capacity to 8, got %d" % InfrastructureManager.get_max_animal_capacity())

func _test_cannot_build_machine_without_quest_unlock() -> void:
	_reset_infra_gates()
	ShippingBinManager.gold = 100000
	InventoryManager.add_item("wood", 500)
	_check(not InfrastructureManager.can_build_machine("keg"), "keg should stay locked without its quest unlock flag")
	_check(not InfrastructureManager.build_machine("keg"), "build_machine should fail without the quest unlock")
	_check(not InfrastructureManager.is_machine_built("keg"), "keg should not be marked built on a failed build")

func _test_build_machine_succeeds_and_deducts_costs() -> void:
	_reset_infra_gates()
	QuestManager._unlocked_flags["keg_unlocked"] = true
	ShippingBinManager.gold = 5000
	InventoryManager.add_item("wood", 500)

	var ok := InfrastructureManager.build_machine("keg")
	_check(ok, "build_machine should succeed once quest-unlocked and affordable")
	_check(InfrastructureManager.is_machine_built("keg"), "keg should be marked built after a successful build")
	_check(ShippingBinManager.gold == 4700, "gold should be deducted by the keg's build cost, got %d" % ShippingBinManager.gold)
	_check(InventoryManager.get_count("wood") == 480, "material should be deducted by the keg's build cost, got %d" % InventoryManager.get_count("wood"))

func _test_start_job_fails_without_machine_built() -> void:
	_reset_infra_gates()
	InventoryManager.add_item("fruit", 10)
	_check(not InfrastructureManager.start_job("job1", "keg"), "start_job should fail if the keg isn't built yet")

func _build_keg_for_test() -> void:
	QuestManager._unlocked_flags["keg_unlocked"] = true
	ShippingBinManager.gold = 5000
	InventoryManager.add_item("wood", 500)
	InfrastructureManager.build_machine("keg")

func _test_start_job_fails_without_enough_input() -> void:
	_reset_infra_gates()
	_build_keg_for_test()
	_check(not InfrastructureManager.start_job("job1", "keg"), "start_job should fail without the raw ingredient on hand")

func _test_start_job_consumes_input_and_ticks_to_ready() -> void:
	_reset_infra_gates()
	_build_keg_for_test()
	InventoryManager.add_item("fruit", 3)

	var ok := InfrastructureManager.start_job("job1", "keg")
	_check(ok, "start_job should succeed with the machine built and input on hand")
	_check(InventoryManager.get_count("fruit") == 2, "starting a job should consume the recipe's input quantity, got %d" % InventoryManager.get_count("fruit"))
	_check(not InfrastructureManager.is_job_ready("job1"), "a freshly started keg job (3-day recipe) should not be ready immediately")

	InfrastructureManager._on_day_started(1, "Spring", "Mon")
	InfrastructureManager._on_day_started(2, "Spring", "Tue")
	_check(not InfrastructureManager.is_job_ready("job1"), "keg job should not be ready after only 2 of 3 days")

	InfrastructureManager._on_day_started(3, "Spring", "Wed")
	_check(InfrastructureManager.is_job_ready("job1"), "keg job should be ready after 3 days")

	var result := InfrastructureManager.collect_job("job1")
	_check(result.get("output_item_id") == "wine" and result.get("output_quantity") == 1,
		"collecting a ready keg job should report the wine output, got %s" % [result])
	_check(InventoryManager.get_count("wine") == 1, "collecting should credit InventoryManager with the output, got %d" % InventoryManager.get_count("wine"))
	_check(InfrastructureManager.list_job_ids().is_empty(), "collecting should remove the job from the active list")

func _test_collect_job_before_ready_returns_empty() -> void:
	_reset_infra_gates()
	_build_keg_for_test()
	InventoryManager.add_item("fruit", 3)
	InfrastructureManager.start_job("job1", "keg")
	var result := InfrastructureManager.collect_job("job1")
	_check(result.is_empty(), "collecting before a job is ready should return an empty dict")
	_check(InventoryManager.get_count("wine") == 0, "collecting an unready job should not credit any output")

func _test_start_job_rejects_duplicate_job_id() -> void:
	_reset_infra_gates()
	_build_keg_for_test()
	InventoryManager.add_item("fruit", 3)
	InfrastructureManager.start_job("job1", "keg")
	_check(not InfrastructureManager.start_job("job1", "keg"), "starting a job with an already-active job_id should fail")

func _test_infrastructure_save_round_trip() -> void:
	_reset_infra_gates()
	QuestManager._unlocked_flags["house_tier_1_unlocked"] = true
	ShippingBinManager.gold = 5000
	InventoryManager.add_item("wood", 500)
	InfrastructureManager.upgrade_house()
	_build_keg_for_test()
	InventoryManager.add_item("fruit", 3)
	InfrastructureManager.start_job("job1", "keg")

	var saved := SaveManager.build_save_data()

	_reset_infrastructure_manager()
	_check(InfrastructureManager.get_house_tier() == 0, "sanity: reset should clear house tier before applying save data")
	_check(not InfrastructureManager.is_machine_built("keg"), "sanity: reset should clear built machines before applying save data")

	SaveManager.apply_save_data(saved)

	_check(InfrastructureManager.get_house_tier() == 1, "house tier should round-trip through save/load, got %d" % InfrastructureManager.get_house_tier())
	_check(InfrastructureManager.is_machine_built("keg"), "built machines should round-trip through save/load")
	_check(not InfrastructureManager.is_job_ready("job1"), "sanity: job should still be pending after round-trip")
	_check(InfrastructureManager.get_job("job1").get("days_remaining") == 3,
		"active job progress should round-trip through save/load, got %s" % [InfrastructureManager.get_job("job1")])
## --- ENG-20: Marriage & Family ---

func _reset_marriage_manager() -> void:
	var mm := MarriageManager
	mm._engaged_to = ""
	mm._days_until_wedding = 0
	mm._spouse = ""
	mm._children = 0

func _make_elena_eligible() -> void:
	_reset_relationship_manager()
	_reset_inventory_manager()
	RelationshipManager._add_points("Elena", RelationshipManager.POINTS_PER_HEART * MarriageManager.PROPOSAL_HEART_THRESHOLD)
	InventoryManager.add_item(MarriageManager.PROPOSAL_ITEM_ID, 1)

func _on_proposal_rejected_for_test(npc_name: String, reason: String) -> void:
	_proposal_rejected_events.append([npc_name, reason])

func _on_wedding_scheduled_for_test(npc_name: String, days_until: int) -> void:
	_wedding_scheduled_events.append([npc_name, days_until])

func _on_married_for_test(npc_name: String) -> void:
	_married_events.append(npc_name)

func _on_child_born_for_test(npc_name: String, total_children: int) -> void:
	_child_born_events.append([npc_name, total_children])

func _test_marriage_cannot_propose_ineligible_npc() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	_check(not MarriageManager.is_marriageable("NotAnNPC"), "an unlisted npc_name should not be marriageable")

	_proposal_rejected_events = []
	MarriageManager.proposal_rejected.connect(_on_proposal_rejected_for_test)
	var ok := MarriageManager.propose("NotAnNPC")
	MarriageManager.proposal_rejected.disconnect(_on_proposal_rejected_for_test)

	_check(not ok, "proposing to a non-marriageable NPC should fail")
	_check(_proposal_rejected_events.size() == 1 and _proposal_rejected_events[0] == ["NotAnNPC", "not_marriageable"],
		"proposal_rejected should fire with reason 'not_marriageable', got %s" % [_proposal_rejected_events])
	_check(InventoryManager.get_count(MarriageManager.PROPOSAL_ITEM_ID) == 1,
		"a rejected proposal must not consume the proposal item")

func _test_marriage_cannot_propose_without_enough_hearts() -> void:
	_reset_marriage_manager()
	_reset_relationship_manager()
	_reset_inventory_manager()
	InventoryManager.add_item(MarriageManager.PROPOSAL_ITEM_ID, 1)
	RelationshipManager._add_points("Elena", RelationshipManager.POINTS_PER_HEART) # far below threshold

	_check(not MarriageManager.can_propose("Elena"), "can_propose should be false below the heart threshold")
	var ok := MarriageManager.propose("Elena")
	_check(not ok, "propose should fail below the heart threshold")
	_check(InventoryManager.get_count(MarriageManager.PROPOSAL_ITEM_ID) == 1,
		"a failed heart-threshold proposal must not consume the item")

func _test_marriage_cannot_propose_without_item() -> void:
	_reset_marriage_manager()
	_reset_relationship_manager()
	_reset_inventory_manager()
	RelationshipManager._add_points("Elena", RelationshipManager.POINTS_PER_HEART * MarriageManager.PROPOSAL_HEART_THRESHOLD)

	_check(not MarriageManager.can_propose("Elena"), "can_propose should be false without the proposal item")
	var ok := MarriageManager.propose("Elena")
	_check(not ok, "propose should fail without the proposal item on hand")

func _test_marriage_propose_consumes_item_and_schedules_wedding() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	_check(MarriageManager.can_propose("Elena"), "sanity: can_propose should be true once eligible")

	_wedding_scheduled_events = []
	MarriageManager.wedding_scheduled.connect(_on_wedding_scheduled_for_test)
	var ok := MarriageManager.propose("Elena")
	MarriageManager.wedding_scheduled.disconnect(_on_wedding_scheduled_for_test)

	_check(ok, "propose should succeed once eligible")
	_check(InventoryManager.get_count(MarriageManager.PROPOSAL_ITEM_ID) == 0,
		"a successful proposal should consume the proposal item")
	_check(MarriageManager.is_engaged() and MarriageManager.engaged_to() == "Elena",
		"a successful proposal should engage the player to that NPC")
	_check(MarriageManager.days_until_wedding() == MarriageManager.WEDDING_PREP_DAYS,
		"wedding should be scheduled WEDDING_PREP_DAYS out, got %d" % MarriageManager.days_until_wedding())
	_check(_wedding_scheduled_events.size() == 1 and _wedding_scheduled_events[0] == ["Elena", MarriageManager.WEDDING_PREP_DAYS],
		"wedding_scheduled should fire once with (npc_name, days_until), got %s" % [_wedding_scheduled_events])
	_check(not MarriageManager.is_married(), "player should not be married yet, only engaged")

func _test_marriage_cannot_propose_twice_while_engaged() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	MarriageManager.propose("Elena")

	InventoryManager.add_item(MarriageManager.PROPOSAL_ITEM_ID, 1)
	RelationshipManager._add_points("Marcus", RelationshipManager.POINTS_PER_HEART * MarriageManager.PROPOSAL_HEART_THRESHOLD)
	var ok := MarriageManager.propose("Marcus")
	_check(not ok, "proposing to a second NPC while already engaged should fail")
	_check(MarriageManager.engaged_to() == "Elena", "the original engagement should remain unchanged")

func _test_marriage_wedding_countdown_finalizes_marriage() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	MarriageManager.propose("Elena")

	_married_events = []
	MarriageManager.married.connect(_on_married_for_test)
	for i in range(MarriageManager.WEDDING_PREP_DAYS):
		_check(not MarriageManager.is_married(), "should not be married before the countdown finishes (day %d)" % i)
		MarriageManager._on_day_started(i + 1, "Spring", "Mon")
	MarriageManager.married.disconnect(_on_married_for_test)

	_check(MarriageManager.is_married() and MarriageManager.spouse_name() == "Elena",
		"marriage should finalize once the wedding countdown reaches zero")
	_check(not MarriageManager.is_engaged(), "engaged state should clear once married")
	_check(_married_events.size() == 1 and _married_events[0] == "Elena",
		"married should fire exactly once with the spouse's name, got %s" % [_married_events])

func _test_marriage_marry_directly_for_ceremony_scene_hook() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	MarriageManager.propose("Elena")

	var ok := MarriageManager.marry("Elena")
	_check(ok, "marry() should let a future ceremony scene finalize the marriage directly, independent of the day countdown")
	_check(MarriageManager.is_married() and MarriageManager.spouse_name() == "Elena",
		"marry() should set married state and spouse_name to the proposed NPC")

	var bad := MarriageManager.marry("Marcus")
	_check(not bad, "marry() for an NPC that isn't the current engagement should fail")

func _test_marriage_daily_gold_bonus_only_when_married() -> void:
	_reset_marriage_manager()
	_check(MarriageManager.daily_gold_bonus() == 0, "unmarried should have no daily gold bonus")

	_make_elena_eligible()
	MarriageManager.propose("Elena")
	_check(MarriageManager.daily_gold_bonus() == 0, "engaged-but-not-married should have no daily gold bonus yet")

	MarriageManager.marry("Elena")
	_check(MarriageManager.daily_gold_bonus() == MarriageManager.MARRIED_DAILY_GOLD_BONUS,
		"married should grant MARRIED_DAILY_GOLD_BONUS, got %d" % MarriageManager.daily_gold_bonus())

func _test_marriage_child_born_rolls_once_per_season_start() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	MarriageManager.propose("Elena")
	MarriageManager.marry("Elena")

	_child_born_events = []
	MarriageManager.child_born.connect(_on_child_born_for_test)
	seed(1) # deterministic randf() sequence for this test
	MarriageManager._on_day_started(1, "Summer", "Mon") # season start, chance rolled
	MarriageManager._on_day_started(2, "Summer", "Tue") # not a season start, no roll
	MarriageManager.child_born.disconnect(_on_child_born_for_test)

	_check(MarriageManager.children_count() <= MarriageManager.MAX_CHILDREN,
		"children_count should never exceed MAX_CHILDREN, got %d" % MarriageManager.children_count())
	_check(_child_born_events.size() == MarriageManager.children_count(),
		"child_born should fire exactly once per child actually added, got %d events for %d children"
			% [_child_born_events.size(), MarriageManager.children_count()])

func _test_marriage_save_round_trip() -> void:
	_reset_marriage_manager()
	_make_elena_eligible()
	MarriageManager.propose("Elena")
	MarriageManager.marry("Elena")
	MarriageManager._children = 2

	var saved := SaveManager.build_save_data()

	_reset_marriage_manager()
	_check(not MarriageManager.is_married(), "sanity check: reset should clear marriage state before applying save data")

	SaveManager.apply_save_data(saved)

	_check(MarriageManager.is_married() and MarriageManager.spouse_name() == "Elena",
		"marriage status should round-trip through save/load")
	_check(MarriageManager.children_count() == 2,
		"children count should round-trip through save/load, got %d" % MarriageManager.children_count())
	_check(not MarriageManager.is_engaged(), "engaged state should round-trip as cleared once already married")
## --- ENG-21: Festivals ---

func _reset_festival_manager() -> void:
	var fm := FestivalManager
	fm._active_festival_id = ""
	TimeManager.unfreeze(FestivalManager.FREEZE_REASON)

func _on_festival_started_for_test(festival_id: String) -> void:
	_festival_started_events.append(festival_id)

func _on_festival_ended_for_test(festival_id: String) -> void:
	_festival_ended_events.append(festival_id)

func _on_mini_game_result_for_test(festival_id: String, score: float, success: bool) -> void:
	_mini_game_result_events.append([festival_id, score, success])

func _test_is_festival_day_matches_registered_date() -> void:
	_reset_festival_manager()
	var tm := TimeManager
	tm.season_index = 0 # Spring
	tm.day_in_season = 13 # bloomtide_fair's registered date
	_check(FestivalManager.is_festival_day(), "day 13 of Spring should be a registered festival day")

func _test_get_festival_for_date_returns_null_off_date() -> void:
	_reset_festival_manager()
	var def := FestivalManager.get_festival_for_date("Spring", 1)
	_check(def == null, "an unregistered season/day combo should return null, got %s" % [def])

func _test_start_festival_freezes_time_and_emits() -> void:
	_reset_festival_manager()
	_festival_started_events = []
	FestivalManager.festival_started.connect(_on_festival_started_for_test)
	var ok := FestivalManager.start_festival("bloomtide_fair")
	FestivalManager.festival_started.disconnect(_on_festival_started_for_test)

	_check(ok, "starting a registered festival should succeed")
	_check(TimeManager.is_frozen(), "starting a festival should freeze TimeManager")
	_check(FestivalManager.is_festival_active(), "starting a festival should mark it active")
	_check(FestivalManager.get_active_festival() != null
		and FestivalManager.get_active_festival().festival_id == "bloomtide_fair",
		"get_active_festival should return the started festival's definition")
	_check(_festival_started_events == ["bloomtide_fair"],
		"festival_started should fire once with the started festival_id, got %s" % [_festival_started_events]
	)
	_reset_festival_manager()

func _test_start_festival_unregistered_id_fails() -> void:
	_reset_festival_manager()
	var ok := FestivalManager.start_festival("nonexistent_festival")
	_check(not ok, "starting an unregistered festival_id should fail")
	_check(not FestivalManager.is_festival_active(), "an unregistered start attempt should not mark anything active")
	_check(not TimeManager.is_frozen(), "an unregistered start attempt should not freeze TimeManager")

func _test_start_festival_while_another_active_fails() -> void:
	_reset_festival_manager()
	FestivalManager.start_festival("bloomtide_fair")
	var ok := FestivalManager.start_festival("sunfield_revel")
	_check(not ok, "starting a second festival while one is already active should fail")
	_check(FestivalManager.get_active_festival().festival_id == "bloomtide_fair",
		"the originally active festival should remain active")
	_reset_festival_manager()

func _test_start_festival_idempotent_for_same_id() -> void:
	_reset_festival_manager()
	FestivalManager.start_festival("bloomtide_fair")
	var ok := FestivalManager.start_festival("bloomtide_fair")
	_check(ok, "re-starting the already-active festival with the same id should succeed (idempotent)")
	_reset_festival_manager()

func _test_end_festival_unfreezes_time_and_emits() -> void:
	_reset_festival_manager()
	FestivalManager.start_festival("sunfield_revel")
	_festival_ended_events = []
	FestivalManager.festival_ended.connect(_on_festival_ended_for_test)
	FestivalManager.end_festival()
	FestivalManager.festival_ended.disconnect(_on_festival_ended_for_test)

	_check(not TimeManager.is_frozen(), "ending the festival should unfreeze TimeManager")
	_check(not FestivalManager.is_festival_active(), "ending the festival should clear the active festival")
	_check(_festival_ended_events == ["sunfield_revel"],
		"festival_ended should fire once with the ended festival_id, got %s" % [_festival_ended_events])

func _test_end_festival_noop_when_none_active() -> void:
	_reset_festival_manager()
	_festival_ended_events = []
	FestivalManager.festival_ended.connect(_on_festival_ended_for_test)
	FestivalManager.end_festival()
	FestivalManager.festival_ended.disconnect(_on_festival_ended_for_test)
	_check(_festival_ended_events.is_empty(), "ending with no active festival should not emit festival_ended")

func _test_day_started_auto_triggers_registered_festival() -> void:
	_reset_festival_manager()
	TimeManager.season_index = 2 # Fall
	TimeManager.day_in_season = 16 # harvest_moon_festival's registered date
	FestivalManager._on_day_started(16, "Fall", "Mon")
	_check(FestivalManager.is_festival_active()
		and FestivalManager.get_active_festival().festival_id == "harvest_moon_festival",
		"day_started on a registered festival's date should auto-start it")
	_reset_festival_manager()

func _test_day_started_does_not_trigger_on_non_festival_day() -> void:
	_reset_festival_manager()
	FestivalManager._on_day_started(1, "Spring", "Mon") # day 1 has no registered festival
	_check(not FestivalManager.is_festival_active(), "day_started on a non-festival date should not start anything")

func _test_submit_mini_game_result_unregistered_returns_empty() -> void:
	var result := FestivalManager.submit_mini_game_result("nonexistent_festival", 0.9)
	_check(result.is_empty(), "submit_mini_game_result for an unregistered festival_id should return {}")

func _test_submit_mini_game_result_pass_and_fail() -> void:
	_mini_game_result_events = []
	FestivalManager.mini_game_result_submitted.connect(_on_mini_game_result_for_test)

	var pass_result := FestivalManager.submit_mini_game_result("sunfield_revel", 0.75)
	_check(pass_result["success"], "score above the pass threshold should succeed, got %s" % [pass_result])

	var fail_result := FestivalManager.submit_mini_game_result("sunfield_revel", 0.1)
	_check(not fail_result["success"], "score below the pass threshold should fail, got %s" % [fail_result])

	FestivalManager.mini_game_result_submitted.disconnect(_on_mini_game_result_for_test)
	_check(_mini_game_result_events.size() == 2
		and _mini_game_result_events[0] == ["sunfield_revel", 0.75, true]
		and _mini_game_result_events[1] == ["sunfield_revel", 0.1, false],
		"mini_game_result_submitted should fire once per call with (festival_id, score, success), got %s" % [_mini_game_result_events])

## --- ENG-16: Mining (MiningManager) ---

func _first_rock_tile() -> Vector2i:
	var size := MiningManager.get_floor_size()
	for x in size.x:
		for y in size.y:
			var tile := Vector2i(x, y)
			if MiningManager.has_rock(tile):
				return tile
	return Vector2i(-1, -1)

func _test_generate_floor_places_ladder_without_rock() -> void:
	MiningManager.generate_floor(1, 42)
	var ladder := MiningManager.get_ladder_position()
	var size := MiningManager.get_floor_size()
	_check(ladder.x >= 0 and ladder.x < size.x and ladder.y >= 0 and ladder.y < size.y,
		"ladder position should be within floor bounds, got %s (size %s)" % [ladder, size])
	_check(not MiningManager.has_rock(ladder),
		"the ladder tile should never have a rock, got has_rock=%s" % MiningManager.has_rock(ladder))

func _test_generate_floor_all_other_tiles_start_as_unbroken_rock() -> void:
	MiningManager.generate_floor(1, 42)
	var ladder := MiningManager.get_ladder_position()
	var size := MiningManager.get_floor_size()
	var rock_count := 0
	for x in size.x:
		for y in size.y:
			var tile := Vector2i(x, y)
			if tile == ladder:
				continue
			if MiningManager.has_rock(tile):
				rock_count += 1
	_check(rock_count == size.x * size.y - 1,
		"every non-ladder tile should start as an intact rock, got %d/%d" % [rock_count, size.x * size.y - 1])

func _test_break_rock_credits_stone_or_ore_and_xp() -> void:
	_reset_inventory_manager()
	SkillManager._xp = {}
	MiningManager.generate_floor(1, 42)
	var tile := _first_rock_tile()

	var result := MiningManager.break_rock(tile)
	_check(not result.is_empty(), "breaking an intact rock should succeed")
	var item_id: String = result["item_id"]
	_check(item_id == MiningManager.STONE_ITEM_ID or item_id in ["copper_ore", "iron_ore"],
		"floor 1 should only yield stone, copper_ore, or iron_ore, got %s" % item_id)
	_check(InventoryManager.get_count(item_id) == int(result["quantity"]),
		"break_rock should credit InventoryManager with the returned item/quantity, got %d" % InventoryManager.get_count(item_id))
	_check(SkillManager.get_xp("Mining") > 0, "breaking a rock should credit Mining XP, got %d" % SkillManager.get_xp("Mining"))
	_check(not MiningManager.has_rock(tile), "a broken tile should no longer report has_rock")

func _test_break_rock_twice_returns_empty_second_time() -> void:
	MiningManager.generate_floor(1, 7)
	var tile := _first_rock_tile()
	MiningManager.break_rock(tile)
	var second := MiningManager.break_rock(tile)
	_check(second.is_empty(), "breaking an already-broken tile should return an empty dict")

func _test_break_rock_on_ladder_tile_returns_empty() -> void:
	MiningManager.generate_floor(1, 7)
	var ladder := MiningManager.get_ladder_position()
	var result := MiningManager.break_rock(ladder)
	_check(result.is_empty(), "breaking the ladder tile (no rock there) should return an empty dict")

func _test_roll_ore_respects_min_floor_gating() -> void:
	for i in range(30):
		var ore1: String = MiningManager._roll_ore(1)
		_check(ore1 in ["copper_ore", "iron_ore"],
			"floor 1 rolls should only surface copper_ore/iron_ore (min_floor 1), got %s" % ore1)

	var saw_gold_or_diamond := false
	for i in range(50):
		var ore2: String = MiningManager._roll_ore(6)
		if ore2 in ["gold_ore", "diamond"]:
			saw_gold_or_diamond = true
	_check(saw_gold_or_diamond,
		"floor 6 rolls should be able to surface gold_ore/diamond (min_floor 3/5) across enough samples")

func _test_descend_ladder_advances_floor_and_regenerates() -> void:
	MiningManager.generate_floor(1, 42)
	var tile := _first_rock_tile()
	MiningManager.break_rock(tile)
	_check(not MiningManager.has_rock(tile), "sanity: tile should be broken before descending")

	var floor_before: int = MiningManager.floor_index
	var ok := MiningManager.descend_ladder()
	_check(ok, "descend_ladder should succeed")
	_check(MiningManager.floor_index == floor_before + 1,
		"descending should increment floor_index, got %d -> %d" % [floor_before, MiningManager.floor_index])
	_check(MiningManager.has_rock(tile) or tile == MiningManager.get_ladder_position(),
		"the new floor should regenerate tile state (previously-broken tile should be intact again unless it's the new ladder), got has_rock=%s" % MiningManager.has_rock(tile))

func _test_mining_save_round_trip() -> void:
	MiningManager.generate_floor(2, 99)
	var tile := _first_rock_tile()
	MiningManager.break_rock(tile)
	var floor_before: int = MiningManager.floor_index

	var saved := SaveManager.build_save_data()

	MiningManager.generate_floor(1, 1) # perturb state before reload
	_check(MiningManager.floor_index == 1, "sanity check: perturbing should change floor_index before applying save data")

	SaveManager.apply_save_data(saved)

	_check(MiningManager.floor_index == floor_before,
		"floor_index should round-trip through save/load, got %d" % MiningManager.floor_index)
	_check(not MiningManager.has_rock(tile), "the broken tile's state should round-trip through save/load")

## --- ENG-27: Ultimate-goal structure (Community Goal bundles) ---

func _on_bundle_contribution_added_for_test(bundle_id: String, item_id: String, quantity: int) -> void:
	_bundle_contribution_events.append([bundle_id, item_id, quantity])

func _on_bundle_completed_for_test(bundle_id: String) -> void:
	_bundle_completed_events.append(bundle_id)

func _on_year_three_evaluation_for_test(challenge_mode: bool, completed: int, total: int, passed: bool) -> void:
	_year_three_evaluation_events.append([challenge_mode, completed, total, passed])

func _on_game_over_for_test(reason: String) -> void:
	_game_over_events.append(reason)

## Resets CommunityGoalManager to a fresh-boot-equivalent state without
## touching InventoryManager -- individual tests reset InventoryManager
## themselves via _reset_inventory_manager() when they need clean stock.
func _reset_community_goal_manager() -> void:
	CommunityGoalManager.challenge_mode = false
	CommunityGoalManager._bundles = {}
	CommunityGoalManager._contributions = {}
	CommunityGoalManager._completed = {}
	CommunityGoalManager._evaluation_fired = false
	CommunityGoalManager._is_game_over = false
	CommunityGoalManager._register_default_content()

func _test_bundle_registration_preserves_progress_on_reregister() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 5)
	CommunityGoalManager.contribute_item("pantry_bundle", "parsnip", 2)
	_check(CommunityGoalManager.contributed_count("pantry_bundle", "parsnip") == 2,
		"sanity: contribution should be recorded before re-registration")

	CommunityGoalManager.register_bundle(CommunityGoalManager._make_bundle(
		"pantry_bundle", "Pantry Bundle", {"parsnip": 3, "tomato": 2, "pumpkin": 1}))

	_check(CommunityGoalManager.contributed_count("pantry_bundle", "parsnip") == 2,
		"re-registering an already-known bundle_id should preserve existing contribution progress, got %d" \
		% CommunityGoalManager.contributed_count("pantry_bundle", "parsnip"))
	_check(not CommunityGoalManager.is_bundle_complete("pantry_bundle"),
		"re-registration should not falsely mark an incomplete bundle complete")

func _test_contribute_item_success_and_clamps_to_remaining() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 10)
	_bundle_contribution_events = []
	CommunityGoalManager.bundle_contribution_added.connect(_on_bundle_contribution_added_for_test)

	var ok := CommunityGoalManager.contribute_item("pantry_bundle", "parsnip", 10)
	CommunityGoalManager.bundle_contribution_added.disconnect(_on_bundle_contribution_added_for_test)

	_check(ok, "contributing to a valid bundle/item should succeed")
	_check(CommunityGoalManager.contributed_count("pantry_bundle", "parsnip") == 3,
		"contribution should clamp to the 3 parsnip pantry_bundle actually requires, got %d" \
		% CommunityGoalManager.contributed_count("pantry_bundle", "parsnip"))
	_check(InventoryManager.get_count("parsnip") == 7,
		"only the clamped amount (3) should be removed from inventory, 10 - 3 = 7 expected, got %d" \
		% InventoryManager.get_count("parsnip"))
	_check(_bundle_contribution_events.size() == 1 and _bundle_contribution_events[0] == ["pantry_bundle", "parsnip", 3],
		"bundle_contribution_added should fire once with the clamped quantity, got %s" % [_bundle_contribution_events])

func _test_contribute_item_fails_unknown_bundle() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 5)
	var ok := CommunityGoalManager.contribute_item("no_such_bundle", "parsnip", 1)
	_check(not ok, "contributing to an unregistered bundle_id should fail")
	_check(InventoryManager.get_count("parsnip") == 5,
		"a failed contribution must not remove anything from inventory")

func _test_contribute_item_fails_bundle_not_owning_item() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("copper_ore", 5)
	var ok := CommunityGoalManager.contribute_item("pantry_bundle", "copper_ore", 1)
	_check(not ok, "contributing an item_id the bundle doesn't require should fail")
	_check(InventoryManager.get_count("copper_ore") == 5,
		"a failed contribution must not remove anything from inventory")

func _test_contribute_item_fails_insufficient_inventory_stock() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 1)
	var ok := CommunityGoalManager.contribute_item("pantry_bundle", "parsnip", 3)
	_check(not ok, "contributing more than InventoryManager actually has should fail")
	_check(InventoryManager.get_count("parsnip") == 1,
		"a failed contribution due to insufficient stock must not partially remove inventory, got %d" \
		% InventoryManager.get_count("parsnip"))
	_check(CommunityGoalManager.contributed_count("pantry_bundle", "parsnip") == 0,
		"a failed contribution must not credit any progress")

func _test_contribute_item_fails_once_bundle_complete() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 10)
	InventoryManager.add_item("tomato", 10)
	InventoryManager.add_item("pumpkin", 10)
	CommunityGoalManager.contribute_item("pantry_bundle", "parsnip", 3)
	CommunityGoalManager.contribute_item("pantry_bundle", "tomato", 2)
	CommunityGoalManager.contribute_item("pantry_bundle", "pumpkin", 1)
	_check(CommunityGoalManager.is_bundle_complete("pantry_bundle"), "sanity: bundle should be complete now")

	var ok := CommunityGoalManager.contribute_item("pantry_bundle", "parsnip", 1)
	_check(not ok, "contributing to an already-complete bundle should fail")
	_check(InventoryManager.get_count("parsnip") == 7,
		"a rejected post-completion contribution must not remove anything further from inventory, got %d" \
		% InventoryManager.get_count("parsnip"))

func _test_bundle_completion_fires_signal_once() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("egg", 10)
	InventoryManager.add_item("milk", 10)
	InventoryManager.add_item("wool", 10)
	_bundle_completed_events = []
	CommunityGoalManager.bundle_completed.connect(_on_bundle_completed_for_test)

	CommunityGoalManager.contribute_item("coop_bundle", "egg", 3)
	_check(_bundle_completed_events.is_empty(), "bundle_completed should not fire before every required item is met")
	CommunityGoalManager.contribute_item("coop_bundle", "milk", 2)
	CommunityGoalManager.contribute_item("coop_bundle", "wool", 2)

	CommunityGoalManager.bundle_completed.disconnect(_on_bundle_completed_for_test)

	_check(_bundle_completed_events == ["coop_bundle"],
		"bundle_completed should fire exactly once for coop_bundle once all required items are met, got %s" \
		% [_bundle_completed_events])

func _test_year_three_evaluation_open_ended_is_non_terminal() -> void:
	_reset_community_goal_manager()
	CommunityGoalManager.challenge_mode = false
	_year_three_evaluation_events = []
	_game_over_events = []
	CommunityGoalManager.year_three_evaluation.connect(_on_year_three_evaluation_for_test)
	CommunityGoalManager.game_over.connect(_on_game_over_for_test)

	CommunityGoalManager._on_day_started(1, "Spring", "Mon")
	# not year 3 yet -- should be a no-op
	_check(_year_three_evaluation_events.is_empty(), "day_started before year 3 spring day 1 should not fire the evaluation")

	TimeManager.year = 3
	CommunityGoalManager._on_day_started(1, "Spring", "Mon")

	CommunityGoalManager.year_three_evaluation.disconnect(_on_year_three_evaluation_for_test)
	CommunityGoalManager.game_over.disconnect(_on_game_over_for_test)
	TimeManager.year = 1

	_check(_year_three_evaluation_events.size() == 1 and _year_three_evaluation_events[0][0] == false \
		and _year_three_evaluation_events[0][3] == true,
		"open-ended mode (challenge_mode=false) should fire year_three_evaluation as a non-terminal, always-passed beat, got %s" \
		% [_year_three_evaluation_events])
	_check(_game_over_events.is_empty(), "open-ended mode should never emit game_over")
	_check(not CommunityGoalManager.is_game_over(), "open-ended mode should never flip is_game_over()")

func _test_year_three_evaluation_challenge_mode_pass() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	CommunityGoalManager.challenge_mode = true
	for bundle_id_and_items in [
		["pantry_bundle", {"parsnip": 3, "tomato": 2, "pumpkin": 1}],
		["coop_bundle", {"egg": 3, "milk": 2, "wool": 2}],
		["fish_tank_bundle", {"carp": 2, "trout": 1, "salmon": 1}],
		["boiler_room_bundle", {"copper_ore": 5, "iron_ore": 3, "gold_ore": 1}],
		["forager_bundle", {"wild_berries": 3, "mushroom": 2, "snow_truffle": 1}],
		["orchard_bundle", {"melon": 2, "corn": 3, "cauliflower": 2}],
		["deluxe_coop_bundle", {"duck_egg": 3, "goat_milk": 2}],
		["night_anglers_bundle", {"bream": 2, "bass": 2, "eel": 1}],
		["forager_reserve_bundle", {"spring_onion": 3, "sweet_pea": 3, "hazelnut": 2, "winter_root": 2}],
		["vault_bundle", {"diamond": 3}],
	]:
		var bundle_id: String = bundle_id_and_items[0]
		var items: Dictionary = bundle_id_and_items[1]
		for item_id in items.keys():
			var qty: int = items[item_id]
			InventoryManager.add_item(item_id, qty)
			CommunityGoalManager.contribute_item(bundle_id, item_id, qty)
	_check(CommunityGoalManager.all_bundles_completed(), "sanity: every bundle should be complete before the pass-path evaluation")

	_year_three_evaluation_events = []
	_game_over_events = []
	CommunityGoalManager.year_three_evaluation.connect(_on_year_three_evaluation_for_test)
	CommunityGoalManager.game_over.connect(_on_game_over_for_test)

	TimeManager.year = 3
	CommunityGoalManager._on_day_started(1, "Spring", "Mon")

	CommunityGoalManager.year_three_evaluation.disconnect(_on_year_three_evaluation_for_test)
	CommunityGoalManager.game_over.disconnect(_on_game_over_for_test)
	TimeManager.year = 1

	_check(_year_three_evaluation_events.size() == 1 and _year_three_evaluation_events[0][3] == true,
		"challenge_mode with every bundle complete should evaluate as passed, got %s" % [_year_three_evaluation_events])
	_check(_game_over_events.is_empty(), "a passing challenge-mode evaluation should not emit game_over")
	_check(not CommunityGoalManager.is_game_over(), "a passing challenge-mode evaluation should not flip is_game_over()")

func _test_year_three_evaluation_challenge_mode_fail_triggers_game_over() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	CommunityGoalManager.challenge_mode = true
	_check(not CommunityGoalManager.all_bundles_completed(), "sanity: no bundles contributed yet, should not be complete")

	_year_three_evaluation_events = []
	_game_over_events = []
	CommunityGoalManager.year_three_evaluation.connect(_on_year_three_evaluation_for_test)
	CommunityGoalManager.game_over.connect(_on_game_over_for_test)

	TimeManager.year = 3
	CommunityGoalManager._on_day_started(1, "Spring", "Mon")

	CommunityGoalManager.year_three_evaluation.disconnect(_on_year_three_evaluation_for_test)
	CommunityGoalManager.game_over.disconnect(_on_game_over_for_test)
	TimeManager.year = 1

	_check(_year_three_evaluation_events.size() == 1 and _year_three_evaluation_events[0][3] == false,
		"challenge_mode with bundles incomplete should evaluate as failed, got %s" % [_year_three_evaluation_events])
	_check(_game_over_events.size() == 1,
		"a failing challenge-mode evaluation should emit game_over exactly once, got %d" % _game_over_events.size())
	_check(CommunityGoalManager.is_game_over(), "a failing challenge-mode evaluation should flip is_game_over()")

	# evaluation should be a one-shot per save -- firing day_started again on
	# the same day must not re-evaluate or re-emit game_over.
	_game_over_events = []
	CommunityGoalManager.game_over.connect(_on_game_over_for_test)
	CommunityGoalManager._on_day_started(1, "Spring", "Mon")
	CommunityGoalManager.game_over.disconnect(_on_game_over_for_test)
	_check(_game_over_events.is_empty(), "the year-3 evaluation should only ever fire once (_evaluation_fired guard)")

func _test_community_goal_save_round_trip() -> void:
	_reset_community_goal_manager()
	_reset_inventory_manager()
	InventoryManager.add_item("parsnip", 5)
	CommunityGoalManager.challenge_mode = true
	CommunityGoalManager.contribute_item("pantry_bundle", "parsnip", 2)

	var saved := SaveManager.build_save_data()

	CommunityGoalManager.challenge_mode = false
	CommunityGoalManager._contributions = {}
	CommunityGoalManager._completed = {}
	_check(CommunityGoalManager.contributed_count("pantry_bundle", "parsnip") == 0,
		"sanity check: perturbing should clear contributed progress before applying save data")

	SaveManager.apply_save_data(saved)

	_check(CommunityGoalManager.challenge_mode == true,
		"challenge_mode should round-trip through save/load")
	_check(CommunityGoalManager.contributed_count("pantry_bundle", "parsnip") == 2,
		"bundle contribution progress should round-trip through save/load, got %d" \
		% CommunityGoalManager.contributed_count("pantry_bundle", "parsnip"))

## --- WeatherManager (closing NPCScheduleEntry.weather's dead-scaffolding
## gap from #18, and issue #52's flagged "no WeatherManager exists yet") ---

func _on_weather_changed_for_test(weather: String) -> void:
	_weather_changed_events.append(weather)

func _reset_weather_manager() -> void:
	WeatherManager._current_weather = WeatherManager.SUNNY

func _test_weather_rolls_valid_values_for_non_winter_season() -> void:
	_reset_weather_manager()
	for i in range(50):
		WeatherManager._roll_weather("Spring")
		_check(WeatherManager.get_current_weather() in [WeatherManager.SUNNY, WeatherManager.RAINY],
			"non-Winter rolls should only ever produce Sunny or Rainy, got %s" % WeatherManager.get_current_weather())

func _test_weather_winter_uses_snowy_not_rainy() -> void:
	_reset_weather_manager()
	var saw_snowy := false
	for i in range(50):
		WeatherManager._roll_weather("Winter")
		var weather := WeatherManager.get_current_weather()
		_check(weather in [WeatherManager.SUNNY, WeatherManager.SNOWY],
			"Winter rolls should only ever produce Sunny or Snowy (never Rainy), got %s" % weather)
		if weather == WeatherManager.SNOWY:
			saw_snowy = true
	_check(saw_snowy, "Winter rolls should be able to surface Snowy across enough samples")

func _test_weather_changed_only_fires_on_actual_change() -> void:
	_reset_weather_manager()
	_weather_changed_events = []
	WeatherManager.weather_changed.connect(_on_weather_changed_for_test)

	for i in range(50):
		var before := WeatherManager.get_current_weather()
		var count_before := _weather_changed_events.size()
		WeatherManager._roll_weather("Spring")
		var after := WeatherManager.get_current_weather()
		var count_after := _weather_changed_events.size()
		if before == after:
			_check(count_after == count_before,
				"a no-op roll (weather unchanged) should not fire weather_changed")
		else:
			_check(count_after == count_before + 1 and _weather_changed_events[-1] == after,
				"an actual weather change should fire weather_changed exactly once with the new value")

	WeatherManager.weather_changed.disconnect(_on_weather_changed_for_test)

func _test_weather_save_round_trip() -> void:
	_reset_weather_manager()
	WeatherManager._current_weather = WeatherManager.RAINY

	var saved := SaveManager.build_save_data()

	WeatherManager._current_weather = WeatherManager.SUNNY
	_check(WeatherManager.get_current_weather() == WeatherManager.SUNNY,
		"sanity: perturbing should change current weather before applying save data")

	SaveManager.apply_save_data(saved)

	_check(WeatherManager.get_current_weather() == WeatherManager.RAINY,
		"current weather should round-trip through save/load, got %s" % WeatherManager.get_current_weather())

func _test_npc_schedule_entry_weather_gating() -> void:
	var any_weather := NPCScheduleEntry.new()
	any_weather.weather = "Any"
	_check(any_weather.matches("Spring", WeatherManager.SUNNY), "weather='Any' should match Sunny")
	_check(any_weather.matches("Spring", WeatherManager.RAINY), "weather='Any' should match Rainy")

	var rainy_only := NPCScheduleEntry.new()
	rainy_only.weather = WeatherManager.RAINY
	_check(rainy_only.matches("Spring", WeatherManager.RAINY), "a Rainy-only entry should match Rainy")
	_check(not rainy_only.matches("Spring", WeatherManager.SUNNY),
		"a Rainy-only entry should not match Sunny")
