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
const SPRITE_HEIGHT_PX := 48

var _current_target: NPCScheduleEntry = null
var _was_at_target := false

func _ready() -> void:
	_add_placeholder_sprite()
	if TimeManager:
		TimeManager.minute_passed.connect(_on_minute_passed)
		_refresh_target(TimeManager.hour, TimeManager.minute)

## Art Squad (#52 adjacent sub-scope): this Node2D had no visual
## representation at all before this -- see procedural_character_art.gd's
## docstring. Adds a bottom-anchored Sprite2D child (per
## design/art/isometric-grid-spec.md section 4's object-anchor convention)
## tinted deterministically from npc_name, so distinct NPCs read as
## visually distinct even before any real character art exists. Purely a
## visual addition -- no change to schedule/movement/signal logic below.
func _add_placeholder_sprite() -> void:
	var texture := ProceduralCharacterArt.build_silhouette_texture(_color_for_npc_name(npc_name), SPRITE_HEIGHT_PX)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	add_child(sprite)

## Deterministic per-name tint so repeated NPCs (or a scene re-entered
## after save/load) always render the same NPC the same color, without
## needing any stored/authored color list.
func _color_for_npc_name(name: String) -> Color:
	var h: int = absi(hash(name if name != "" else "npc"))
	return Color.from_hsv(float(h % 360) / 360.0, 0.45, 0.85)

func _on_minute_passed(hour: int, minute: int) -> void:
	_refresh_target(hour, minute)

func _refresh_target(hour: int, minute: int) -> void:
	if schedule == null:
		return
	var season := TimeManager.current_season() if TimeManager else "Spring"
	var weather := WeatherManager.get_current_weather() if WeatherManager else "Any"
	var new_target := schedule.get_target_for(hour, minute, season, weather)
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
