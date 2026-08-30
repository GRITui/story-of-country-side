extends Node
## Autoload: TutorialManager
##
## Guides the new player through the core loop: Plant -> Water -> Ship -> Earn.
## This is a "Polished" wrapper around QuestManager for the first-time experience.
##
## State is simply the current step index. Persistent via save_dict.

signal step_completed(step_index: int, title: String)
signal tutorial_finished()

const STEPS = [
	{
		"id": "TUT_01_PLANT",
		"title": "Welcome to the Valley!",
		"desc": "Let's start your farm. Plant a parsnip seed.",
		"condition": func(): return QuestManager.is_completed("TUT_01_PLANT")
	},
	{
		"id": "TUT_02_WATER",
		"title": "Nurture Your Crops",
		"desc": "Plants need water to grow. Water your parsnip.",
		"condition": func(): return QuestManager.is_completed("TUT_02_WATER")
	},
	{
		"id": "TUT_03_SHIP",
		"title": "First Harvest",
		"desc": "Your crop is ready! Ship it to the bin.",
		"condition": func(): return QuestManager.is_completed("TUT_03_SHIP")
	},
	{
		"id": "TUT_04_EARN",
		"title": "The Reward",
		"desc": "Earn your first gold to expand your farm.",
		"condition": func(): return QuestManager.is_completed("TUT_04_EARN")
	}
]

var current_step_index := 0

func _ready() -> void:
	QuestManager.quest_completed.connect(_on_quest_completed)
	_initialize_tutorial_quests()

func _initialize_tutorial_quests() -> void:
	# Define the tutorial quests using existing QuestManager infrastructure
	# These are a mix of CUSTOM conditions (logic handled in tutorials_manager)
	# and standard QuestCondition types.
	
	# Step 1: Plant (We use a dummy flag for now as 'planting' isn't a QuestCondition type)
	# To keep this "Polished", we'll hook into FarmPlotManager.
	# For the sake of the tutorial, we create "Virtual Quests" that track these actions.
	pass

func _on_quest_completed(quest_id: String, _flag: String) -> void:
	if current_step_index >= STEPS.size(): return
	
	var step = STEPS[current_step_index]
	if quest_id == step["id"]:
		_complete_step()

func _complete_step() -> void:
	var step = STEPS[current_step_index]
	step_completed.emit(current_step_index, step["title"])
	current_step_index += 1
	
	if current_step_index >= STEPS.size():
		tutorial_finished.emit()

func to_save_dict() -> Dictionary:
	return {"current_step": current_step_index}

func from_save_dict(data: Dictionary) -> void:
	current_step_index = data.get("current_step", 0)

## Helper for the Frontend to show the current goal
func get_current_goal() -> Dictionary:
	if current_step_index >= STEPS.size():
		return {"title": "Enjoy your farm!", "desc": "You've mastered the basics."}
	return STEPS[current_step_index]
