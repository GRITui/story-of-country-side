extends Node2D
class_name ForageScene
## Frontend (#52 sub-scope): world/tile-rendering scene for ForagingManager.
##
## Same gap FarmScene/RanchScene closed for their own managers:
## ForagingManager (#17/#53) is fully logic-only (a Vector2i -> ForageNode
## dictionary), so gathering was never visible. This scene renders that
## state reactively via a Godot isometric TileMap, per
## design/art/isometric-grid-spec.md (same 64x32px footprint /
## TILE_SHAPE_ISOMETRIC / TILE_LAYOUT_DIAMOND_DOWN convention every prior
## world scene in this repo already uses).
##
## Grid size: 8x8, same as FarmScene -- a wild-forageable clearing is a
## reasonable match for the crop field's own footprint, and there's no
## design-doc number dictating otherwise (same content-gap disclosure every
## prior world scene's docstring makes, per SQUAD-SPLIT.md's norm).
##
## Unlike FarmPlotManager/AnimalManager, ForagingManager's own docstring
## explicitly hands node placement to the caller: "Frontend (or a future
## map-population step) calls [register_node] once per spot; it is not
## implied by mere lookups the way FarmPlotManager's plots are implicitly
## created by plant()." So _ready() below both populates the map (calling
## register_node() for every grid cell -- a no-op per ForagingManager's own
## contract if a node already exists there, e.g. on a scene re-enter after
## a save load) and renders it, rather than assuming some other system
## seeds the grid.
##
## VISUALS (Decision E / #6 still unresolved, same blocker every prior
## frontend scene has documented; no image-generation tool exists in this
## environment either, see squad-handshake-art.md): Art Squad replaced
## this scene's flat-color placeholder tileset with a procedurally-
## generated one (ProceduralTileArt.build_isometric_tileset, in
## scripts/world/procedural_tile_art.gd) -- real alpha-masked isometric
## diamonds with directional shading, an edge outline, and speckle-grain
## texture, still one base color per node state:
##   dormant (no season-valid item) -> bare forest floor (Color(0.30, 0.26, 0.18))
##   on cooldown (gathered recently) -> disturbed earth   (Color(0.40, 0.33, 0.22))
##   available to gather              -> lush undergrowth (Color(0.28, 0.50, 0.22))
## available-to-gather also gets ProceduralTileArt's center-weighted glow
## accent so a gatherable node visually calls attention to itself.
## No per-forageable sprite variety (wild_berries vs. mushroom, etc.) --
## out of scope for a tileset with no illustrated art asset behind it. A
## later pass with real art (human artist or an image-gen pipeline) should
## replace _build_tileset with real tile/prop art without needing to touch
## the signal-binding logic below.
##
## Rendering model: fully reactive, no polling. _ready() registers every
## grid position then reads back ForagingManager.get_forage_node() for its
## initial paint -- both public. After that, every visual update comes from
## ForagingManager's public signals (forage_gathered/forage_node_rerolled)
## -- never a private field.
##
## Interaction: clicking an available tile gathers it via
## ForagingManager.gather(); a click on a dormant/cooldown tile is a
## silent no-op (mirrors FarmScene/RanchScene's "backend validates, scene
## never duplicates that check" discipline). No click-to-add step is
## needed here (unlike RanchScene) since every grid cell is pre-registered
## by this scene itself.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const TILE_WIDTH := 64
const TILE_HEIGHT := 32

const STATE_DORMANT := 0
const STATE_COOLDOWN := 1
const STATE_AVAILABLE := 2

const STATE_COLORS := {
	STATE_DORMANT: Color(0.30, 0.26, 0.18),
	STATE_COOLDOWN: Color(0.40, 0.33, 0.22),
	STATE_AVAILABLE: Color(0.28, 0.50, 0.22),
}

const ATLAS_SOURCE_ID := 0

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar

func _ready() -> void:
	_build_tileset()
	_populate_and_render_all_nodes()
	_add_player_avatar()

	ForagingManager.forage_gathered.connect(_on_forage_gathered)
	ForagingManager.forage_node_rerolled.connect(_on_forage_node_rerolled)

## Same shared ProceduralTileArt approach as FarmScene/RanchScene -- see
## class docstring for why there's no art asset to load instead.
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_AVAILABLE])

func _populate_and_render_all_nodes() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var position := Vector2i(x, y)
			ForagingManager.register_node(position) # no-op if already registered
			_refresh_tile(position)

## Player avatar (#100): mirrors farm_scene.gd's _add_player_avatar.
func _add_player_avatar() -> void:
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2))
	add_child(_player_avatar)

func _refresh_tile(position: Vector2i) -> void:
	_paint_tile(position, _node_state(position))

func _node_state(position: Vector2i) -> int:
	var node: ForageNode = ForagingManager.get_forage_node(position)
	if node == null or node.is_empty():
		return STATE_DORMANT
	if node.is_available():
		return STATE_AVAILABLE
	return STATE_COOLDOWN

func _paint_tile(position: Vector2i, state: int) -> void:
	_tilemap.set_cell(0, position, ATLAS_SOURCE_ID, Vector2i(state, 0))

func _in_grid(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < GRID_WIDTH and position.y >= 0 and position.y < GRID_HEIGHT

func _on_forage_gathered(position: Vector2i, _item_id: String, _quantity: int) -> void:
	if _in_grid(position):
		_refresh_tile(position)

func _on_forage_node_rerolled(position: Vector2i, _item_id: String) -> void:
	if _in_grid(position):
		_refresh_tile(position)

## Click-to-interact (see class docstring): mirrors FarmScene/RanchScene's
## _unhandled_input pattern exactly.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	_player_avatar.move_to(_tilemap.map_to_local(position))
	if ForagingManager.is_available(position):
		if not ForagingManager.gather(position).is_empty():
			_player_avatar.pulse_tool_use()
