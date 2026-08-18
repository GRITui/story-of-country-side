extends Node
## Autoload: MarriageManager
##
## ENG-20: marriage-eligible NPCs, a proposal gated on an item + a
## RelationshipManager heart threshold, a scheduled-wedding state machine,
## and a minimal post-marriage life-change/children mechanic. Builds
## directly on RelationshipManager (#19) for the heart gate and
## InventoryManager (#13) for the proposal-item check/consumption, same
## "read the existing autoload's public API, don't invent a parallel one"
## discipline every prior backend PR followed.
##
## Single-spouse model: the player can be married to at most one NPC at a
## time (standard for the genre this is modeled after). Proposing to a
## second NPC while already married/engaged is rejected outright.
##
## --- Content-gap placeholders (no design doc content exists for any of
## these yet -- flagged explicitly per SQUAD-SPLIT.md's Content lane so a
## future Content-lane pass can retune without touching this file's logic) ---
## - MARRIAGEABLE_NPCS: a 6-name starter roster (3 bachelors, 3
##   bachelorettes, no gender-locking on who can court whom). "Elena" and
##   "Marcus" are the two names that predate this list (RelationshipManager/
##   QuestManager test fixtures) and are kept first for that reason; the
##   other four are new Content-lane additions -- still no actual character
##   writing (portraits, dialogue, backstory) exists anywhere in the repo,
##   this is just enough of a named roster that "marry someone" isn't a
##   two-person illusion. no actual NPC roster *resource* exists yet
##   (scripts/npc/ only has the schedule *data model*, not named character
##   content) -- this const list is still the only place these six names are
##   defined.
## - PROPOSAL_ITEM_ID: "mermaid_pendant", Stardew Valley's proposal-item
##   precedent per the issue text.
## - PROPOSAL_HEART_THRESHOLD: 8 of RelationshipManager.MAX_HEARTS (10) --
##   "most but not all hearts filled" on the existing 0-10 heart scale.
## - WEDDING_PREP_DAYS: 3 in-game days between a scheduled wedding and the
##   ceremony actually happening -- gives a future ceremony scene something
##   to countdown against.
## - CHILD_CHANCE_PER_SEASON: 0.15 (15%), rolled once per season start
##   (day_in_season == 1) while married, capped at MAX_CHILDREN -- a
##   deliberately minimal placeholder mechanic per the issue's own "keep
##   this genuinely minimal" instruction, not a deep parenting system.
## - MARRIED_DAILY_GOLD_BONUS: 25 gold/day once married, the "post-marriage
##   life changes" measurable benefit the issue asks for. Applied by a
##   future caller reading daily_gold_bonus() on day_started, same as
##   StaminaManager/ShippingBinManager's own day_started hooks -- this
##   autoload exposes the number and the query surface, it does not reach
##   into ShippingBinManager itself (staying decoupled from other
##   autoloads' internals, same boundary every prior manager keeps).

signal proposal_accepted(npc_name: String)
signal proposal_rejected(npc_name: String, reason: String)
signal wedding_scheduled(npc_name: String, days_until: int)
signal married(npc_name: String)
signal child_born(npc_name: String, total_children: int)

const MARRIAGEABLE_NPCS: Array[String] = ["Elena", "Marcus", "Priya", "Tobias", "Sana", "Colton"]
const PROPOSAL_ITEM_ID := "mermaid_pendant"
const PROPOSAL_HEART_THRESHOLD := 8
const WEDDING_PREP_DAYS := 3
const CHILD_CHANCE_PER_SEASON := 0.15
const MAX_CHILDREN := 3
const MARRIED_DAILY_GOLD_BONUS := 25

var _engaged_to: String = "" ## npc_name currently proposed-to-and-accepted, pending wedding
var _days_until_wedding: int = 0
var _spouse: String = "" ## npc_name currently married to, "" if unmarried
var _children: int = 0

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func is_marriageable(npc_name: String) -> bool:
	return MARRIAGEABLE_NPCS.has(npc_name)

