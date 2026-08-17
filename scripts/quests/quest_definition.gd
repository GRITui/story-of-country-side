class_name QuestDefinition
extends Resource
## One registerable quest: a condition plus the unlock flag it flips on
## completion. .tres-authorable, same pattern as NPCSchedule (#18) and
## GiftPreferenceTable (#19) — designers add automation-unlock quests
## without touching QuestManager's code.

@export var quest_id: String = ""
@export var title: String = ""
@export var condition: QuestCondition
@export var unlock_flag: String = ""
