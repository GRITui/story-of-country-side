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

var _quests: Dictionary = {}            ## quest_id -> QuestDefinition
var _completed: Dictionary = {}         ## quest_id -> bool
var _delivered_totals: Dictionary = {}  ## item_id -> int (lifetime shipped)
var _unlocked_flags: Dictionary = {}    ## unlock_flag -> bool

func _ready() -> void:
	if ShippingBinManager:
		ShippingBinManager.item_shipped.connect(_on_item_shipped)
	if RelationshipManager:
		RelationshipManager.points_changed.connect(_on_relationship_points_changed)

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

func to_save_dict() -> Dictionary:
	return {
		"completed": _completed.duplicate(),
		"delivered_totals": _delivered_totals.duplicate(),
		"unlocked_flags": _unlocked_flags.duplicate(),
	}

func from_save_dict(data: Dictionary) -> void:
	_completed = (data.get("completed", {}) as Dictionary).duplicate()
	_delivered_totals = (data.get("delivered_totals", {}) as Dictionary).duplicate()
	_unlocked_flags = (data.get("unlocked_flags", {}) as Dictionary).duplicate()
