extends Node
## Super User retail-economy sim driver - sprint 003 (v1).
##
## Tester pass over the RETAIL loop (sell side = shipping bin, buy side =
## tool/infrastructure gold sinks) played through public APIs only -- same
## reach a player-facing shop UI has. Stock is granted via
## InventoryManager.add_item(), which is the exact crediting path harvest/
## gather/mine already use; no internals are poked.
##
## Phase (user args after "--"): --phase retail
## Run:
##   godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase retail

var _main: Node
var _failures: Array[String] = []
var _checks := 0
var _last_payout_total := -1
var _last_payout_count := -1

func _ready() -> void:
	var phase := "retail"
	var uargs := OS.get_cmdline_user_args()
	if uargs.size() >= 2 and uargs[0] == "--phase":
		phase = uargs[1]
	print("[SU3] phase=", phase)
	ShippingBinManager.payout_processed.connect(_on_payout_processed)
	match phase:
		"retail":
			await _phase_retail()
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
		await get_tree().create_timer(0.05).timeout
	if guard >= 1500:
		_fail("intro guard exhausted")
	else:
		print("[SU3] booted; HUD live (gold=%d)" % ShippingBinManager.gold)

func _on_payout_processed(total_earned: int, item_count: int) -> void:
	_last_payout_total = total_earned
	_last_payout_count = item_count

func _check(cond: bool, uc: String, what: String) -> bool:
	_checks += 1
	if cond:
		print("[SU3] %s PASS: %s" % [uc, what])
	else:
		_fail("%s %s" % [uc, what])
	return cond

func _fail(msg: String) -> void:
	_failures.append(msg)
	print("[SU3-FAIL] " + msg)

func _next_day_edge() -> void:
	Engine.time_scale = 300.0
	await TimeManager.day_started
	Engine.time_scale = 1.0

func _finish() -> void:
	Engine.time_scale = 1.0
	print("[SU3-RESULT] checks=%d failures=%d" % [_checks, _failures.size()])
	for f in _failures:
		print("[SU3-RESULT] failure=" + f.replace(" ", "_"))
	print("[SU3] done")
	get_tree().quit(1 if _failures.size() > 0 else 0)

# --- the retail matrix ---------------------------------------------------

func _phase_retail() -> void:
	SaveManager.delete_save_file()
	_boot()
	await _click_through_intro()
	var inv := InventoryManager
	var bin := ShippingBinManager
	var gold0: int = bin.gold

	# UC01 - happy path: stock in, listed at a price, sits in bin overnight.
	inv.add_item("parsnip", 10)
	var r01 := inv.sell_item("parsnip", 10, 35)
	_check(r01, "UC01", "sell_item accepted full stock")
	_check(inv.get_count("parsnip") == 0, "UC01", "inventory decremented to 0")
	_check(bin.pending_item_count() == 10, "UC01", "bin holds 10 pending units")

	# UC04 - oversell must be rejected with ledger untouched.
	inv.add_item("potato", 1)
	var r04 := inv.sell_item("potato", 5, 10)
	_check(r04 == false, "UC04", "oversell rejected")
	_check(inv.get_count("potato") == 1 and bin.pending_item_count() == 10,
			"UC04", "stock+pending untouched after oversell")

	# UC05 - empty item id must be rejected end-to-end.
	var r05 := inv.sell_item("", 1, 10)
	_check(r05 == false, "UC05", "empty item_id rejected")

	# UC02 - retailer lists goods at price 0 (misconfigured price feed).
	# EXPECTED: reject, stock stays. Watch for silent stock destruction.
	inv.add_item("cauliflower", 3)
	var r02 := inv.sell_item("cauliflower", 3, 0)
	if not _check(r02 == false, "UC02",
			"zero-price listing rejected (got accept=%s, cauliflower_left=%d, pending=%d)"
					% [str(r02), inv.get_count("cauliflower"), bin.pending_item_count()]):
		print("[SU3] UC02 DAMAGE: goods left inventory but no payable shipment exists")

	# UC03 - negative price variant of the same contract hole.
	inv.add_item("melon", 2)
	var r03 := inv.sell_item("melon", 2, -5)
	if not _check(r03 == false, "UC03",
			"negative-price listing rejected (got accept=%s, melon_left=%d)"
					% [str(r03), inv.get_count("melon")]):
		print("[SU3] UC03 DAMAGE: goods left inventory on a negative-price sale")

	# UC06 - quality-tier style multi-line shipment, exact overnight math.
	inv.add_item("turnip", 6)
	inv.sell_item("turnip", 4, 12)  # normal tier
	inv.sell_item("turnip", 2, 15)  # silver tier
	# pending = 10 parsnip + (4x12 + 2x15 turnip) -> payout 350+48+30 = 428
	_check(bin.pending_item_count() == 16, "UC06", "16 pending units across 3 price lines")

	# UC07 - quit-mid-day persistence: save, corrupt in-memory state, reload.
	SaveManager.save_game()
	bin.spend(100)                      # gold 500 -> 400
	bin.ship_item("ghost_item", 9, 9)   # phantom line that must NOT survive
	_check(bin.pending_item_count() == 25, "UC07", "pre-reload corruption applied")
	SaveManager.load_game()
	_check(bin.gold == gold0, "UC07", "gold restored to saved value (%d)" % gold0)
	_check(bin.pending_item_count() == 16, "UC07",
			"pending shipments restored (ghost line gone, got %d)" % bin.pending_item_count())

	# UC11 - overnight settlement after reload pays exactly once, exactly right.
	await _next_day_edge()
	_check(bin.gold == gold0 + 428, "UC11",
			"payout settled 428g exactly (gold=%d expected=%d)"
					% [bin.gold, gold0 + 428])
	_check(_last_payout_total == 428 and _last_payout_count == 16, "UC11",
			"payout_processed(total=%d count=%d)" % [_last_payout_total, _last_payout_count])
	_check(bin.pending_item_count() == 0, "UC11", "bin cleared after settlement")

	# UC08 - buy side: tool upgrade with exact funds (two-gate order).
	ToolManager.add_ore("iron_ore", 5)
	_check(ToolManager.can_upgrade("Hoe"), "UC08", "can_upgrade true at 5 ore / >=200g")
	var r08 := ToolManager.upgrade_tool("Hoe")
	_check(r08 and ToolManager.get_tool_tier("Hoe") == 1, "UC08", "Hoe upgraded to Iron")
	_check(bin.gold == gold0 + 228 and ToolManager.get_ore_count("iron_ore") == 0,
			"UC08", "exact debit: gold %d, ore 0" % bin.gold)

	# UC09 - buy side: insufficient gold must not consume ore first.
	bin.spend(700)  # drain below WateringCan's 150g
	ToolManager.add_ore("iron_ore", 4)
	_check(ToolManager.can_upgrade("WateringCan") == false, "UC09",
			"can_upgrade false when gold short")
	var r09 := ToolManager.upgrade_tool("WateringCan")
	_check(r09 == false and ToolManager.get_ore_count("iron_ore") == 4,
			"UC09", "failed purchase consumed no ore (two-gate held)")

	# UC10 - spend() input guards.
	_check(bin.spend(0) == false and bin.spend(-50) == false, "UC10",
			"non-positive spends rejected")

	# Observation for the price-registry question (no assertion): who maps
	# quality ids to prices? Print the surface a future shop UI would need.
	print("[SU3-NOTE] price sources today: CropDefinition.base_sell_price "
			+ "(normal id only), FarmPlotManager quality multipliers, caller-supplied "
			+ "unit_price into sell_item(); no canonical lookup for 'parsnip_silver' etc.")

