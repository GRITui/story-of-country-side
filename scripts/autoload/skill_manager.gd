extends Node
## Autoload: SkillManager
##
## Implements #116: Skill milestone perks.
## Tracks levels for various skills and grants perks at specific milestones.

signal skill_leveled(skill_name: String, new_level: int)
signal perk_unlocked(perk_id: String, description: String)

const SKILLS = ["Farming", "Mining", "Fishing", "Foraging", "Ranching"]
const MILESTONES = {
	"Farming": { 5: "Green Thumb (Crops grow 10% faster)", 10: "Master Harvester (Double yield chance)" },
	"Mining": { 5: "Steady Hand (Less stamina loss in mines)", 10: "Deep Vein (Rare ores more common)" },
	"Fishing": { 5: "Patient Angler (Faster bites)", 10: "Trophy Hunter (Higher quality fish)" },
	"Foraging": { 5: "Keen Eye (Rare items easier to find)", 10: "Nature's Friend (More foraging nodes)" },
	"Ranching": { 5: "Animal Whisperer (Higher affection gain)", 10: "Pro Breeder (Higher quality products)" }
}

var _levels: Dictionary = {} ## skill_name -> level
var _unlocked_perks: Array = []

func _ready() -> void:
	for skill in SKILLS:
		_levels[skill] = 1

func get_level(skill_name: String) -> int:
	return _levels.get(skill_name, 1)

func add_experience(skill_name: String, amount: int) -> void:
	if not _levels.has(skill_name): return
	
	var old_level = _levels[skill_name]
	# Simple leveling logic: level = sqrt(exp/10)
	# For this version, we just increment based on a threshold
	_levels[skill_name] += amount # Simplified for prototype
	
	var new_level = _levels[skill_name]
	if new_level > old_level:
		skill_leveled.emit(skill_name, new_level)
		_check_for_perks(skill_name, new_level)

## Alias for callers using the older `add_xp` name (FarmPlotManager, FishingManager,
## ForagingManager, AnimalManager, MiningManager). Keeps both names working.
func add_xp(skill_name: String, amount: int) -> void:
	add_experience(skill_name, amount)

func _check_for_perks(skill_name: String, level: int) -> void:
	if MILESTONES.has(skill_name) and MILESTONES[skill_name].has(level):
		var perk_desc = MILESTONES[skill_name][level]
		_unlocked_perks.append(perk_desc)
		perk_unlocked.emit(skill_name + "_" + str(level), perk_desc)

func to_save_dict() -> Dictionary:
	return {"levels": _levels.duplicate(), "perks": _unlocked_perks.duplicate()}

func from_save_dict(data: Dictionary) -> void:
	_levels = (data.get("levels", {}) as Dictionary).duplicate()
	_unlocked_perks = (data.get("perks", []) as Array).duplicate()
