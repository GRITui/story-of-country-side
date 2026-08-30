extends Node2D
class_name PlayerAvatar
## Frontend (#100): the player's own on-screen representation in every world
## scene -- previously a disembodied cursor, per the issue's own framing
## ("Player avatar: a visible main character in world scenes (you are
## currently a disembodied cursor)"). Adds a bottom-anchored Sprite2D
## NPCController already uses (see that file's and
## scripts/npc/procedural_character_art.gd's docstrings for the "no
## image-generation tool / no illustrated art asset" disclosure this
## shares), tinted a fixed PLAYER_COLOR distinct from any NPC's
## name-hashed tint, so the player always reads as the same visual
## identity across scenes and never coincidentally matches an NPC.
##
## Minimal viable embodiment per #100's own ask list:
## 1. One simple player sprite placed in each world scene at a sensible
##    anchor -- see farm_scene.gd et al's _add_player_avatar().
## 2. Pseudo-moves toward the last tile clicked (move_to()), with 4-dir
##    facing via flip_h on horizontal movement. No full walk-cycle
##    animation -- explicitly not required v1 per the issue.
## 3. Tool-use feedback: pulse_tool_use() briefly tints the sprite when a
##    tool action actually fires on the clicked tile. Callers (each world
##    scene's own _handle_tile_click) decide when that counts -- this node
##    has no opinion on which manager call constitutes "tool use".
## 4. Position persists across actions within the same scene visit simply
##    by being an ordinary child node that isn't recreated on every click.
##    A scene swap (main_controller.travel_to()) frees the whole world
##    scene -- this node included -- and the next scene's _ready() places
##    a fresh one at its own anchor. That's "reset per scene swap", which
##    #100 explicitly accepts as fine for v1.
##
## Explicitly NOT built here, per the issue's own "out of scope v1" list:
## collision physics, a free camera, a clothing system, or animation sets
## beyond facing+swing.
##
## #101 update: this node now also supports direct, input-driven movement
## (move_by_input()) alongside the original click-to-move (move_to()) --
## see this file's own docstring on move_by_input() for the precedence
## rule between the two. Each world scene decides when to call which;
## this node still has no opinion on where its target/direction inputs
## come from, keeping it agnostic to any particular grid shape or input
## binding scheme.

signal arrived()

const SPRITE_HEIGHT_PX := 48
## Fixed warm-red tint, deliberately outside NPCController's own
## hue/sat/val band (name-hashed hue at 0.45 sat / 0.85 val) so the player
## never coincidentally renders the same color as an NPC.
const PLAYER_COLOR := Color(0.82, 0.28, 0.24)
const ARRIVAL_THRESHOLD_PX := 1.0
## Brief brightening multiplier applied to the sprite's modulate for the
## tool-swing feedback pulse (#100 ask item 3).
const SWING_PULSE_COLOR := Color(1.5, 1.5, 1.15)

## JRL pack (feat/jrl-art-pack, #196) — 384×256, 24×32 cells, 8 rows ×16 cols
## Rows: 0 idle, 1 walk, 2 sit_engawa, 3 hoe/kuwa, 4 plant, 5 net/bug_net, 6 fish/bamboo_rod, 7 bow
## Cols: 16 = 4 dirs ×4 frames (Down, Up, Left, Right ×4). Bottom-center pivot feet y=31 cx=11.5
## Variants: player_jp_winter.png / player_jp_yukata.png (palette swaps, not wired yet)
const SHEET_PATH := "res://assets/16bit/characters/player_jp.png"
const FRAME_W := 24
const FRAME_H := 32
const FRAME_COUNT := 4
const ANIM_FPS := 8.0
## Tool swing + holding — PO-16BIT-GFX-2
const TOOL_SWING_FRAMES := 3
const TOOL_SWING_FPS := 12.0
const HOLDING_OFFSET := Vector2(0, -22) # overhead 8px above head (head top y=2, head 18px)

@export var move_speed_px_per_sec: float = 90.0

## PO-16BIT-HCI-3: 12x8 feet collision — bottom-center anchored at position (feet).
const FEET_WIDTH := 12.0
const FEET_HEIGHT := 8.0
const FEET_COLLISION_SIZE := Vector2(FEET_WIDTH, FEET_HEIGHT)

var _target_position: Vector2
var _has_target := false
var _sprite: Sprite2D
var _uses_sheet := false
var _anim_timer := 0.0
var _frame_index := 0
# Tool swing / holding state — PO-16BIT-GFX-2
var _is_swinging := false
var _swing_frame := 0
var _swing_timer := 0.0
var _holding := false
var _holding_sprite: Sprite2D = null
# PO-16BIT-HCI-3: world bounds + blocked rects for 12x8 feet clamp.
var _world_bounds := Rect2()
var _has_world_bounds := false
var _blocked_rects: Array[Rect2] = []

