extends Node
## Autoload: StaminaManager
##
## Implements #120: Soften the pass-out gold penalty.
## Tracks current and max stamina, handles spending and restoration.

signal stamina_changed(current: int, max_stamina: int)
signal passed_out()

var current_stamina: int = 100
var max_stamina: int = 100
var _passed_out_today: bool = false

## Polished #120: The "Cozy" Penalty.
## Instead of a harsh flat penalty, we use a scaling penalty
## that is capped to prevent bankruptcy in the early game.
const PASS_OUT_PENALTY_PERCENT := 0.05 # 5% of current gold
const MIN_PENALTY := 10
const MAX_PENALTY := 100

func spend(amount: int) -> bool:
	if current_stamina < amount:
		_pass_out()
		return false
	current_stamina -= amount
	stamina_changed.emit(current_stamina, max_stamina)
	return true

func restore(amount: int) -> void:
	current_stamina = mini(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

func restore_full() -> void:
	_passed_out_today = false
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func _pass_out() -> void:
	_passed_out_today = true
	passed_out.emit(PASS_OUT_MONEY_PENALTY) # This signal is handled by ShippingBinManager

func get_pass_out_penalty() -> int:
	var gold = ShippingBinManager.gold
	var penalty = int(gold * PASS_OUT_PENALTY_PERCENT)
	return clamp(penalty, MIN_PENALTY, MAX_PENALTY)
