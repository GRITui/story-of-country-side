extends Node
## Super User autoplay driver - sprint 002 hands-on pass (v2).
##
## Boots the REAL game and plays it via public APIs only. Phases
## (user args after "--":  --phase full|fest_save|fest_check):
##   full       - new-player run: intro, multi-day farm loop w/ daily
##                watering, fish->ship->overnight-gold economy, world
##                travel, mining, ranching, foraging, pacing numbers.
##   fest_save  - fresh save, fast-forward to Spring day 13, start the
##                Bloomtide Fair (its real calendar day), save mid-
##                festival, quit. Simulates player quitting at night.
##   fest_check - plain reboot loading that save: does the festival
##                survive a real quit+relaunch?
## Run:
##   godot --headless --path . superuser/autoplay/AutoplayDriver.tscn -- --phase full

const DAY_TIME_SCALE := 30.0
const FEST_TIME_SCALE := 300.0 ## fast-forward to festival day quickly

var _main: Node
var _failures: Array[String] = []

func _ready() -> void:
	var phase := "full"
	var uargs := OS.get_cmdline_user_args()
	if uargs.size() >= 2 and uargs[0] == "--phase":
		phase = uargs[1]
	Engine.time_scale = FEST_TIME_SCALE if phase != "full" else DAY_TIME_SCALE
	print("[SU2] phase=", phase, " time_scale=", Engine.time_scale)
	match phase:
		"full":
			await _phase_full()
		"fest_save":
			await _phase_fest_save()
		"fest_check":
			await _phase_fest_check()
		_:
			_fail("unknown phase " + phase)
	_finish()

# --- shared helpers ----------------------------------------------------

func _boot() -> void:
	_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	add_child(_main)

func _hud_visible() -> bool:
	for c in _main.get_children():
		if c is HUD:
			return true
	return false

func _active_intro() -> IntroSequence:
	for c in _main.get_children():
		if c is IntroSequence and not c.is_finished():
			return c
	return null

func _click_through_intro() -> void:
	var guard := 0
	while (_active_intro() != null or not _hud_visible()) and guard < 1500:
		var intro := _active_intro()
		if intro != null:
			intro.advance()
		guard += 1
		if guard % 250 == 0:
			print("[SU2] intro-wait i=%d intro_present=%s hud=%s seen=%s"
				% [guard, str(_active_intro() != null), str(_hud_visible()),
				str(SaveManager.has_seen_intro())])
		await get_tree().create_timer(0.05).timeout
	if guard >= 1500:
		_fail("intro guard exhausted")
	elif SaveManager.has_seen_intro():
		print("[SU2] intro clicked through; HUD live")
	else:
		_fail("HUD live but has_seen_intro false")

func _fail(msg: String) -> void:
	_failures.append(msg)
	print("[SU2-FAIL] " + msg)

func _finish() -> void:
	Engine.time_scale = 1.0
	print("[SU2-RESULT] failures=%d" % _failures.size())
	for f in _failures:
		print("[SU2-RESULT] failure=" + f.replace(" ", "_"))
	print("[SU2] done")
	get_tree().quit(1 if _failures.size() > 0 else 0)

# --- phases ------------------------------------------------------------

func _phase_full() -> void:
	SaveManager.delete_save_file()
	_boot()
	await _click_through_intro()

	# Farm loop, played like a player: water EVERY day.
	var pos := Vector2i(0, 0)
	if not FarmPlotManager.can_plant(pos, "rice"):
		_fail("cannot plant rice on empty spring plot")
		return
	FarmPlotManager.plant(pos, "rice")
	var def := FarmPlotManager.get_crop_definition("rice")
	for i in range(def.days_to_grow):
		FarmPlotManager.water(pos)
		print("[SU2] watered day %d" % (i + 1))
		await TimeManager.day_started
	var result := FarmPlotManager.harvest(pos)
	if result.is_empty():
		_fail("harvest empty after daily watering x%d" % def.days_to_grow)
	else:
		print("[SU2-RESULT] first_harvest=%s quality=%s (seedless: plant never checked inventory)"
			% [result.item_id, result.quality])

	# Economy: catch -> ship -> overnight payout.
	var pool := FishingManager.get_available_fish(
		"river", TimeManager.current_season(), TimeManager.hour)
	if pool.is_empty():
		_fail("empty fish pool river current-hour")
	else:
		var c := FishingManager.attempt_catch(pool[0], 0.8)
		if c.is_empty():
			_fail("attempt_catch failed " + pool[0])
		else:
			var price := FishingManager.get_sell_price(pool[0], c.quality)
			ShippingBinManager.ship_item(c.item_id, c.quantity, price)
			var gold_before := ShippingBinManager.gold
			await TimeManager.day_started
			print("[SU2-RESULT] economy gold %d->%d overnight pending=%d"
				% [gold_before, ShippingBinManager.gold,
				ShippingBinManager.pending_item_count()])

	_travel_all_locations()
	_mining_pass()
	_ranch_pass()
	_forage_pass()
	_measure_day_pacing()

