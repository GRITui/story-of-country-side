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

var gold: int = STARTING_GOLD

## Array of {item_id: String, quantity: int, unit_price: int}. A list of
## shipment entries rather than a merged item_id -> total map, so two
## shipments of the same item at different quality-tier prices don't get
## collapsed into one (wrong) average price.
var _pending_shipments: Array[Dictionary] = []

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

func pending_item_count() -> int:
	var count := 0
	for shipment in _pending_shipments:
		count += shipment["quantity"] as int
	return count

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
		return
	var total := 0
	var item_count := 0
	for shipment in _pending_shipments:
		total += (shipment["quantity"] as int) * (shipment["unit_price"] as int)
		item_count += shipment["quantity"] as int
	_pending_shipments.clear()
	_add_gold(total)
	payout_processed.emit(total, item_count)

func _on_passed_out(money_penalty: int) -> void:
	_add_gold(-money_penalty)

func to_save_dict() -> Dictionary:
	return {
		"gold": gold,
		"pending_shipments": _pending_shipments.duplicate(true),
	}

func from_save_dict(data: Dictionary) -> void:
	gold = data.get("gold", STARTING_GOLD)
	var raw: Array = data.get("pending_shipments", [])
	_pending_shipments.clear()
	for entry in raw:
		_pending_shipments.append((entry as Dictionary).duplicate())
