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

## Strict 16-bit chibi spec (32x32, 1:2.3, 55% head):
## 128x128, 4 rows x 4 frames, frame 32x32, rows 0=down(front),1=left(3/4),2=right(3/4),3=up(back)
## Walk 4F: Contact L | Pass | Contact R | Pass — 1px head bob, hair delayed 1F
const FRAME_W := 32
const FRAME_H := 32
const FRAME_COUNT := 4
const ANIM_FPS := 8.0

var _current_target: NPCScheduleEntry = null
var _was_at_target := false
var _sprite: Sprite2D
var _uses_sheet := false
var _anim_timer := 0.0
var _frame_index := 0
var _facing: Vector2 = Vector2.DOWN

## PO-16BIT-WORLD-4 waypoint pathfinding (simple lerp across tile colliders, no full A*).
## When a schedule target changes, _waypoints holds detour points around blocked rects.
var _waypoints: Array[Vector2] = []
var _waypoint_index: int = 0
var _blocked_rects: Array[Rect2] = []
## Optional emote sprite above head for gifting affinity feedback
var _emote_sprite: Sprite2D = null

func _ready() -> void:
	_add_character_sprite()
	if TimeManager:
		TimeManager.minute_passed.connect(_on_minute_passed)
		_refresh_target(TimeManager.hour, TimeManager.minute)

## Tries generated 16-bit sheet (sana.png etc.) first, falls back gracefully.
func _add_character_sprite() -> void:
	_sprite = Sprite2D.new()
	var sheet: Texture2D = null
	var sheet_path := ""
	if npc_name != "":
		for cand in [
			"res://assets/16bit/characters/%s.png" % npc_name.to_lower(),
			"res://assets/16bit/characters/%s.png" % npc_name.to_lower().replace(" ", "_"),
			"res://assets/16bit/characters/%s.png" % npc_name,
			"res://assets/16bit/characters/%s.png" % npc_name.replace(" ", "_"),
		]:
			sheet_path = cand
			if ResourceLoader.exists(cand):
				var maybe: Texture2D = load(cand)
				if maybe and maybe.get_image():
					sheet = maybe
					break
	if sheet == null:
		# Fallback: generate procedural silhouette via ProceduralCharacterArt if present, else blank
		# Keep node valid so pos/waypoint tests don't null-ref; push warning only if npc_name was set
		if npc_name != "":
			push_error("Missing 16-bit character asset: %s" % sheet_path)
		add_child(_sprite)
		return
	_uses_sheet = true
	_sprite.texture = sheet
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(Vector2.ZERO, Vector2(FRAME_W, FRAME_H))
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
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
	if _facing.y < -0.3 and absf(_facing.y) > absf(_facing.x):
		row = 3
	elif _facing.x < -0.3:
		row = 1
	elif _facing.x > 0.3:
		row = 2
	else:
		row = 0
	_sprite.region_rect = Rect2(Vector2(_frame_index * FRAME_W, row * FRAME_H), Vector2(FRAME_W, FRAME_H))
	_sprite.flip_h = false


func _on_minute_passed(hour: int, minute: int) -> void:
	_refresh_target(hour, minute)

func set_blocked_rects(rects: Array[Rect2]) -> void:
	_blocked_rects = rects

func set_waypoints(path: Array[Vector2]) -> void:
	_waypoints = path
	_waypoint_index = 0

## Builds a simple waypoint path from current position to target, detouring around _blocked_rects.
func _rebuild_waypoints() -> void:
	if _current_target == null:
		_waypoints.clear()
		_waypoint_index = 0
		return
	_waypoints = WorldMap.get_waypoint_path(position, _current_target.position, _blocked_rects)
	_waypoint_index = 0

func _current_waypoint() -> Vector2:
	if _waypoint_index < _waypoints.size():
		return _waypoints[_waypoint_index]
	if _current_target:
		return _current_target.position
	return position

func _advance_waypoint() -> void:
	if _waypoint_index < _waypoints.size():
		_waypoint_index += 1

