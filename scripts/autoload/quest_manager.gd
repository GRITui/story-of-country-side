extends Node
## Autoload: QuestManager
##
## Minimal quest tracking (ENG-31), sized only to gate automation-tier
## unlocks per #31's scope — not a general quest engine. Register
## QuestDefinition resources; this manager listens to the systems that
## already exist (ShippingBinManager, RelationshipManager) and flips an
## unlock flag when a quest's condition is met. Tool Upgrades (#23) and
## Infrastructure Upgrades (#24) read is_unlocked(flag) before allowing a
## purchase of the gated tier.

signal quest_completed(quest_id: String, unlock_flag: String)
signal unlock_flag_changed(flag: String, unlocked: bool)
signal quest_available(quest_id: String, title: String)

var _quests: Dictionary = {}            ## quest_id -> QuestDefinition
var _completed: Dictionary = {}         ## quest_id -> bool
var _delivered_totals: Dictionary = {}  ## item_id -> int (lifetime shipped)
var _unlocked_flags: Dictionary = {}    ## unlock_flag -> bool
var _lifetime_earned_gold: int = 0      ## ENG-91: cumulative gold earned via payouts
var _announced_available: Dictionary = {}  ## quest_id -> bool (quest_available dedup)

func _ready() -> void:
	if ShippingBinManager:
		ShippingBinManager.item_shipped.connect(_on_item_shipped)
		ShippingBinManager.payout_processed.connect(_on_payout_processed)
	if RelationshipManager:
		RelationshipManager.points_changed.connect(_on_relationship_points_changed)
	_register_default_content()

## #108 starter quest chain: teaches the core loop in order -- ship something
## (bin), watch it pay out overnight (economy), then meet a neighbor (social).
## Conditions reuse the existing types; each step unlocks the next via
## requires_quest_id so the chain reads as one guided onboarding arc.
func _register_default_content() -> void:
	var harvest := QuestCondition.new()
	harvest.type = QuestCondition.ConditionType.DELIVER_ITEM
	harvest.item_id = "parsnip"
	harvest.target_quantity = 1
	_register_starter_quest(
		"starter_first_harvest", "First Harvest",
		"Ship your first parsnip in the shipping bin out front.",
		"starter_quest_1_done", "", harvest)

	var earn := QuestCondition.new()
	earn.type = QuestCondition.ConditionType.EARN_GOLD
	earn.target_gold = 25
	_register_starter_quest(
		"starter_earn_gold", "A Growing Business",
		"Leave something in the bin overnight and collect the payout in the morning.",
		"starter_quest_2_done", "starter_first_harvest", earn)

	var friends := QuestCondition.new()
	friends.type = QuestCondition.ConditionType.FRIENDSHIP_LEVEL
	friends.npc_name = "Elena"
	friends.target_hearts = 1
	_register_starter_quest(
		"starter_meet_the_town", "Meet the Town",
		"The villagers are friendly if you're friendly first. Talk to Elena or bring her something she likes.",
		"starter_quest_3_done", "starter_earn_gold", friends)

## Registers one starter-chain quest. Content lane owns the strings/values
## above; this helper only wires the definition together.
func _register_starter_quest(quest_id: String, title: String, description: String,
		unlock_flag: String, requires_quest_id: String, condition: QuestCondition) -> void:
	var quest := QuestDefinition.new()
	quest.quest_id = quest_id
	quest.title = title
	quest.description = description
	quest.unlock_flag = unlock_flag
	quest.requires_quest_id = requires_quest_id
	quest.condition = condition
	register_quest(quest)

## The quest chain (#108): quests whose prerequisite is completed (or that
## have none) and that aren't completed themselves. Sorted for deterministic
## UI ordering. This is the read path a quest log/HUD consumes.
func get_available_quest_ids() -> Array[String]:
	var available: Array[String] = []
	for quest_id: String in _quests.keys():
		if is_completed(quest_id):
			continue
		var quest: QuestDefinition = _quests[quest_id] as QuestDefinition
		if quest == null:
			continue
		if quest.requires_quest_id.is_empty() or is_completed(quest.requires_quest_id):
			available.append(quest_id)
	available.sort()
	return available

func get_quest(quest_id: String) -> QuestDefinition:
	return _quests.get(quest_id) as QuestDefinition

