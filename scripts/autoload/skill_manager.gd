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
## Recipe/crafting unlocks and passive perks (also in #25's scope) have no
## concrete content anywhere in the design doc — same gap pattern as quest
## content (#31) and gift preferences (#19). This ships the level-tracking
## system plus level_changed as the hook a future recipe/perk system reads,
## rather than fabricating specific recipes/perks that don't exist yet.

signal xp_gained(skill_name: String, amount: int, total_xp: int)
signal level_changed(skill_name: String, new_level: int, old_level: int)

const XP_PER_LEVEL_STEP := 100 ## level N costs XP_PER_LEVEL_STEP * N to reach from N-1

var _xp: Dictionary = {} ## skill_name -> int

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
		if QuestManager:
			QuestManager.evaluate_skill_level(skill_name, level)

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
	}

func from_save_dict(data: Dictionary) -> void:
	_xp = (data.get("xp", {}) as Dictionary).duplicate()
