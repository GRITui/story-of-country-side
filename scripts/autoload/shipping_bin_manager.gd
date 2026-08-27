extends Node
## Autoload: ShippingBinManager
##
## Owns the player's wallet (ENG-22) — nothing else in the repo has a gold
## value yet, so this is the wallet's home. Items placed in the bin during
## the day are paid out overnight at TimeManager.day_started, matching the
## design doc's "drops items in bin, money calculated/rewarded overnight"
## rule. Also consumes StaminaManager's pass-out penalty (#12 shipped that
## signal announcing a money penalty but nothing paid it out until now).

signal item_shipped(item_id: String, quantity: int, unit_price: int)
signal payout_processed(total_earned: int, item_count: int)
signal gold_changed(new_gold: int)

const STARTING_GOLD := 500
## Issue #120: soften pass-out penalty from 10% to 5%. Configurable so
## balance tuning doesn't require code changes. Applied as a percentage
## of current gold, clamped to at least 0 and at most the incoming
## money_penalty when that signal carries a fixed 100.
const PASS_OUT_PENALTY_RATE := 0.05

var gold: int = STARTING_GOLD

## Array of {item_id: String, quantity: int, unit_price: int}. A list of
## shipment entries rather than a merged item_id -> total map, so two
## shipments of the same item at different quality-tier prices don't get
## collapsed into one (wrong) average price.
var _pending_shipments: Array[Dictionary] = []

## Nightly receipt (Issue #98): persisted after each payout, readable until
## the next payout overwrites it. Empty when no shipment occurred last night.
var _last_shipment: Dictionary = {} ## item_id -> {qty: int, gold: int}
var _total_gold_last_night: int = 0

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
	if StaminaManager:
		StaminaManager.passed_out.connect(_on_passed_out)

## quantity and unit_price must both be positive; a non-positive shipment
## is a no-op rather than a silent negative-value entry.
func ship_item(item_id: String, quantity: int, unit_price: int) -> void:
	if quantity <= 0 or unit_price <= 0:
		return
	_pending_shipments.append({
		"item_id": item_id,
		"quantity": quantity,
		"unit_price": unit_price,
	})
	item_shipped.emit(item_id, quantity, unit_price)

## PriceRegistry-aware convenience: look up unit_price from the canonical
## registry and delegate to ship_item. Keeps old ship_item(unit_price) path
## intact for tests and managers not yet migrated.
const _PriceRegistryScript := preload("res://scripts/economy/price_registry.gd")

func ship_item_with_registry(item_id: String, quantity: int, quality: String = "normal") -> bool:
	var price: int = _PriceRegistryScript.get_price(item_id, quality)
	# Fallback: if registry has no entry, fall back to caller's responsibility.
	if price <= 0:
		return false
	ship_item(item_id, quantity, price)
	return true

func pending_item_count() -> int:
	var count := 0
	for shipment in _pending_shipments:
		count += shipment["quantity"] as int
	return count

func get_last_shipment() -> Dictionary:
	return _last_shipment.duplicate(true)

func get_total_last_night() -> int:
	return _total_gold_last_night

func spend(amount: int) -> bool:
	if amount <= 0 or amount > gold:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func _add_gold(amount: int) -> void:
	if amount == 0:
		return
	gold = maxi(gold + amount, 0)
	gold_changed.emit(gold)

func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	if _pending_shipments.is_empty():
		# No payout this night — clear receipt so UI shows "nothing shipped".
		_last_shipment.clear()
		_total_gold_last_night = 0
		return
	var total := 0
	var item_count := 0
	var receipt: Dictionary = {}
	for shipment in _pending_shipments:
		var qty: int = shipment["quantity"] as int
		var price: int = shipment["unit_price"] as int
		var item_id: String = shipment["item_id"] as String
		total += qty * price
		item_count += qty
		var entry: Dictionary = receipt.get(item_id, {"qty": 0, "gold": 0})
		entry["qty"] = int(entry["qty"]) + qty
		entry["gold"] = int(entry["gold"]) + qty * price
		receipt[item_id] = entry
	_pending_shipments.clear()
	_last_shipment = receipt
	_total_gold_last_night = total
	_add_gold(total)
	payout_processed.emit(total, item_count)

func _on_passed_out(money_penalty: int) -> void:
	# Soften per #120: cap penalty at PASS_OUT_PENALTY_RATE of current gold.
	# money_penalty is StaminaManager's fixed 100 (legacy). We respect the
	# softer percentage when gold is large enough for it to matter; for very
	# small wallets we still clamp via _add_gold's maxi(...,0).
	var penalty := money_penalty
	if gold > 0 and PASS_OUT_PENALTY_RATE > 0.0:
		var pct_penalty := int(gold * PASS_OUT_PENALTY_RATE)
		# Use the smaller of the fixed penalty and the 5% penalty — this
		# softens the hit (5% of 500 = 25 < 100) while keeping clamp behavior
		# for tiny wallets. If pct_penalty is 0 for very small gold (<20),
		# we still apply at least 0 (no penalty loop).
		penalty = mini(penalty, pct_penalty) if pct_penalty > 0 else penalty
	_add_gold(-penalty)

func to_save_dict() -> Dictionary:
	return {
		"gold": gold,
		"pending_shipments": _pending_shipments.duplicate(true),
		"last_shipment": _last_shipment.duplicate(true),
		"total_gold_last_night": _total_gold_last_night,
	}

func from_save_dict(data: Dictionary) -> void:
	gold = data.get("gold", STARTING_GOLD)
	var raw: Array = data.get("pending_shipments", [])
	_pending_shipments.clear()
	for entry in raw:
		_pending_shipments.append((entry as Dictionary).duplicate())
	_last_shipment = (data.get("last_shipment", {}) as Dictionary).duplicate(true)
	_total_gold_last_night = data.get("total_gold_last_night", 0)
