extends Node
## Autoload: ShippingBinManager — PO-16BIT-CORE-1: profit at 06:00 next morning
signal gold_changed(new_gold: int)
signal item_shipped(item_id: String, quantity: int, unit_price: int)
signal payout_processed(gold_amount: int, item_count: int)

var gold: int = 500
var _current_shipments: Dictionary = {} ## item_id -> {"qty":int,"price":int}
var _daily_history: Array = []

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func _on_day_started(_d: int, _s: String, _w: String) -> void:
	# Payout at 06:00 next morning per spec
	process_payout()

func ship_item(item_id: String, quantity: int, unit_price: int = 10) -> void:
	if item_id.is_empty() or quantity <= 0:
		return
	if unit_price <= 0:
		unit_price = 10
	var entry: Dictionary = _current_shipments.get(item_id, {"qty": 0, "price": unit_price})
	entry["qty"] = int(entry.get("qty", 0)) + quantity
	entry["price"] = unit_price
	_current_shipments[item_id] = entry
	item_shipped.emit(item_id, quantity, unit_price)

func process_payout() -> void:
	var total_gold := 0
	var total_items := 0
	_daily_history.clear()
	for item_id in _current_shipments.keys():
		var e: Dictionary = _current_shipments[item_id]
		var qty: int = int(e.get("qty", 0))
		var price: int = int(e.get("price", 10))
		var subtotal := qty * price
		total_gold += subtotal
		total_items += qty
		_daily_history.append({"id": item_id, "qty": qty, "price": price, "total": subtotal})
	gold += total_gold
	_current_shipments.clear()
	gold_changed.emit(gold)
	payout_processed.emit(total_gold, total_items)

func get_daily_receipt() -> Array:
	return _daily_history.duplicate()

func spend(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func handle_pass_out_penalty() -> void:
	var penalty := 0
	if StaminaManager and StaminaManager.has_method("get_pass_out_penalty"):
		penalty = StaminaManager.get_pass_out_penalty()
	gold = maxi(0, gold - penalty)
	gold_changed.emit(gold)

func to_save_dict() -> Dictionary:
	return {"gold": gold, "shipments": _current_shipments.duplicate(), "history": _daily_history.duplicate()}

func from_save_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", 500))
	_current_shipments = (data.get("shipments", {}) as Dictionary).duplicate()
	_daily_history = (data.get("history", []) as Array).duplicate()