## Last non-zero movement direction, in this node's local screen-space
## (not grid space) -- updated by both move_by_input() and the click-to-
## move step in _process(). Defaults to "facing down" (toward the viewer),
## a reasonable idle default before the avatar has ever moved. World
## scenes read this to resolve an "adjacent tile" for the interact action
## (#101) without this node needing any grid/TileMap awareness itself.
var facing: Vector2 = Vector2.DOWN

func _ready() -> void:
	_sprite = _build_sprite()
	add_child(_sprite)
	_target_position = position
	_has_target = true

func _build_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	var sheet: Texture2D = load(SHEET_PATH)
	if sheet == null or sheet.get_image() == null:
		push_error("Missing 16-bit player asset: %s" % SHEET_PATH)
		return sprite
	_uses_sheet = true
	sprite.texture = sheet
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(FRAME_W, FRAME_H))
	sprite.centered = false
	sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
	return sprite


func _update_sprite_frame(moving: bool, delta: float) -> void:
	if not _uses_sheet:
		return
	# Tool swing overrides walk/idle — JRL pack has dedicated action rows (3 hoe/kuwa, 4 plant, etc.)
	if _is_swinging:
		_swing_timer += delta
		if _swing_timer >= 1.0 / TOOL_SWING_FPS:
			_swing_timer -= 1.0 / TOOL_SWING_FPS
			_swing_frame += 1
			if _swing_frame >= TOOL_SWING_FRAMES:
				_is_swinging = false
				_swing_frame = 0
				_swing_timer = 0.0
		var dir := _facing_dir_index()
		var action_row := 3 # hoe/kuwa row
		var swing_frame_map := [0, 1, 0]
		_frame_index = swing_frame_map[_swing_frame]
		var col := dir * FRAME_COUNT + _frame_index
		_sprite.region_rect = Rect2(Vector2(col * FRAME_W, action_row * FRAME_H), Vector2(FRAME_W, FRAME_H))
		if _swing_frame == 0:
			_sprite.offset = Vector2(-FRAME_W / 2.0 + 1, -FRAME_H + 1)
		elif _swing_frame == 1:
			_sprite.offset = Vector2(-FRAME_W / 2.0 - 1, -FRAME_H - 1)
		else:
			_sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
		_sprite.flip_h = false
		return
	if moving:
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer -= 1.0 / ANIM_FPS
			_frame_index = (_frame_index + 1) % FRAME_COUNT
	else:
		_frame_index = 0
		_anim_timer = 0.0
	var dir := _facing_dir_index()
	var action_row := 1 if moving else 0 # 0 idle, 1 walk
	var col := dir * FRAME_COUNT + _frame_index
	_sprite.region_rect = Rect2(Vector2(col * FRAME_W, action_row * FRAME_H), Vector2(FRAME_W, FRAME_H))
	_sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
	_sprite.flip_h = false
	if _holding and _holding_sprite:
		_holding_sprite.position = HOLDING_OFFSET

func _facing_dir_index() -> int:
	# JRL sheet dir order: Down(0), Up(1), Left(2), Right(3) ×4 frames
	if facing.y < -0.3 and absf(facing.y) > absf(facing.x):
		return 1 # up
	elif facing.x < -0.3:
		return 2 # left
	elif facing.x > 0.3:
		return 3 # right
	else:
		return 0 # down

func _facing_row() -> int:
	return _facing_dir_index() # compat alias

## PO-16BIT-GFX-2: 3-frame tool swing hook — Anticipation→Impact→Recovery.
## Call instead of pulse_tool_use for full animation; keeps pulse as fallback.
func play_tool_swing() -> void:
	if not _uses_sheet:
		pulse_tool_use()
		return
	_is_swinging = true
	_swing_frame = 0
	_swing_timer = 0.0
	_anim_timer = 0.0

func is_swinging() -> bool:
	return _is_swinging

## PO-16BIT-GFX-2: Holding overhead pose — shows item sprite 8px above head.
func set_holding(holding: bool, item_texture: Texture2D = null) -> void:
	_holding = holding
	if holding:
		if _holding_sprite == null:
			_holding_sprite = Sprite2D.new()
			_holding_sprite.centered = true
			_holding_sprite.position = HOLDING_OFFSET
			add_child(_holding_sprite)
		if item_texture != null:
			_holding_sprite.texture = item_texture
		_holding_sprite.visible = true
	else:
		if _holding_sprite != null:
			_holding_sprite.visible = false

func is_holding() -> bool:
	return _holding

