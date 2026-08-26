class_name QuestCondition
extends Resource
## One quest's completion condition. Sized only to what #31 needs to gate
## automation tiers — not a general quest-scripting system.

enum ConditionType { DELIVER_ITEM, FRIENDSHIP_LEVEL, SKILL_LEVEL, EARN_GOLD }

@export var type: ConditionType = ConditionType.DELIVER_ITEM

## DELIVER_ITEM: lifetime shipped quantity of item_id reaches target_quantity.
@export var item_id: String = ""
@export var target_quantity: int = 0

## FRIENDSHIP_LEVEL: the named NPC's heart level reaches target_hearts.
@export var npc_name: String = ""
@export var target_hearts: int = 0

## SKILL_LEVEL: named skill reaches target_level. No SkillManager exists in
## this repo yet (#25 not built) — this condition type can be authored and
## checked via QuestManager.evaluate_skill_level(), but nothing calls that
## automatically until a real skill system exists to call it. Forward-
## compatible scaffolding, not a claim that skill-gated quests fire on
## their own today.
@export var skill_name: String = ""
@export var target_level: int = 0

## EARN_GOLD: cumulative gold earned via payouts reaches target_gold.
@export var target_gold: int = 0
