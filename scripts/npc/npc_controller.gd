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

enum Direction { DOWN, UP, LEFT, RIGHT }
enum AnimationState { IDLE, WALKING }
var _current_direction: int = Direction.DOWN
var _current_animation_state: int = AnimationState.IDLE

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
	
	# Create animated sprite with placeholder frames for IDLE/WALKING animations
	var anim_sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	
	# Add idle frame (use the same silhouette texture)
	frames.add_frame("idle_down", texture)
	frames.add_frame("idle_up", texture)
	frames.add_frame("idle_left", texture)
	frames.add_frame("idle_right", texture)
	
	# Add walking frame (slightly dimmer for movement)
	var walking_texture := texture.duplicate()
	walking_texture.get_image().fill(Color(1.0, 1.0, 1.0, 0.7), Rect2i(0, 0, walking_texture.get_width(), walking_texture.get_height()))
	frames.add_frame("walk_down", walking_texture)
	frames.add_frame("walk_up", walking_texture)
	frames.add_frame("walk_left", walking_texture)
	frames.add_frame("walk_right", walking_texture)
	
	anim_sprite.sprite_frames = frames
	anim_sprite.animation = "idle_down"
	anim_sprite.play()
	add_child(anim_sprite)

## Deterministic per-name tint so repeated NPCs (or a scene re-entered
## after save/load) always render the same NPC the same color, without
## needing any stored/authored color list.
func _color_for_npc_name(name: String) -> Color:
	var h: int = absi(hash(name if name != "" else "npc"))
	return Color.from_hsv(float(h % 360) / 360.0, 0.45, 0.85)

func _on_minute_passed(hour: int, minute: int) -> void:
	_refresh_target(hour, minute)

## Frontend (#102): NPCs should now have movement animations.
## The procedural_character_art.gd provides the placeholder sprites, but we
## need movement animations like PlayerAvatar: idle/walking with directional
## facing. This method updates animation state based on current movement.
func _update_animation() -> void:
	if _current_target == null:
		# Idle animation
		_set_animation_state(AnimationState.IDLE)
	else:
		# Walking animation - determine direction to target
		var to_target := _current_target.position - position
		var direction := Vector2i.ZERO
		
		if abs(to_target.x) > abs(to_target.y):
			direction.x = sign(to_target.x)
		else:
			direction.y = sign(to_target.y)
		
		# Convert to Direction enum for animation
		var facing_dir := _vector_to_direction(direction)
		_set_direction(facing_dir)
		_set_animation_state(AnimationState.WALKING)

## Sets the NPC's direction for animation purposes.
func _set_direction(direction: int) -> void:
	_current_direction = direction

## Sets the NPC's animation state.
func _set_animation_state(state: int) -> void:
	_current_animation_state = state

## Returns the current facing direction as a Vector2i for grid-based movement.
func get_facing() -> Vector2i:
	var direction := Vector2i.ZERO
	if _current_target != null:
		var to_target := _current_target.position - position
		if abs(to_target.x) > abs(to_target.y):
			direction.x = sign(to_target.x)
		else:
			direction.y = sign(to_target.y)
	return direction

## Converts Vector2i to Direction enum for animation purposes.
func _vector_to_direction(vector: Vector2i) -> int:
	if vector.x < 0:
		return Direction.LEFT
	elif vector.x > 0:
		return Direction.RIGHT
	elif vector.y < 0:
		return Direction.UP
	else:
		return Direction.DOWN

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
	
	# Update animation state based on movement
	_update_animation()

func is_at_target() -> bool:
	return _current_target != null and position.distance_to(_current_target.position) <= ARRIVAL_THRESHOLD_PX

func current_location_name() -> String:
	return _current_target.location_name if _current_target else ""
