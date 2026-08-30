extends Node2D
class_name MountainScene
## Frontend (#107): mountainside home for the mine entrance.
##
## Same gap SeaCoastScene closes for FishingManager: MiningManager
## (#16/#53) is fully logic-only (per-floor Vector2i rock tiles + ladder)
## so the underground floors existed with no above-ground geography. This
## scene is that geography -- a rocky mountainside rendered via the same
## isometric TileMap contract every world scene already uses (64x32px,
## TILE_SHAPE_ISOMETRIC / TILE_LAYOUT_DIAMOND_DOWN, ProceduralTileArt).
##
## Grid: 8x8, same footprint as FarmScene/ForageScene/SeaCoastScene.
## No design-doc number dictates a different size; placeholder sizing
## documented as such (SQUAD-SPLIT content-gap norm).
##
## Tiles:
##   ROCK   (0)  -- scree/mountain gray, non-interactive filler.
##   PATH   (1)  -- trail dirt connecting the entrance to the grid edge.
##   ENTRANCE (2)-- mine entrance prop; clicking travels to MineScene
##                  via MainController.travel_to("Mine"). Pure travel
##                  wiring, MiningManager untouched (spec scope guard).
##   FORAGE (3) -- mountain tile currently holding an available
##                ForageNode; same overlay pattern as SeaCoastScene.
##
## Forage nodes: every non-water/path tile gets a ForageNode registered
## via ForagingManager.register_node() -- no-op on re-enter after a save
## load, mirrors ForageScene/SeaCoastScene.
##
## VISUALS: ProceduralTileArt with a high-altitude palette (rock gray,
## path tan, entrance warm gold, forage green) -- same diamond mask +
## shading pipeline. ENTRANCE and FORAGE get glow accent.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const TILE_WIDTH := 64
const TILE_HEIGHT := 32

const STATE_ROCK := 0
const STATE_PATH := 1
const STATE_ENTRANCE := 2
const STATE_FORAGE := 3

const STATE_COLORS := {
	STATE_ROCK: Color(0.42, 0.40, 0.38),
	STATE_PATH: Color(0.55, 0.48, 0.36),
	STATE_ENTRANCE: Color(0.70, 0.58, 0.22),
	STATE_FORAGE: Color(0.32, 0.52, 0.24),
}

const ATLAS_SOURCE_ID := 0

const ENTRANCE_POSITION := Vector2i(4, 2)
## Straight path from entrance down to the bottom edge so it reads as a
## trail the player would walk.
const PATH_TILES: Array[Vector2i] = [
	Vector2i(4, 3), Vector2i(4, 4), Vector2i(4, 5), Vector2i(4, 6), Vector2i(4, 7),
]

signal travel_requested(location: String)

@onready var _tilemap: TileMap = $TileMap

func _ready() -> void:
	_build_tileset()
	_register_forage_nodes()
	_render_all_tiles()

	ForagingManager.forage_gathered.connect(_on_forage_gathered)
	ForagingManager.forage_node_rerolled.connect(_on_forage_node_rerolled)

func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_ENTRANCE, STATE_FORAGE])

func _register_forage_nodes() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var pos := Vector2i(x, y)
			if pos == ENTRANCE_POSITION or pos in PATH_TILES:
				continue
			ForagingManager.register_node(pos)

func _render_all_tiles() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

func _is_entrance(pos: Vector2i) -> bool:
	return pos == ENTRANCE_POSITION

func _is_path(pos: Vector2i) -> bool:
	return pos in PATH_TILES

func _tile_state(pos: Vector2i) -> int:
	if _is_entrance(pos):
		return STATE_ENTRANCE
	if _is_path(pos):
		return STATE_PATH
	var node: ForageNode = ForagingManager.get_forage_node(pos)
	if node != null and node.is_available():
		return STATE_FORAGE
	return STATE_ROCK

func _refresh_tile(pos: Vector2i) -> void:
	_paint_tile(pos, _tile_state(pos))

func _paint_tile(pos: Vector2i, state: int) -> void:
	_tilemap.set_cell(0, pos, ATLAS_SOURCE_ID, Vector2i(state, 0))

func _in_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func get_mine_entrance_position() -> Vector2i:
	return ENTRANCE_POSITION

func _on_forage_gathered(position: Vector2i, _item_id: String, _quantity: int) -> void:
	if _in_grid(position):
		_refresh_tile(position)

func _on_forage_node_rerolled(position: Vector2i, _item_id: String) -> void:
	if _in_grid(position):
		_refresh_tile(position)

## Mine entrance click travels to MineScene. Tries MainController.travel_to
## first (the real in-game path via LOCATION_SCENE_PATHS), falls back to
## emitting travel_requested so a parent can wire it even when this scene
## is tested headless without a live MainController.
func _request_travel_to_mine() -> void:
	var main := _find_main_controller()
	if main != null and main.has_method("travel_to"):
		main.travel_to("Mine")
	else:
		travel_requested.emit("Mine")

func _find_main_controller() -> Node:
	var cur := get_tree().current_scene if get_tree() else null
	if cur != null and cur.has_method("travel_to"):
		return cur
	# Walk up the tree: this scene is a child of Main when live.
	var p := get_parent()
	while p != null:
		if p.has_method("travel_to"):
			return p
		p = p.get_parent()
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(pos: Vector2i) -> void:
	if not _in_grid(pos):
		return
	if _is_entrance(pos):
		_request_travel_to_mine()
	elif ForagingManager.is_available(pos):
		ForagingManager.gather(pos)