## Re-registering an already-known quest_id is a no-op for its completion
## state — re-registering the same quest content at boot (as content
## reloads on every launch) shouldn't reset progress already made.
func register_quest(quest: QuestDefinition) -> void:
	if quest == null or quest.quest_id.is_empty():
		return
	_quests[quest.quest_id] = quest
	if not _completed.has(quest.quest_id):
		_completed[quest.quest_id] = false

func is_completed(quest_id: String) -> bool:
	return _completed.get(quest_id, false)

func is_unlocked(flag: String) -> bool:
	return _unlocked_flags.get(flag, false)

func delivered_count(item_id: String) -> int:
	return _delivered_totals.get(item_id, 0)

func get_lifetime_earned_gold() -> int:
	return _lifetime_earned_gold

## Forward-compatible entry point for a future skill system (#25) to call
## on level-up. No caller exists yet — see QuestCondition's skill_name doc.
func evaluate_skill_level(skill_name: String, level: int) -> void:
	for quest_id in _quests.keys():
		var quest: QuestDefinition = _quests[quest_id]
		var cond := quest.condition
		if cond == null or is_completed(quest_id):
			continue
		if cond.type == QuestCondition.ConditionType.SKILL_LEVEL \
			and cond.skill_name == skill_name and level >= cond.target_level:
			_complete_quest(quest)

func _on_payout_processed(gold_amount: int, _item_count: int) -> void:
	_lifetime_earned_gold += gold_amount
	for quest_id in _quests.keys():
		var quest: QuestDefinition = _quests[quest_id]
		var cond := quest.condition
		if cond == null or is_completed(quest_id):
			continue
		if cond.type == QuestCondition.ConditionType.EARN_GOLD \
			and _lifetime_earned_gold >= cond.target_gold:
			_complete_quest(quest)

func _on_item_shipped(item_id: String, quantity: int, _unit_price: int) -> void:
	_delivered_totals[item_id] = delivered_count(item_id) + quantity
	for quest_id in _quests.keys():
		var quest: QuestDefinition = _quests[quest_id]
		var cond := quest.condition
		if cond == null or is_completed(quest_id):
			continue
		if cond.type == QuestCondition.ConditionType.DELIVER_ITEM \
			and cond.item_id == item_id \
			and delivered_count(item_id) >= cond.target_quantity:
			_complete_quest(quest)

func _on_relationship_points_changed(npc_name: String, _points: int, hearts: int) -> void:
	for quest_id in _quests.keys():
		var quest: QuestDefinition = _quests[quest_id]
		var cond := quest.condition
		if cond == null or is_completed(quest_id):
			continue
		if cond.type == QuestCondition.ConditionType.FRIENDSHIP_LEVEL \
			and cond.npc_name == npc_name and hearts >= cond.target_hearts:
			_complete_quest(quest)

func _complete_quest(quest: QuestDefinition) -> void:
	_completed[quest.quest_id] = true
	_unlocked_flags[quest.unlock_flag] = true
	quest_completed.emit(quest.quest_id, quest.unlock_flag)
	unlock_flag_changed.emit(quest.unlock_flag, true)
	_notify_newly_available()

## Announces quests that just became available because of a completion, so a
## HUD can surface "new quest" without polling. The _announced_available dedup
## keeps a quest from being announced twice if two quests complete in the same
## event. Boot-time availability is read via get_available_quest_ids().
func _notify_newly_available() -> void:
	for quest_id in get_available_quest_ids():
		if _announced_available.has(quest_id):
			continue
		_announced_available[quest_id] = true
		var quest: QuestDefinition = _quests[quest_id] as QuestDefinition
		if quest == null:
			continue
		quest_available.emit(quest_id, quest.title)

func to_save_dict() -> Dictionary:
	return {
		"completed": _completed.duplicate(),
		"delivered_totals": _delivered_totals.duplicate(),
		"unlocked_flags": _unlocked_flags.duplicate(),
		"lifetime_earned_gold": _lifetime_earned_gold,
	}

func from_save_dict(data: Dictionary) -> void:
	_completed = (data.get("completed", {}) as Dictionary).duplicate()
	_delivered_totals = (data.get("delivered_totals", {}) as Dictionary).duplicate()
	_unlocked_flags = (data.get("unlocked_flags", {}) as Dictionary).duplicate()
	_lifetime_earned_gold = data.get("lifetime_earned_gold", 0) as int
	_announced_available = {}