## True only when: the NPC is marriage-eligible, the player isn't already
## engaged/married to anyone (including this same NPC), hearts meet the
## threshold, and the proposal item is on hand. Read-only -- does not
## consume the item, mirrors ToolManager.can_upgrade()'s check-first shape.
func can_propose(npc_name: String) -> bool:
	if not is_marriageable(npc_name):
		return false
	if is_engaged() or is_married():
		return false
	if RelationshipManager.get_hearts(npc_name) < PROPOSAL_HEART_THRESHOLD:
		return false
	if not InventoryManager.has_item(PROPOSAL_ITEM_ID, 1):
		return false
	return true

func is_engaged() -> bool:
	return not _engaged_to.is_empty()

func is_married() -> bool:
	return not _spouse.is_empty()

func spouse_name() -> String:
	return _spouse

func engaged_to() -> String:
	return _engaged_to

func days_until_wedding() -> int:
	return _days_until_wedding

func children_count() -> int:
	return _children

## Consumes the proposal item and, on success, immediately schedules the
## wedding (no separate "accept" step from the NPC -- once the heart/item
## gate is met the proposal always succeeds, matching the genre precedent
## this issue cites). Returns false with proposal_rejected(reason) on any
## failed precondition; never partially consumes the item.
func propose(npc_name: String) -> bool:
	if not is_marriageable(npc_name):
		proposal_rejected.emit(npc_name, "not_marriageable")
		return false
	if is_engaged() or is_married():
		proposal_rejected.emit(npc_name, "already_engaged_or_married")
		return false
	if RelationshipManager.get_hearts(npc_name) < PROPOSAL_HEART_THRESHOLD:
		proposal_rejected.emit(npc_name, "insufficient_hearts")
		return false
	if not InventoryManager.remove_item(PROPOSAL_ITEM_ID, 1):
		proposal_rejected.emit(npc_name, "missing_item")
		return false

	proposal_accepted.emit(npc_name)
	_schedule_wedding(npc_name)
	return true

func _schedule_wedding(npc_name: String) -> void:
	_engaged_to = npc_name
	_days_until_wedding = WEDDING_PREP_DAYS
	wedding_scheduled.emit(npc_name, _days_until_wedding)

## Finalizes the marriage immediately, independent of the day-countdown --
## a future ceremony scene (Frontend's territory) calls this once its
## visual sequence finishes, the same way it would call any other backend
## state-transition method. Also the path _on_day_started uses once the
## countdown reaches zero.
func marry(npc_name: String) -> bool:
	if _engaged_to != npc_name:
		return false
	_spouse = npc_name
	_engaged_to = ""
	_days_until_wedding = 0
	married.emit(npc_name)
	return true

## The measurable post-marriage benefit the issue asks for -- a future
## caller (e.g. ShippingBinManager's day-rollover consumer) adds this to
## the day's payout when is_married() is true. Returns 0 unmarried.
func daily_gold_bonus() -> int:
	return MARRIED_DAILY_GOLD_BONUS if is_married() else 0

func _on_day_started(day_in_season: int, _season: String, _day_of_week: String) -> void:
	if is_engaged():
		_days_until_wedding -= 1
		if _days_until_wedding <= 0:
			marry(_engaged_to)

	if is_married() and day_in_season == 1 and _children < MAX_CHILDREN:
		if randf() < CHILD_CHANCE_PER_SEASON:
			_children += 1
			child_born.emit(_spouse, _children)

func to_save_dict() -> Dictionary:
	return {
		"engaged_to": _engaged_to,
		"days_until_wedding": _days_until_wedding,
		"spouse": _spouse,
		"children": _children,
	}

func from_save_dict(data: Dictionary) -> void:
	_engaged_to = data.get("engaged_to", "")
	_days_until_wedding = data.get("days_until_wedding", 0)
	_spouse = data.get("spouse", "")
	_children = data.get("children", 0)
