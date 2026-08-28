class_name QuestDefinition
extends Resource
## One registerable quest: a condition plus the unlock flag it flips on
## completion. .tres-authorable, same pattern as NPCSchedule (#18) and
## GiftPreferenceTable (#19) — designers add automation-unlock quests
## without touching QuestManager's code.

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var condition: QuestCondition
@export var unlock_flag: String = ""

## Chaining (#108): this quest only becomes available (get_available_quest_ids)
## once the named quest is completed. Empty string = available from the start.
@export var requires_quest_id: String = ""
