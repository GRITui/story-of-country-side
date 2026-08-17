class_name GiftPreferenceTable
extends Resource
## One NPC's gift preferences. Designers author these as .tres resources,
## same pattern as NPCSchedule/NPCScheduleEntry (ENG-18) — no code changes
## needed to add or tune an NPC's likes.

enum Reaction { HATED, DISLIKED, NEUTRAL, LIKED, LOVED }

@export var loved_items: Array[String] = []
@export var liked_items: Array[String] = []
@export var disliked_items: Array[String] = []
@export var hated_items: Array[String] = []

func reaction_to(item_id: String) -> Reaction:
	if loved_items.has(item_id):
		return Reaction.LOVED
	if liked_items.has(item_id):
		return Reaction.LIKED
	if disliked_items.has(item_id):
		return Reaction.DISLIKED
	if hated_items.has(item_id):
		return Reaction.HATED
	return Reaction.NEUTRAL

func point_delta_for(item_id: String) -> int:
	match reaction_to(item_id):
		Reaction.LOVED:
			return 80
		Reaction.LIKED:
			return 45
		Reaction.NEUTRAL:
			return 20
		Reaction.DISLIKED:
			return -20
		Reaction.HATED:
			return -40
		_:
			return 0
