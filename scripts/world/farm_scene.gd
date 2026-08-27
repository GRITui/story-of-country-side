extends Node2D
class_name FarmScene
## Frontend (#52 sub-scope + Squad Alpha P0 #100/#93): world/tile-rendering
## scene for FarmPlotManager + visible player avatar.
##
## FarmPlot rendering unchanged from the pre-avatar implementation (reactive
## TileMap, ProceduralTileArt, 8x8 grid, 64x32 isometric spec). Squad Alpha
## adds:
##   - PlayerAvatar instance (Sprite2D/4-dir/shape, shadow, tool-hold,
##     deterministic tint per save, WASD/arrows, emitted moved(Vector2i)).
##   - Avatar is centered on spawn grid (1,1), clamped to GRID_WIDTH/HEIGHT
##     tile bounds, faces the last clicked tile, and plays a tool-swing pulse
##     on every successful plant/water/harvest.
##   - Bed tile at BED_POSITION: clicking it calls TimeManager.sleep() (when
##     can_sleep()) instead of a farming action, advancing to next day 6:00 AM
##     via TimeManager's public sleep() API only — never _-fields.
##   - Movement + bed interaction both respect TimeManager.is_frozen() via the
##     avatar's own freeze check and via can_sleep() gating.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const TILE_WIDTH := 64
const TILE_HEIGHT := 32

const STATE_EMPTY := 0
const STATE_PLANTED := 1
const STATE_WATERED := 2
const STATE_READY := 3
const STATE_WITHERED := 4

const STATE_COLORS := {
	STATE_EMPTY: Color(0.45, 0.36, 0.22),
	STATE_PLANTED: Color(0.31, 0.55, 0.25),
	STATE_WATERED: Color(0.16, 0.35, 0.32),
	STATE_READY: Color(0.86, 0.71, 0.18),
	STATE_WITHERED: Color(0.35, 0.32, 0.30),
}

## Hardcoded placeholder planting choice — see class docstring. Only used
## by the click-to-plant stretch interaction below.
const PLACEHOLDER_PLANT_CROP_ID := "parsnip"

const ATLAS_SOURCE_ID := 0
## Bed for sleep interaction — top-left corner so it never collides with the
## typical starter crop area, visually still part of the same TileMap grid.
const BED_POSITION := Vector2i(GRID_WIDTH - 1, GRID_HEIGHT - 1) ## far corner, avoids (0,0) used by click-plant tests

@onready var _tilemap: TileMap = $TileMap
var _avatar: PlayerAvatar

func _ready() -> void:
	_build_tileset()
	_render_all_plots()
	_spawn_avatar()

	FarmPlotManager.crop_planted.connect(_on_crop_planted)
	FarmPlotManager.crop_watered.connect(_on_crop_watered)
	FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	FarmPlotManager.crop_withered.connect(_on_crop_withered)

## Builds one TileSet at runtime via ProceduralTileArt — see class
## docstring and scripts/world/procedural_tile_art.gd for why there's no
## art asset to load instead. tile_shape/tile_layout/tile_size match
## design/art/isometric-grid-spec.md sections 1-2 exactly (enforced inside
## the shared generator).
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_READY])

func _spawn_avatar() -> void:
	var existing := get_node_or_null("PlayerAvatar")
	if existing is PlayerAvatar:
		_avatar = existing
	else:
		var scene := load("res://scenes/world/PlayerAvatar.tscn")
		if scene != null:
			_avatar = scene.instantiate()
			add_child(_avatar)
		else:
			# Fallback if tscn not present (e.g. headless test minimal setup)
			_avatar = PlayerAvatar.new()
			_avatar.name = "PlayerAvatar"
			add_child(_avatar)
	_avatar.grid_bounds = Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT)
	_avatar.spawn_grid = Vector2i(1, 1)
	# Ensure avatar sits on a walkable tile (not the bed tile)
	_avatar.set_grid_position(Vector2i(1, 1))
	_avatar.moved.connect(_on_avatar_moved)

func _render_all_plots() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

## Re-derives a tile's visual state from FarmPlotManager.get_plot() — the
## single source of truth — rather than tracking any scene-local duplicate
## state, same "no duplicate state" discipline HUD's docstring calls out.
func _refresh_tile(position: Vector2i) -> void:
	_paint_tile(position, _plot_state(position))

func _plot_state(position: Vector2i) -> int:
	var plot: FarmPlot = FarmPlotManager.get_plot(position)
	if plot == null or plot.is_empty():
		return STATE_EMPTY
	if plot.harvest_ready:
		return STATE_READY
	if plot.watered_today:
		return STATE_WATERED
	return STATE_PLANTED

func _paint_tile(position: Vector2i, state: int) -> void:
	_tilemap.set_cell(0, position, ATLAS_SOURCE_ID, Vector2i(state, 0))

func _in_grid(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < GRID_WIDTH and position.y >= 0 and position.y < GRID_HEIGHT

func _is_bed_tile(position: Vector2i) -> bool:
	return position == BED_POSITION

func _on_crop_planted(position: Vector2i, _crop_id: String) -> void:
	if _in_grid(position):
		_refresh_tile(position)

func _on_crop_watered(position: Vector2i) -> void:
	if _in_grid(position):
		_refresh_tile(position)

func _on_crop_harvested(position: Vector2i, _item_id: String, _quality: String, _quantity: int) -> void:
	if _in_grid(position):
		_refresh_tile(position)

## crop_withered fires after FarmPlotManager has already erased the plot, so
## get_plot(position) would report STATE_EMPTY by the time this runs —
## paint the withered color directly instead of re-deriving from state, so
## the player sees the wither happen rather than the tile silently going
## back to bare dirt. It reverts to whatever _refresh_tile would compute the
## next time this position changes (a future plant, etc.).
func _on_crop_withered(position: Vector2i, _crop_id: String) -> void:
	if _in_grid(position):
		_paint_tile(position, STATE_WITHERED)

func _on_avatar_moved(_grid_pos: Vector2i) -> void:
	# Hook for future NPC interaction / footprint logic.
	pass

## Click-to-interact: bed tile triggers sleep (via TimeManager public API),
## otherwise plants/waters/harvests via FarmPlotManager public methods.
## Avatar faces the clicked tile and swings its tool on any successful
## farming action.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	if _avatar != null:
		_avatar.face_grid(position)
	# Bed interaction takes priority over farming on its tile.
	if _is_bed_tile(position):
		if TimeManager.can_sleep():
			if TimeManager.sleep():
				if _avatar != null:
					_avatar.swing_tool()
		return
	var plot: FarmPlot = FarmPlotManager.get_plot(position)
	var acted := false
	if plot == null or plot.is_empty():
		acted = FarmPlotManager.plant(position, PLACEHOLDER_PLANT_CROP_ID)
	elif plot.harvest_ready:
		var result := FarmPlotManager.harvest(position)
		acted = not result.is_empty()
	elif not plot.watered_today:
		acted = FarmPlotManager.water(position)
	if acted and _avatar != null:
		_avatar.swing_tool()
