extends Node2D
class_name PlayerAvatar
## Frontend (#100): the player's own on-screen representation in every world
## scene -- previously a disembodied cursor, per the issue's own framing
## ("Player avatar: a visible main character in world scenes (you are
## currently a disembodied cursor)"). Adds a bottom-anchored Sprite2D
## placeholder using the same ProceduralCharacterArt generator
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

@export var move_speed_px_per_sec: float = 90.0

var _target_position: Vector2
var _has_target := false
var _sprite: Sprite2D

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
	var texture := ProceduralCharacterArt.build_silhouette_texture(PLAYER_COLOR, SPRITE_HEIGHT_PX)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	return sprite

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
func move_by_input(direction: Vector2, delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	_has_target = false
	facing = direction.normalized()
	if absf(facing.x) > 0.01:
		_sprite.flip_h = facing.x < 0.0
	position += facing * move_speed_px_per_sec * delta

func _process(delta: float) -> void:
	if not _has_target:
		return
	var to_target := _target_position - position
	var dist := to_target.length()
	if dist <= ARRIVAL_THRESHOLD_PX:
		if position != _target_position:
			position = _target_position
			arrived.emit()
		return
	if absf(to_target.x) > 0.5:
		_sprite.flip_h = to_target.x < 0.0
	facing = to_target.normalized()
	var step := move_speed_px_per_sec * delta
	if step >= dist:
		position = _target_position
		arrived.emit()
	else:
		position += facing * step

## Tool-use feedback (#100 ask item 3): a brief tint pulse on the sprite.
## Call this right after a world scene's own tool-action call succeeds
## (e.g. FarmPlotManager.water() actually watering a plot).
func pulse_tool_use() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", SWING_PULSE_COLOR, 0.08)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
