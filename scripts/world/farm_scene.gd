extends Node2D
class_name FarmScene
## Frontend (#52 sub-scope): world/tile-rendering scene for FarmPlotManager.
##
## The single biggest player-visible gap this epic had left -- FarmPlotManager
## (#13/#53) is fully logic-only (a Vector2i -> FarmPlot dictionary with no
## rendering), so nothing a player did with planting/watering/harvesting was
## ever visible. This scene renders that state reactively via a Godot
## isometric TileMap, per design/art/isometric-grid-spec.md (64x32px tile
## footprint, 2:1 ratio, TILE_SHAPE_ISOMETRIC / TILE_LAYOUT_DIAMOND_DOWN --
## the same convention the spec hands to any tilemap consumer).
##
## Grid size: 8x8 (GRID_WIDTH x GRID_HEIGHT below) -- a reasonable starter
## farm plot, matching the small-farm-in-town-view sizing precedent named in
## the isometric-grid-spec's own genre references, and small enough that a
## screenful of tiles reads clearly without a camera zoom/pan implementation
## (spec section 6 explicitly leaves zoom/pan out of scope). Not tied to any
## design-doc number -- there isn't one -- so this is this PR's own content
## placeholder, documented as such per SQUAD-SPLIT.md's content-gap norm.
##
## VISUALS (Decision E / #6 is still unresolved -- no illustrated tile art
## exists anywhere in the repo, and no image-generation tool exists in this
## environment; see squad-handshake-art.md): Art Squad replaced this
## scene's flat-color placeholder tileset with a procedurally-generated
## one (ProceduralTileArt.build_isometric_tileset, in
## scripts/world/procedural_tile_art.gd) -- real alpha-masked isometric
## diamonds with directional shading, an edge outline, and speckle-grain
## texture, still one base color per FarmPlot state:
##   empty        -> bare dirt brown   (Color(0.45, 0.36, 0.22))
##   planted      -> seedling green    (Color(0.31, 0.55, 0.25))
##   watered      -> darker wet green  (Color(0.16, 0.35, 0.32))
##   harvest_ready-> bright gold       (Color(0.86, 0.71, 0.18))
##   withered     -> ash gray          (Color(0.35, 0.32, 0.30))
## harvest_ready also gets a center-weighted glow accent (ProceduralTileArt's
## glow_states) so a ready-to-harvest tile visually calls attention to
## itself, same idea a real art pass would eventually express with a
## dedicated sprite/VFX instead.
## No crop-specific sprites, no growth-stage variants -- state alone drives
## color. A later pass with real illustrated art (human artist or an
## image-gen pipeline) should replace _build_tileset with real tile art
## without needing to touch the signal-binding logic below.
##
## Rendering model: fully reactive, no polling. _ready() does one pass over
## every (x, y) in the grid calling FarmPlotManager.get_plot(position) --
## that public getter is sufficient to enumerate this scene's own known grid
## bounds without needing a new "get all plots" backend API (there isn't
## one, and none is needed: this scene owns/defines its own grid, backend
## only needs to answer "what's at this position", which get_plot() already
## does). After that initial pass, every visual update comes from
## FarmPlotManager's public signals (crop_planted/crop_watered/
## crop_harvested/crop_withered) -- never a private field.
##
## Interaction (stretch goal, included): clicking a tile plants/waters/
## harvests it via FarmPlotManager's public methods, using a single
## hardcoded seed choice ("parsnip") for planting since there is no seed-
## selection UI/hotbar-binding yet (HUD's own docstring already flags the
## hotbar has no real item binding -- same gap, not re-solved here). This is
## a placeholder interaction model, not a designed one.

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

## Hardcoded placeholder planting choice -- see class docstring. Only used
## by the click-to-plant stretch interaction below.
const PLACEHOLDER_PLANT_CROP_ID := "parsnip"

const ATLAS_SOURCE_ID := 0

@onready var _tilemap: TileMap = $TileMap

func _ready() -> void:
	_build_tileset()
	_render_all_plots()

	FarmPlotManager.crop_planted.connect(_on_crop_planted)
	FarmPlotManager.crop_watered.connect(_on_crop_watered)
	FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	FarmPlotManager.crop_withered.connect(_on_crop_withered)

## Builds one TileSet at runtime via ProceduralTileArt -- see class
## docstring and scripts/world/procedural_tile_art.gd for why there's no
## art asset to load instead. tile_shape/tile_layout/tile_size match
## design/art/isometric-grid-spec.md sections 1-2 exactly (enforced inside
## the shared generator).
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_READY])

func _render_all_plots() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

## Re-derives a tile's visual state from FarmPlotManager.get_plot() -- the
## single source of truth -- rather than tracking any scene-local duplicate
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
## get_plot(position) would report STATE_EMPTY by the time this runs --
## paint the withered color directly instead of re-deriving from state, so
## the player sees the wither happen rather than the tile silently going
## back to bare dirt. It reverts to whatever _refresh_tile would compute the
## next time this position changes (a future plant, etc.).
func _on_crop_withered(position: Vector2i, _crop_id: String) -> void:
	if _in_grid(position):
		_paint_tile(position, STATE_WITHERED)

## Click-to-interact stretch goal (see class docstring): a single click
## plants (if empty), waters (if planted and not yet watered today), or
## harvests (if ready) -- one action per click, cycling through the plot's
## lifecycle. Whichever FarmPlotManager call applies returns false and is a
## silent no-op if its own preconditions aren't met (wrong season, already
## watered, etc.) -- this scene never duplicates that validation.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	var plot: FarmPlot = FarmPlotManager.get_plot(position)
	if plot == null or plot.is_empty():
		FarmPlotManager.plant(position, PLACEHOLDER_PLANT_CROP_ID)
	elif plot.harvest_ready:
		FarmPlotManager.harvest(position)
	elif not plot.watered_today:
		FarmPlotManager.water(position)
