extends Node2D
class_name MineScene
## Frontend (#52 sub-scope): world/tile-rendering scene for MiningManager.
##
## Same gap FarmScene/RanchScene/ForageScene closed for their own
## managers: MiningManager (#16/#53) is fully logic-only (a per-floor
## Vector2i -> tile-state dictionary with no rendering), so nothing about
## breaking rock or descending floors was ever visible. This scene renders
## that state reactively via a Godot isometric TileMap, per
## design/art/isometric-grid-spec.md (same 64x32px footprint /
## TILE_SHAPE_ISOMETRIC / TILE_LAYOUT_DIAMOND_DOWN convention every prior
## world scene in this repo already uses).
##
## Grid size: read from MiningManager.get_floor_size() rather than a
## scene-local constant, unlike FarmScene/RanchScene/ForageScene's fixed
## grids -- MiningManager already owns FLOOR_WIDTH/FLOOR_HEIGHT as its own
## content decision (5x5), so this scene defers to that instead of
## duplicating the number.
##
## MiningManager's own per-tile state (has_rock/ore_item_id/broken) is a
## private dictionary with only has_rock(tile) exposed publicly -- no
## getter reveals whether a rock secretly holds ore before it's broken.
## That's a deliberate design property (ore is a surprise on break, per
## rock_broken's own item_id payload), not a gap this scene works around:
## every rock tile renders identically regardless of what's inside it.
##
## VISUALS (Decision E / #6 still unresolved, same blocker every prior
## frontend scene has documented; no image-generation tool exists in this
## environment either, see squad-handshake-art.md): Art Squad replaced
## this scene's flat-color placeholder tileset with a procedurally-
## generated one (ProceduralTileArt.build_isometric_tileset, in
## scripts/world/procedural_tile_art.gd) -- real alpha-masked isometric
## diamonds with directional shading, an edge outline, and speckle-grain
## texture, still one base color per tile state:
##   rock (unbroken)  -> mine wall gray  (Color(0.38, 0.36, 0.34))
##   floor (broken)   -> cleared floor   (Color(0.20, 0.18, 0.16))
##   ladder           -> descent gold    (Color(0.70, 0.58, 0.22))
## No visual distinction between plain stone and ore-bearing rock (can't
## be, see above), no per-ore-type sprite variety once broken (the tile
## just becomes floor). A later pass with real art (human artist or an
## image-gen pipeline) should replace _build_tileset with real tile/prop
## art without needing to touch the signal-binding logic below.
##
## Rendering model: fully reactive, no polling. _ready() does one pass
## over every (x, y) in the current floor's grid calling
## MiningManager.has_rock()/get_ladder_position() -- both public. After
## that, every visual update comes from MiningManager's public signals
## (rock_broken/floor_descended) -- never a private field. floor_descended
## regenerates the entire floor server-side, so this scene does a full
## re-render pass on that signal rather than trying to diff individual
## tiles.
##
## Interaction: clicking a rock tile breaks it via MiningManager.break_rock();
## clicking the ladder tile descends via MiningManager.descend_ladder().
## MiningManager.descend_ladder() itself has no concept of player
## position/standing-on-the-ladder (its own docstring calls that a
## frontend concern) -- this placeholder interaction model clicks the
## ladder tile directly rather than implementing player movement/
## proximity, same "placeholder interaction, not a designed one"
## disclosure FarmScene/RanchScene/ForageScene's docstrings all make.

const TILE_WIDTH := 64
const TILE_HEIGHT := 32

const STATE_ROCK := 0
const STATE_FLOOR := 1
const STATE_LADDER := 2

const STATE_COLORS := {
	STATE_ROCK: Color(0.38, 0.36, 0.34),
	STATE_FLOOR: Color(0.20, 0.18, 0.16),
	STATE_LADDER: Color(0.70, 0.58, 0.22),
}

const ATLAS_SOURCE_ID := 0

@onready var _tilemap: TileMap = $TileMap

func _ready() -> void:
	_build_tileset()
	_render_all_tiles()

	MiningManager.rock_broken.connect(_on_rock_broken)
	MiningManager.floor_descended.connect(_on_floor_descended)

## Same shared ProceduralTileArt approach as every prior world scene --
## see class docstring for why there's no art asset to load instead.
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID)

func _render_all_tiles() -> void:
	var floor_size := MiningManager.get_floor_size()
	for x in range(floor_size.x):
		for y in range(floor_size.y):
			_refresh_tile(Vector2i(x, y))

func _refresh_tile(tile: Vector2i) -> void:
	_paint_tile(tile, _tile_state(tile))

func _tile_state(tile: Vector2i) -> int:
	if tile == MiningManager.get_ladder_position():
		return STATE_LADDER
	if MiningManager.has_rock(tile):
		return STATE_ROCK
	return STATE_FLOOR

func _paint_tile(tile: Vector2i, state: int) -> void:
	_tilemap.set_cell(0, tile, ATLAS_SOURCE_ID, Vector2i(state, 0))

func _in_grid(tile: Vector2i) -> bool:
	var floor_size := MiningManager.get_floor_size()
	return tile.x >= 0 and tile.x < floor_size.x and tile.y >= 0 and tile.y < floor_size.y

func _on_rock_broken(tile: Vector2i, _item_id: String, _quantity: int) -> void:
	if _in_grid(tile):
		_refresh_tile(tile)

## floor_descended means MiningManager regenerated the entire floor
## (new ladder position, fresh rock/ore layout) -- a full re-render, not a
## single-tile refresh, mirrors the scope of the backend change.
func _on_floor_descended(_new_floor_index: int) -> void:
	_render_all_tiles()

## Click-to-interact (see class docstring): mirrors every prior world
## scene's _unhandled_input pattern exactly.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(tile: Vector2i) -> void:
	if not _in_grid(tile):
		return
	if tile == MiningManager.get_ladder_position():
		MiningManager.descend_ladder()
	elif MiningManager.has_rock(tile):
		MiningManager.break_rock(tile)
