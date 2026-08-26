extends Node
## Autoload: InventoryManager
##
## Minimal general-purpose item ledger (#13) — item_id -> quantity only, no
## item metadata/weight/stacking-limits system. Flagged explicitly as a gap
## in ToolManager's docstring (#23): "whoever builds the first activity that
## produces real items (#13/#16/#17) will hit directly." Agriculture (#13)
## is that first activity, so this ships general-purpose rather than
## crops-only — Ranching/Fishing/Mining/Foraging (#14/#15/#16/#17) are
## expected to consume this same autoload next epoch, not fork their own
## ledger. Same "minimal but real" spirit as ToolManager's ore ledger, just
## generalized to any item_id instead of scoped to ore.
##
## Intentionally NOT scoped here: item metadata (display name, icon,
## category), weight/carry limits, stack-size caps. Those are real gaps a
## future activity may need to fill in, but nothing in #13 or the epic's
## other sub-issues requires them yet, so they're not fabricated as
## unrequested scope.

signal item_changed(item_id: String, delta: int, total: int)

var _counts: Dictionary = {} # item_id -> int

func add_item(item_id: String, quantity: int) -> void:
	if item_id.is_empty() or quantity <= 0:
		return
	var total: int = get_count(item_id) + quantity
	_counts[item_id] = total
	item_changed.emit(item_id, quantity, total)

## Fails (returns false, no partial deduction) when there isn't enough of
## item_id on hand -- mirrors ToolManager.upgrade_tool's "check before
## spend" pattern so a failed removal never leaves a partial ledger change.
func remove_item(item_id: String, quantity: int) -> bool:
	if item_id.is_empty() or quantity <= 0:
		return false
	var current := get_count(item_id)
	if current < quantity:
		return false
	var total := current - quantity
	if total == 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = total
	item_changed.emit(item_id, -quantity, total)
	return true

func get_count(item_id: String) -> int:
	return _counts.get(item_id, 0)

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_count(item_id) >= quantity

## Convenience for the "pull from inventory, place in the shipping bin"
## flow #13 needs end-to-end (crop/tile logic must not ship directly) --
## removes from the ledger and forwards to ShippingBinManager.ship_item in
## one call so every future item-producing activity doesn't reimplement
## this same two-step glue. Fails without shipping anything if the ledger
## doesn't have enough of item_id.
##
## Also fails (returns false) when unit_price <= 0 (#97): the bin's
## ship_item silently ignores non-positive-price shipments, so without this
## guard the stock was destroyed here and then dropped by the bin -- goods
## gone, zero gold, no signal. Like every other failure path in this file,
## a rejected sale emits nothing and leaves both ledger and bin untouched.
func sell_item(item_id: String, quantity: int, unit_price: int) -> bool:
	if unit_price <= 0:
		return false
	if not remove_item(item_id, quantity):
		return false
	ShippingBinManager.ship_item(item_id, quantity, unit_price)
	return true

func to_save_dict() -> Dictionary:
	return {
		"counts": _counts.duplicate(),
	}

func from_save_dict(data: Dictionary) -> void:
	_counts = (data.get("counts", {}) as Dictionary).duplicate()
