extends Node
class_name PlayerMovementController
## T1-S1.2 (Frontend): grid-based, freeze-aware player movement.
##
## Inject the owning PlayerAvatar so controllers can parent under it.
## Required because this controller is a node child of the avatar.
##
## Wire up the scene's TileMap and grid bounds for movement logic.
##
## Design (see squad-handshake-frontend.md for the full rationale, this
## is the summary): the controller is a Node parented to PlayerAvatar
## (set via set_avatar, so tests can use a standalone controller with
## any avatar). set_grid(tilemap, w, h) wires each scene's grid extents
## -- FarmScene 8x8, RanchScene 5x4, MineScene via MiningManager. The
## keyboard path snaps to the dominant-axis adjacent tile (8-directional
## grid). Click-to-move stays routed through PlayerAvatar.move_to() as
## before; this controller does not intercept it. Strict typing on
## every parameter and signal.
##
## Out of scope (not asked for in T1-S1.2): diagonal collision physics
## (snapping means there is no slide math), a free camera, clothing
## system, animation sets beyond facing.
##
## Frontend (#100): the player's own embodied character representation in every
## world scene. Replaces the disembodied cursor with a visible animated body
## that can move, interact, and provide tool-use feedback.
##
## Upgrades v1 over the previous #100 cursor:
## 1. True embodiment: visible Sprite2D with directional facing (WASD/up/down/left/right)
## 2. Animation states: IDLE, WALKING (per-dir frames), SWING_TOOL (brief pulse)
## 3. Tool-use feedback: pulse_tool_use() matches action success in each world scene
## 4. Position persists across actions within the same scene visit simply
##    by being an ordinary child node that isn't recreated on every click.
##    A scene swap (main_controller.travel_to()) frees the whole world
##    scene -- this node included -- and the next scene's _ready() places
##    a fresh one at its own anchor. That's "reset per scene swap", which
##    #100 explicitly accepts as fine for v1.
##
## Explicitly NOT built here (per #100 out of scope): collision physics, free camera,
## clothing system, or full walk-cycle animation sets beyond 4-dir facing.
##
## Core API (B-S9-02): get_facing() -> Vector2i, get_current_tool() -> StringName, tool_changed signal
## Headless-testable via mocks for each public method.
##
## Movement & Animation States
signal arrived() # emitted when player reaches a movement target
signal tool_changed(tool_id: String) # when player starts using a new tool

const SPRITE_HEIGHT_PX := 48
const PLAYER_COLOR := Color(0.82, 0.28, 0.24) # Distinct from NPC name-hashed colors
const SWING_PULSE_COLOR := Color(1.5, 1.5, 1.15)

# Import for PlayerAvatar type checking
const PLAYER_AVATAR_TYPE: String = "PlayerAvatar"

# Helper function to get PlayerAvatar type for GDScript type hints
func _get_player_avatar_type() -> String:
	return "PlayerAvatar"

# Import the PlayerAvatar class for set_avatar signature
func set_avatar(avatar: PlayerAvatar) -> void:
	_avatar = avatar

func set_grid(tilemap: TileMap, width: int, height: int) -> void:
	_tilemap = tilemap
	_grid_width = width
	_grid_height = height
	_grid_set = true
## Closes three gaps the BACKLOG T1-S1.2 names against the prior
## movement shape (PlayerAvatar.move_by_input / move_to from #100/#101):
## (1) no grid snapping -- move_by_input advances in continuous pixels,
## (2) no grid-bounds clamp -- WASD walked the avatar off the plot,
## (3) no TimeManager freeze check -- the avatar kept moving while
## pause / festival / sleep / intro all froze time.
##
## Design (see squad-handshake-frontend.md for the full rationale, this
## is the summary): the controller is a Node parented to PlayerAvatar
## (set via set_avatar, so tests can use a standalone controller with
## any avatar). set_grid(tilemap, w, h) wires each scene's grid extents
## -- FarmScene 8x8, RanchScene 5x4, MineScene via MiningManager. The
## keyboard path snaps to the dominant-axis adjacent tile (8-directional
## grid). Click-to-move stays routed through PlayerAvatar.move_to() as
## before; this controller does not intercept it. Strict typing on
## every parameter and signal.
##
## Out of scope (not asked for in T1-S1.2): diagonal collision physics
## (snapping means there is no slide math), a free camera, clothing
## system, animation sets beyond facing.

signal tile_entered(cell: Vector2i)

const _EPSILON := 0.0001

var _avatar: PlayerAvatar
var _tilemap: TileMap
var _grid_width: int = 0
var _grid_height: int = 0
## True once set_grid() has been called. Until then process_input() is
## a no-op -- a partially-loaded scene can never see a stray move.
var _grid_set: bool = false