func _phase_fest_save() -> void:
	SaveManager.delete_save_file()
	_boot()
	await _click_through_intro()
	# Fast-forward to Bloomtide Fair's real calendar day (Spring 13).
	while TimeManager.day_in_season != 13:
		await TimeManager.day_started
	print("[SU2] reached Spring day 13 (festival day) at %02d:%02d"
		% [TimeManager.hour, TimeManager.minute])
	if not FestivalManager.start_festival("bloomtide_fair"):
		_fail("start_festival rejected on its own calendar day")
		return
	print("[SU2] festival live; saving mid-festival and quitting like a player")
	print("[SU2-FEST] save_state active=%s overlay=%s clock=%02d:%02d day=%d"
		% [str(FestivalManager.is_festival_active()),
		str(_overlay_present()), TimeManager.hour, TimeManager.minute,
		TimeManager.day_in_season])
	SaveManager.save_game()

func _phase_fest_check() -> void:
	# Plain reboot: MainController auto-loads the save. No special setup.
	_boot()
	await get_tree().create_timer(0.5).timeout
	print("[SU2-FEST] relaunch_state active=%s overlay=%s restored_clock=%02d:%02d day=%d"
		% [str(FestivalManager.is_festival_active()), str(_overlay_present()),
		TimeManager.hour, TimeManager.minute, TimeManager.day_in_season])
	if FestivalManager.is_festival_active() == false:
		print("[SU2] CONFIRMED P1 via real quit+relaunch: festival gone after reboot")
	else:
		print("[SU2] festival survived reboot - P1 not reproducible this way")

func _travel_all_locations() -> void:
	for loc in ["Ranch", "Mine", "Forage", "Farm"]:
		_main.travel_to(loc)
		if _main.current_location() != loc:
			_fail("travel_to did not stick: " + loc)
	print("[SU2] world travel ok (Ranch/Mine/Forage/Farm)")

func _mining_pass() -> void:
	_main.travel_to("Mine")
	var broke := {}
	for y in range(MiningManager.get_floor_size().y):
		for x in range(MiningManager.get_floor_size().x):
			var tile := Vector2i(x, y)
			if MiningManager.has_rock(tile):
				broke = MiningManager.break_rock(tile)
				break
		if not broke.is_empty():
			break
	if broke.is_empty():
		_fail("break_rock produced nothing on floor 1")
	else:
		print("[SU2] mining break_rock ok")

func _ranch_pass() -> void:
	_main.travel_to("Ranch")
	if not AnimalManager.add_animal("su_chicken_1", "chicken"):
		_fail("add_animal(chicken) rejected")
		return
	AnimalManager.feed("su_chicken_1")
	AnimalManager.brush("su_chicken_1")
	print("[SU2] ranch chicken added+fed+brushed")

func _forage_pass() -> void:
	_main.travel_to("Forage")
	var found := false
	for y in range(8):
		for x in range(8):
			if ForagingManager.is_available(Vector2i(x, y)):
				ForagingManager.gather(Vector2i(x, y))
				found = true
				break
		if found:
			break
	print("[SU2] forage node found+gathered=%s" % str(found))

func _measure_day_pacing() -> void:
	var real_seconds := ((TimeManager.DAY_END_HOUR + 24 - TimeManager.DAY_START_HOUR) % 24) * 60.0 / 7.0
	print("[SU2-RESULT] real_seconds_per_day_no_sleep=%.0f idle_minutes_to_first_rice=%.1f"
		% [real_seconds, real_seconds * 5.0 / 60.0])

func _overlay_present() -> bool:
	for c in _main.get_children():
		if c is FestivalMiniGameOverlay and is_instance_valid(c):
			return true
	return false
