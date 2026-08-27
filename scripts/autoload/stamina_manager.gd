extends Node
## Autoload: StaminaManager
##
## Owns the stamina pool (ENG-12): actions spend stamina, hitting 0 triggers
## a pass-out. This node only announces the pass-out (money penalty amount)
## via signal — it does not deduct money itself, since money is the Shipping
## Bin economy's responsibility (#22), not this system's.

signal stamina_changed(current: int, max: int)
signal passed_out(money_penalty: int)

const MAX_STAMINA_DEFAULT := 100
const PASS_OUT_MONEY_PENALTY := 100
const PASS_OUT_ENERGY_RATIO := 0.5 ## next day starts at 50% max stamina, not full

var max_stamina: int = MAX_STAMINA_DEFAULT
var current_stamina: int = MAX_STAMINA_DEFAULT

var _passed_out_today: bool = false

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func spend(amount: int) -> void:
	if amount <= 0:
		return
	current_stamina = maxi(current_stamina - amount, 0)
	stamina_changed.emit(current_stamina, max_stamina)
	if current_stamina == 0 and not _passed_out_today:
		_pass_out()

func restore(amount: int) -> void:
	if amount <= 0:
		return
	current_stamina = mini(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

## Squad Alpha (P0 #93/#120): full restore on sleep.
## Called reactively via TimeManager.day_started for normal day rollovers
## (including sleep-driven ones), but also exposed as a public helper so
## callers that need an explicit full restore (e.g. bed interaction before
## the day_started signal would fire) have a single place to do it without
## touching _passed_out_today directly.
func restore_full() -> void:
	_passed_out_today = false
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func _pass_out() -> void:
	_passed_out_today = true
	passed_out.emit(PASS_OUT_MONEY_PENALTY)

func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	if _passed_out_today:
		current_stamina = int(max_stamina * PASS_OUT_ENERGY_RATIO)
		_passed_out_today = false
	else:
		current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func to_save_dict() -> Dictionary:
	return {
		"max_stamina": max_stamina,
		"current_stamina": current_stamina,
		"passed_out_today": _passed_out_today,
	}

func from_save_dict(data: Dictionary) -> void:
	max_stamina = data.get("max_stamina", MAX_STAMINA_DEFAULT)
	current_stamina = data.get("current_stamina", max_stamina)
	_passed_out_today = data.get("passed_out_today", false)
