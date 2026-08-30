extends Node
## Autoload: StaminaManager — PO-16BIT-CORE-1 overhaul: 100 max, 50% speed at 0, collapse
signal stamina_changed(current: int, max_stamina: int)
signal passed_out()
signal collapsed()

var current_stamina: int = 100
var max_stamina: int = 100
var _passed_out_today: bool = false

const PASS_OUT_PENALTY_PERCENT := 0.05
const MIN_PENALTY := 10
const MAX_PENALTY := 100
const COLLAPSE_THRESHOLD := 0

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_stamina < amount:
		current_stamina = 0
		stamina_changed.emit(current_stamina, max_stamina)
		_pass_out()
		return false
	current_stamina -= amount
	stamina_changed.emit(current_stamina, max_stamina)
	if current_stamina == 0:
		collapsed.emit()
	return true

func restore(amount: int) -> void:
	current_stamina = mini(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

func restore_full() -> void:
	_passed_out_today = false
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func get_movement_speed_multiplier() -> float:
	# Spec: 0 stamina -> 50% speed
	if current_stamina <= 0:
		return 0.5
	return 1.0

func is_collapsed() -> bool:
	return current_stamina <= COLLAPSE_THRESHOLD

func _on_day_started(_d: int, _s: String, _w: String) -> void:
	restore_full()

func _pass_out() -> void:
	_passed_out_today = true
	passed_out.emit()
	collapsed.emit()

func get_pass_out_penalty() -> int:
	var gold := 0
	if ShippingBinManager and "gold" in ShippingBinManager:
		gold = ShippingBinManager.gold
	var penalty = int(gold * PASS_OUT_PENALTY_PERCENT)
	return clamp(penalty, MIN_PENALTY, MAX_PENALTY)

func to_save_dict() -> Dictionary:
	return {"current": current_stamina, "max": max_stamina, "passed_out_today": _passed_out_today}

func from_save_dict(data: Dictionary) -> void:
	current_stamina = int(data.get("current", max_stamina))
	max_stamina = int(data.get("max", 100))
	_passed_out_today = bool(data.get("passed_out_today", false))