## Sets a new movement target in this scene's local coordinate space.
## Callers pass whatever local position their own tile-click handler
## already resolved (typically _tilemap.map_to_local(cell)) -- this node
## never resolves tile coordinates itself, so it stays agnostic to
## whichever grid shape (farm/ranch/mine/forage) the calling scene uses.
func move_to(target: Vector2) -> void:
	_target_position = target
	_has_target = true

## Direct, input-driven movement (#101): moves this node immediately, this
## frame, in `direction` (expected pre-normalized, e.g. from
## Input.get_vector) at move_speed_px_per_sec. A zero direction is a no-op
## -- callers should simply not call this when nothing is pressed, rather
## than passing Vector2.ZERO, so an idle avatar just holds position.
##
## Precedence rule vs. move_to(): any non-zero direction here immediately
## cancels a pending click-to-move target (_has_target = false), so
## keyboard input always wins over an in-flight click move -- pressing a
## movement key interrupts walking toward a stale click target rather than
## fighting it every frame. Releasing all movement keys does not resume
## the click target; the avatar simply stops. This is a documented product
## decision, not an oversight: re-clicking (or pressing a key again) is a
## simpler mental model than a walk that silently resumes toward an old
## click the player may no longer want.
## PO-16BIT-HCI-3: feet rect at given world position (bottom-center anchor).
func get_feet_rect(at_pos: Vector2 = Vector2.INF) -> Rect2:
	var p := at_pos if at_pos != Vector2.INF else position
	return Rect2(p.x - FEET_WIDTH * 0.5, p.y - FEET_HEIGHT, FEET_WIDTH, FEET_HEIGHT)

func would_collide(at_pos: Vector2) -> bool:
	var feet := get_feet_rect(at_pos)
	if _has_world_bounds and not _world_bounds.encloses(feet):
		return true
	for r in _blocked_rects:
		if feet.intersects(r):
			return true
	return false

func set_world_bounds(bounds: Rect2) -> void:
	_world_bounds = bounds
	_has_world_bounds = true

func clear_world_bounds() -> void:
	_has_world_bounds = false

func set_blocked_rects(rects: Array[Rect2]) -> void:
	_blocked_rects = rects

func add_blocked_rect(r: Rect2) -> void:
	_blocked_rects.append(r)

func _try_move(desired: Vector2) -> Vector2:
	if not would_collide(desired):
		return desired
	# Axis-separated slide — try X then Y for 8-way feel, else block.
	var try_x := Vector2(desired.x, position.y)
	var try_y := Vector2(position.x, desired.y)
	var can_x := not would_collide(try_x)
	var can_y := not would_collide(try_y)
	if can_x and not can_y:
		return try_x
	if can_y and not can_x:
		return try_y
	if can_x and can_y:
		# Prefer larger axis progress (keeps diagonal slide intuitive).
		if absf(desired.x - position.x) > absf(desired.y - position.y):
			return try_x
		return try_y
	return position

func move_by_input(direction: Vector2, delta: float) -> void:
	if direction == Vector2.ZERO:
		_update_sprite_frame(false, delta)
		return
	_has_target = false
	facing = direction.normalized()
	if not _uses_sheet and absf(facing.x) > 0.01:
		_sprite.flip_h = facing.x < 0.0
	var desired := position + facing * move_speed_px_per_sec * delta
	position = _try_move(desired)
	_update_sprite_frame(true, delta)

func _process(delta: float) -> void:
	if not _has_target:
		_update_sprite_frame(false, delta)
		return
	var to_target := _target_position - position
	var dist := to_target.length()
	if dist <= ARRIVAL_THRESHOLD_PX:
		if position != _target_position:
			var clamped_target := _target_position
			if would_collide(clamped_target):
				_has_target = false
			else:
				position = clamped_target
			arrived.emit()
		_update_sprite_frame(false, delta)
		return
	if not _uses_sheet and absf(to_target.x) > 0.5:
		_sprite.flip_h = to_target.x < 0.0
	facing = to_target.normalized()
	var step := move_speed_px_per_sec * delta
	var desired: Vector2
	if step >= dist:
		desired = _target_position
	else:
		desired = position + facing * step
	var next_pos := _try_move(desired)
	# If blocked and can't advance, cancel target (don't jitter against wall).
	if next_pos == position and desired != position:
		_has_target = false
		_update_sprite_frame(false, delta)
		return
	position = next_pos
	if position == _target_position:
		arrived.emit()
		_has_target = false
	_update_sprite_frame(true, delta)

## Tool-use feedback (#100 ask item 3): a brief tint pulse on the sprite.
## Call this right after a world scene's own tool-action call succeeds
## (e.g. FarmPlotManager.water() actually watering a plot).
func pulse_tool_use() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", SWING_PULSE_COLOR, 0.08)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
