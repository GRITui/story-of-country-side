extends Node
## Autoload: SkillManager
##
## The shared "on activity performed" event hook #25's own scope note
## calls for — built before Agriculture/Ranching/Fishing/Mining/Foraging
## (#13/#14/#15/#16/#17) so those five sub-issues emit into one consistent
## interface (add_xp) instead of inventing five different ad-hoc signals.
## Ranching XP feeds the Farming skill, not a separate Ranching skill —
## matches SDV's actual skill list (Farming/Fishing/Mining/Foraging/Combat),
## and Combat is excluded per Decision B (peaceful mines, no combat, #3).
##
## Milestone perks (Issue #116): level 5 grants a perk (stamina max +1 or
## +10% sell price), level 10 grants tool stamina discount. Emits
## perk_unlocked(skill_name, level, perk_id).

signal xp_gained(skill_name: String, amount: int, total_xp: int)
signal level_changed(skill_name: String, new_level: int, old_level: int)
signal perk_unlocked(skill_name: String, level: int, perk_id: String)

const XP_PER_LEVEL_STEP := 100 ## level N costs XP_PER_LEVEL_STEP * N to reach from N-1

## Perk thresholds — placeholder MVP balance, no final perk design exists.
const PERK_LEVEL_5 := 5
const PERK_LEVEL_10 := 10

var _xp: Dictionary = {} ## skill_name -> int
var _unlocked_perks: Dictionary = {} ## skill_name -> Array[String] of perk_id
var _sell_price_bonus: float = 0.0 ## additive bonus applied via get_sell_price_multiplier()
var _tool_stamina_discount: float = 0.0 ## 0.0..1.0 discount on tool stamina cost

func add_xp(skill_name: String, amount: int) -> void:
	if amount <= 0 or skill_name.is_empty():
		return
	var old_level := get_level(skill_name)
	_xp[skill_name] = get_xp(skill_name) + amount
	xp_gained.emit(skill_name, amount, _xp[skill_name])

	var new_level := get_level(skill_name)
	if new_level == old_level:
		return
	# A big XP grant can cross more than one level at once — report every
	# crossed level in order, same reasoning as RelationshipManager's
	# multi-heart-jump handling (#19).
	for level in range(old_level + 1, new_level + 1):
		level_changed.emit(skill_name, level, level - 1)
		_check_milestone_perk(skill_name, level)
		if QuestManager:
			QuestManager.evaluate_skill_level(skill_name, level)

func _check_milestone_perk(skill_name: String, level: int) -> void:
	if level == PERK_LEVEL_5:
		var perk_id := "%s_level_5_bonus" % skill_name.to_lower()
		_grant_perk(skill_name, level, perk_id)
		# Level 5: +10% sell price (via PriceRegistry hook) AND +1 max stamina
		_sell_price_bonus = 0.10
		if StaminaManager:
			StaminaManager.max_stamina += 1
	elif level == PERK_LEVEL_10:
		var perk_id := "%s_level_10_efficiency" % skill_name.to_lower()
		_grant_perk(skill_name, level, perk_id)
		_tool_stamina_discount = 0.20

func _grant_perk(skill_name: String, level: int, perk_id: String) -> void:
	var arr: Array = _unlocked_perks.get(skill_name, [])
	if arr.has(perk_id):
		return
	arr.append(perk_id)
	_unlocked_perks[skill_name] = arr
	perk_unlocked.emit(skill_name, level, perk_id)

func has_perk(skill_name: String, perk_id: String) -> bool:
	var arr: Array = _unlocked_perks.get(skill_name, [])
	return arr.has(perk_id)

func get_unlocked_perks(skill_name: String) -> Array:
	return (_unlocked_perks.get(skill_name, []) as Array).duplicate()

func get_all_perks() -> Dictionary:
	return _unlocked_perks.duplicate(true)

## PriceRegistry hook: returns multiplier (1.0 + bonus). Level 5 = 1.10.
func get_sell_price_multiplier() -> float:
	return 1.0 + _sell_price_bonus

func get_tool_stamina_discount() -> float:
	return _tool_stamina_discount

func get_xp(skill_name: String) -> int:
	return _xp.get(skill_name, 0)

func get_level(skill_name: String) -> int:
	var xp := get_xp(skill_name)
	var level := 0
	while _cumulative_xp_for_level(level + 1) <= xp:
		level += 1
	return level

## Total XP required to reach `level` from 0 (not the delta from level-1).
func _cumulative_xp_for_level(level: int) -> int:
	return XP_PER_LEVEL_STEP * level * (level + 1) / 2

func to_save_dict() -> Dictionary:
	return {
		"xp": _xp.duplicate(),
		"unlocked_perks": _unlocked_perks.duplicate(true),
		"sell_price_bonus": _sell_price_bonus,
		"tool_stamina_discount": _tool_stamina_discount,
	}

func from_save_dict(data: Dictionary) -> void:
	_xp = (data.get("xp", {}) as Dictionary).duplicate()
	_unlocked_perks = (data.get("unlocked_perks", {}) as Dictionary).duplicate(true)
	_sell_price_bonus = data.get("sell_price_bonus", 0.0)
	_tool_stamina_discount = data.get("tool_stamina_discount", 0.0)