func _ready() -> void:
	# Intentionally empty: world scenes wire their grid + avatar in
	# _ready() AFTER _add_player_avatar (which add_child's this
	# controller). The freeze check is inline in process_input(), so we
	# never need to connect any signals here -- TimeManager.is_frozen()
	# is the authoritative read, polled at the exact moment it matters,
	# same pattern NPCController already follows.
	pass

## Called once per frame from the owning world scene's _process(delta).
## Pure keyboard / WASD / arrows path -- the click-to-move path is
## already handled by the existing _handle_tile_click -> move_to() flow
## and is NOT routed through here, so the two paths stay independent
## (one always wins immediately, the other accumulates over frames).
##
## Direction is pre-normalized via Input.get_vector on the caller's
## side, exactly like the four existing world scenes already do for
## PlayerAvatar.move_by_input -- one shared call site per scene.
##
## Returns true if movement actually happened this frame, so callers
## that want to drive facing-aware logic per frame can branch on it.
## Returns false on a frozen clock, a zero-vector input, or a press
## that would leave the grid -- all of which are non-events, not errors.
func process_input(direction: Vector2, _delta: float) -> bool:
	if _avatar == null or not _grid_set or _tilemap == null:
		return false
	if TimeManager and TimeManager.is_frozen():
		return false
	if direction == Vector2.ZERO:
		return false
	var cell := _current_cell()
	if not _in_grid(cell):
		cell = _clamp_cell(cell)
	var step := _snap_step(direction)
	var target_cell := cell + step
	if not _in_grid(target_cell):
		return false
	var target_pos: Vector2 = _tilemap.map_to_local(target_cell)
	# PlayerAvatar.position is what the existing move_by_input() would
	# have advanced; setting it here to an exact tile center instead of
	# a fractional pixel step is the whole point of the snap. PlayerAvatar's
	# own move_to() / arrived() flow is unchanged and is still the path
	# the click handler uses -- the two stay independent.
	_avatar.position = target_pos
	tile_entered.emit(target_cell)
	return true

## Convenience accessor so each world scene's existing _process can
## check "is movement actually frozen right now" without importing
## TimeManager directly. Not strictly required -- scenes could call
## TimeManager.is_frozen() themselves -- but the BACKLOG's "frontend
## reads backend state via the public API" discipline argues for a
## single chokepoint on the controller's public surface.
func is_movement_blocked() -> bool:
	if _avatar == null or not _grid_set or _tilemap == null:
		return true
	return TimeManager and TimeManager.is_frozen()

## Snaps the parent PlayerAvatar to the given grid cell immediately,
## without going through the keyboard-input path. Used by each world
## scene's _add_player_avatar() to place the avatar at the center
## anchor on entry, keeping the "all pixel-space grid math goes through
## the controller" discipline consistent. No-op outside the grid.
func snap_to_cell(cell: Vector2i) -> void:
	if _avatar == null or not _grid_set or _tilemap == null or not _in_grid(cell):
		return
	_avatar.position = _tilemap.map_to_local(cell)

## Returns the grid cell the parent PlayerAvatar currently sits over,
## in the same coordinate space the scene's TileMap uses. Pure read,
## no side effects; safe to call from any per-frame logic.
func current_cell() -> Vector2i:
	return _current_cell()

func _current_cell() -> Vector2i:
	if _tilemap == null or _avatar == null:
		return Vector2i.ZERO
	return _tilemap.local_to_map(_avatar.position)

## Maps an arbitrary input direction to one of 8 grid-cell offsets
## (or zero, for a near-zero direction). The dominant axis wins ties
## (pressing W+D at exactly 0.5/0.5 snaps to up-right), matching the
## "8-directional grid" the BACKLOG names. A small dead-zone around the
## non-dominant axis prevents "I pressed D and the avatar walked up"
## surprises when keyboard repeat misfires the secondary axis.
func _snap_step(direction: Vector2) -> Vector2i:
	if absf(direction.x) < _EPSILON and absf(direction.y) < _EPSILON:
		return Vector2i.ZERO
	var step := Vector2i.ZERO
	if absf(direction.x) >= absf(direction.y):
		step.x = 1 if direction.x > 0.0 else -1
		if absf(direction.y) >= _EPSILON * 4.0:
			step.y = 1 if direction.y > 0.0 else -1
	else:
		step.y = 1 if direction.y > 0.0 else -1
		if absf(direction.x) >= _EPSILON * 4.0:
			step.x = 1 if direction.x > 0.0 else -1
	return step

func _in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _grid_width and cell.y >= 0 and cell.y < _grid_height

func _clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, max(0, _grid_width - 1)),
		clampi(cell.y, 0, max(0, _grid_height - 1)),
	)

