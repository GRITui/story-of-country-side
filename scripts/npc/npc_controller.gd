class_name NPCController
extends Node2D
## Drives one NPC: reads its NPCSchedule against TimeManager's clock and
## walks toward the current target position. Pauses while TimeManager is
## frozen (menus/cutscenes/festivals), same as the rest of the world.

signal arrived_at(location_name: String)

@export var npc_name: String = ""
@export var schedule: NPCSchedule
@export var move_speed_px_per_sec: float = 60.0

const ARRIVAL_THRESHOLD_PX := 1.0

var _current_target: NPCScheduleEntry = null
var _was_at_target := false

func _ready() -> void:
	if TimeManager:
		TimeManager.minute_passed.connect(_on_minute_passed)
		_refresh_target(TimeManager.hour, TimeManager.minute)

func _on_minute_passed(hour: int, minute: int) -> void:
	_refresh_target(hour, minute)

func _refresh_target(hour: int, minute: int) -> void:
	if schedule == null:
		return
	var season := TimeManager.current_season() if TimeManager else "Spring"
	var new_target := schedule.get_target_for(hour, minute, season)
	if new_target != _current_target:
		_current_target = new_target
		_was_at_target = false

func _process(delta: float) -> void:
	if TimeManager and TimeManager.is_frozen():
		return
	if _current_target == null:
		return
	var to_target := _current_target.position - position
	var dist := to_target.length()
	if dist <= ARRIVAL_THRESHOLD_PX:
		position = _current_target.position
		if not _was_at_target:
			_was_at_target = true
			arrived_at.emit(_current_target.location_name)
		return
	var step := move_speed_px_per_sec * delta
	if step >= dist:
		position = _current_target.position
	else:
		position += to_target.normalized() * step

func is_at_target() -> bool:
	return _current_target != null and position.distance_to(_current_target.position) <= ARRIVAL_THRESHOLD_PX

func current_location_name() -> String:
	return _current_target.location_name if _current_target else ""