## Gifting / affinity interaction — Talk and Gift via RelationshipManager, with emote + dialogue hook.
## Talk: +TALK_POINTS affinity, once per day per NPC. Gift: uses Inventory consumption + affinity delta via gift table.
func talk() -> bool:
	var ok := RelationshipManager.talk_to(npc_name)
	if ok:
		_show_emote("heart")
	return ok

func gift(item_id: String) -> bool:
	if not InventoryManager.has_item(item_id, 1):
		return false
	var before := RelationshipManager.get_points(npc_name)
	var ok := RelationshipManager.give_gift_by_npc_name(npc_name, item_id)
	if not ok:
		return false
	InventoryManager.remove_item(item_id, 1)
	var after := RelationshipManager.get_points(npc_name)
	var delta := after - before
	if delta >= 45:
		_show_emote("heart")
	elif delta >= 20:
		_show_emote("surprise")
	elif delta < 0:
		_show_emote("anger")
	else:
		_show_emote("sweatdrop")
	return true

func _show_emote(emote: String) -> void:
	if _emote_sprite == null:
		_emote_sprite = Sprite2D.new()
		_emote_sprite.centered = true
		_emote_sprite.position = Vector2(0, -FRAME_H - 12)
		add_child(_emote_sprite)
	var paths := {
		"heart": "res://assets/16bit/ui/icon_heart.png",
		"sweatdrop": "res://assets/16bit/ui/emote_sweatdrop.png",
		"anger": "res://assets/16bit/ui/emote_anger.png",
		"surprise": "res://assets/16bit/ui/emote_surprise.png",
	}
	var p: String = paths.get(emote, "")
	if p != "" and ResourceLoader.exists(p):
		var tex: Texture2D = load(p)
		if tex and tex.get_image():
			_emote_sprite.texture = tex
			_emote_sprite.visible = true
			var t := get_tree().create_timer(1.2) if get_tree() else null
			if t:
				t.timeout.connect(func(): if is_instance_valid(_emote_sprite): _emote_sprite.visible = false, CONNECT_ONE_SHOT)

func _refresh_target(hour: int, minute: int) -> void:
	if schedule == null:
		return
	var season := TimeManager.current_season() if TimeManager else "Spring"
	var weather := WeatherManager.get_current_weather() if WeatherManager else "Any"
	var new_target := schedule.get_target_for(hour, minute, season, weather)
	if new_target != _current_target:
		_current_target = new_target
		_was_at_target = false
		_rebuild_waypoints()

func _process(delta: float) -> void:
	if TimeManager and TimeManager.is_frozen():
		_update_sprite_frame(false, delta)
		return
	if _current_target == null:
		_update_sprite_frame(false, delta)
		return
	var waypoint := _current_waypoint()
	var to_target := waypoint - position
	var dist := to_target.length()
	if dist <= ARRIVAL_THRESHOLD_PX:
		position = waypoint
		if _waypoint_index < _waypoints.size():
			_advance_waypoint()
			# If we just reached an intermediate waypoint, don't emit arrived_at yet
			if _waypoint_index < _waypoints.size():
				_update_sprite_frame(true, delta)
				return
		# Final arrival at schedule target
		if not _was_at_target:
			_was_at_target = true
			arrived_at.emit(_current_target.location_name)
		_update_sprite_frame(false, delta)
		return
	_facing = to_target.normalized()
	var step := move_speed_px_per_sec * delta
	var moving := dist > ARRIVAL_THRESHOLD_PX
	if step >= dist:
		position = waypoint
		if _waypoint_index < _waypoints.size():
			_advance_waypoint()
	else:
		position += _facing * step
	_update_sprite_frame(moving, delta)

func is_at_target() -> bool:
	return _current_target != null and position.distance_to(_current_target.position) <= ARRIVAL_THRESHOLD_PX

func current_location_name() -> String:
	return _current_target.location_name if _current_target else ""
