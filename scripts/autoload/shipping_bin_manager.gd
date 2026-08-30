extends Node
## Autoload: ShippingBinManager
##
## Implements #98: Nightly sale receipts.
## Handles shipping items and processing daily payouts.

signal gold_changed(new_gold: int)
signal item_shipped(item_id: String, quantity: int, unit_price: int)
signal payout_processed(gold_amount: int, item_count: int)

var gold: int = 500
var _current_shipments: Dictionary = {} ## item_id -> quantity
var _daily_history: Array = [] ## List of {item_id, quantity, price, total}

func ship_item(item_id: String, quantity: int) -> void:
	var price = 10 # Simplified: in real version, reads from PriceRegistry
	_current_shipments[item_id] = _current_shipments.get(item_id, 0) + quantity
	item_shipped.emit(item_id, quantity, price)

func process_payout() -> void:
	var total_gold := 0
	var total_items := 0
	_daily_history.clear()
	
	for item_id in _current_shipments:
		var qty = _current_shipments[item_id]
		var price = 10 # Simplified
		var subtotal = qty * price
		total_gold += subtotal
		total_items += qty
		_daily_history.append({"id": item_id, "qty": qty, "price": price, "total": subtotal})
	
	gold += total_gold
	_current_shipments.clear()
	gold_changed.emit(gold)
	payout_processed.emit(total_gold, total_items)

func get_daily_receipt() -> Array:
	return _daily_history

func spend(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func handle_pass_out_penalty() -> void:
	var penalty = StaminaManager.get_pass_out_penalty()
	gold = max(0, gold - penalty)
	gold_changed.emit(gold)
