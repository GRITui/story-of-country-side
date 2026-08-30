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

## Pixelart spritesheet spec matching assets/pixelart/characters/<name>.png:
## 48x120, 3 rows x 2 frames, frame 24x40, rows 0=down 1=up 2=side (flip_h).
const FRAME_W := 24
const FRAME_H := 40
const FRAME_COUNT := 2
const ANIM_FPS := 4.0

var _current_target: NPCScheduleEntry = null
var _was_at_target := false
var _sprite: Sprite2D
var _uses_sheet := false
var _anim_timer := 0.0
var _frame_index := 0
var _facing: Vector2 = Vector2.DOWN

func _ready() -> void:
	_add_character_sprite()
	if TimeManager:
		TimeManager.minute_passed.connect(_on_minute_passed)
		_refresh_target(TimeManager.hour, TimeManager.minute)

## Tries generated pixelart sheet (sana.png etc.) first, falls back to the
## procedural silhouette tinted deterministically from npc_name.
func _add_character_sprite() -> void:
	_sprite = Sprite2D.new()
	var sheet_path := "res://assets/pixelart/characters/%s.png" % npc_name.to_lower()
	var sheet: Texture2D = load(sheet_path) if npc_name != "" else null
	if sheet == null and npc_name != "":
		# Fallback: try exact name as stored (e.g. capital letter file already lowercase)
		sheet = load("res://assets/pixelart/characters/%s.png" % npc_name) as Texture2D
	if sheet != null:
		_uses_sheet = true
		_sprite.texture = sheet
		_sprite.region_enabled = true
		_sprite.region_rect = Rect2(Vector2.ZERO, Vector2(FRAME_W, FRAME_H))
		_sprite.centered = false
		_sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
	else:
		_uses_sheet = false
		var texture := ProceduralCharacterArt.build_silhouette_texture(_color_for_npc_name(npc_name), SPRITE_HEIGHT_PX)
		_sprite.texture = texture
		_sprite.centered = false
		_sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	add_child(_sprite)

## Back-compat alias used by older scene wiring or tests that call the
## placeholder method directly.
func _add_placeholder_sprite() -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		_add_character_sprite()

func _update_sprite_frame(moving: bool, delta: float) -> void:
	if not _uses_sheet:
		return
	if moving:
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer -= 1.0 / ANIM_FPS
			_frame_index = (_frame_index + 1) % FRAME_COUNT
	else:
		_frame_index = 0
		_anim_timer = 0.0
	var row := 0
	if absf(_facing.x) > absf(_facing.y):
		row = 2
	elif _facing.y < 0:
		row = 1
	else:
		row = 0
	_sprite.region_rect = Rect2(Vector2(_frame_index * FRAME_W, row * FRAME_H), Vector2(FRAME_W, FRAME_H))
	if row == 2:
		_sprite.flip_h = _facing.x < 0.0

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
		_update_sprite_frame(false, delta)
		return
	if _current_target == null:
		_update_sprite_frame(false, delta)
		return
	var to_target := _current_target.position - position
	var dist := to_target.length()
	if dist <= ARRIVAL_THRESHOLD_PX:
		position = _current_target.position
		if not _was_at_target:
			_was_at_target = true
			arrived_at.emit(_current_target.location_name)
		_update_sprite_frame(false, delta)
		return
	_facing = to_target.normalized()
	var step := move_speed_px_per_sec * delta
	var moving := dist > ARRIVAL_THRESHOLD_PX
	if step >= dist:
		position = _current_target.position
	else:
		position += _facing * step
	_update_sprite_frame(moving, delta)

func is_at_target() -> bool:
	return _current_target != null and position.distance_to(_current_target.position) <= ARRIVAL_THRESHOLD_PX

func current_location_name() -> String:
	return _current_target.location_name if _current_target else ""
