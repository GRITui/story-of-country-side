extends Node
## Autoload: RelationshipManager
##
## Owns per-NPC friendship points (ENG-19): talking and gifting raise points,
## hitting a heart threshold fires a heart-event trigger signal. Threshold
## crossings are tracked per NPC so a jump across more than one heart in a
## single gift (unlikely, but not impossible with a loved gift near a
## boundary) still fires once per newly-crossed heart, not once total.

signal points_changed(npc_name: String, points: int, hearts: int)
signal heart_event_triggered(npc_name: String, heart_level: int)

const POINTS_PER_HEART := 250
const MAX_HEARTS := 10
const MAX_POINTS := POINTS_PER_HEART * MAX_HEARTS
const TALK_POINTS := 20

var _points: Dictionary = {} ## npc_name -> int
var _highest_triggered_heart: Dictionary = {} ## npc_name -> int
var _talked_today: Dictionary = {} ## npc_name -> bool
var _gifted_today: Dictionary = {} ## npc_name -> bool

func _ready() -> void:
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func get_points(npc_name: String) -> int:
	return _points.get(npc_name, 0)

func get_hearts(npc_name: String) -> int:
	return get_points(npc_name) / POINTS_PER_HEART

func has_talked_today(npc_name: String) -> bool:
	return _talked_today.get(npc_name, false)

func has_gifted_today(npc_name: String) -> bool:
	return _gifted_today.get(npc_name, false)

## Returns false (no-op) if this NPC has already been talked to today —
## matches the once-per-day pattern established for stamina/time resets.
func talk_to(npc_name: String) -> bool:
	if has_talked_today(npc_name):
		return false
	_talked_today[npc_name] = true
	_add_points(npc_name, TALK_POINTS)
	return true

## Returns false (no-op) if this NPC has already received a gift today.
## `preferences` is that NPC's GiftPreferenceTable; passed in rather than
## looked up here since this system doesn't own NPC-to-preference wiring
## (that's the caller's/data layer's job, same separation StaminaManager
## keeps from the Shipping Bin economy).
func give_gift(npc_name: String, item_id: String, preferences: GiftPreferenceTable) -> bool:
	if has_gifted_today(npc_name):
		return false
	_gifted_today[npc_name] = true
	var delta := preferences.point_delta_for(item_id) if preferences else 0
	_add_points(npc_name, delta)
	return true

func _add_points(npc_name: String, delta: int) -> void:
	var new_points: int = clampi(get_points(npc_name) + delta, 0, MAX_POINTS)
	_points[npc_name] = new_points
	var hearts := new_points / POINTS_PER_HEART
	points_changed.emit(npc_name, new_points, hearts)
	_check_heart_events(npc_name, hearts)

func _check_heart_events(npc_name: String, hearts: int) -> void:
	var highest: int = _highest_triggered_heart.get(npc_name, 0)
	while highest < hearts:
		highest += 1
		heart_event_triggered.emit(npc_name, highest)
	_highest_triggered_heart[npc_name] = highest

func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	_talked_today.clear()
	_gifted_today.clear()

func to_save_dict() -> Dictionary:
	return {
		"points": _points.duplicate(),
		"highest_triggered_heart": _highest_triggered_heart.duplicate(),
	}

func from_save_dict(data: Dictionary) -> void:
	_points = (data.get("points", {}) as Dictionary).duplicate()
	_highest_triggered_heart = (data.get("highest_triggered_heart", {}) as Dictionary).duplicate()
	_talked_today.clear()
	_gifted_today.clear()
