extends Node2D
class_name RanchScene
## Frontend (#52 sub-scope): world/tile-rendering scene for AnimalManager.
##
## Same gap FarmScene closed for FarmPlotManager: AnimalManager (#14/#53) is
## fully logic-only (an animal_id -> Animal dictionary with no rendering or
## spatial concept at all), so nothing about feeding/brushing/collecting was
## ever visible. This scene renders that state reactively via a Godot
## isometric TileMap, per design/art/isometric-grid-spec.md (same 64x32px
## footprint / TILE_SHAPE_ISOMETRIC / TILE_LAYOUT_DIAMOND_DOWN convention
## FarmScene already established).
##
## Grid size: 5x4 (20 pens) -- smaller than FarmScene's 8x8 crop grid,
## matching the genre norm that a starter barn/coop holds far fewer animals
## than a starter crop field. Not tied to any design-doc number -- there
## isn't one -- so this is this PR's own content placeholder, per
## SQUAD-SPLIT.md's content-gap norm (same disclosure FarmScene's own
## docstring makes for its grid size).
##
## AnimalManager has no positional concept -- add_animal(animal_id,
## species_id) takes a caller-chosen id string, not a location. Rather than
## inventing scene-local duplicate state (a Vector2i -> animal_id
## dictionary this scene would have to keep in sync itself), this scene
## derives each pen's animal_id deterministically from its grid position
## ("pen_<x>_<y>") and always re-reads AnimalManager.get_animal(id) /
## has_animal(id) as the single source of truth -- same "no duplicate
## state" discipline FarmScene and HUD both follow. Every signal
## AnimalManager fires carries only an animal_id, not a position, so this
## scene parses the position back out of that same "pen_<x>_<y>" id it
## chose in the first place (see _position_for_animal_id below).
##
## VISUALS (Decision E / #6 still unresolved, same blocker every prior
## frontend scene has documented; no image-generation tool exists in this
## environment either, see squad-handshake-art.md): Art Squad replaced
## this scene's flat-color placeholder tileset with a procedurally-
## generated one (ProceduralTileArt.build_isometric_tileset, in
## scripts/world/procedural_tile_art.gd) -- real alpha-masked isometric
## diamonds with directional shading, an edge outline, and speckle-grain
## texture, still one base color per pen state:
##   empty              -> bare pen dirt   (Color(0.42, 0.34, 0.24))
##   occupied, not fed  -> neutral hay     (Color(0.62, 0.55, 0.32))
##   occupied, fed      -> content green   (Color(0.35, 0.58, 0.30))
##   product ready      -> bright gold     (Color(0.86, 0.71, 0.18))
## Species and happiness-tier detail (silver/gold quality) have no visual
## representation yet -- out of scope for a tileset with no illustrated
## art asset behind it. A later pass with real art (human artist or an
## image-gen pipeline) should replace _build_tileset with real tile/animal
## art without needing to touch the signal-binding logic below.
##
## Rendering model: fully reactive, no polling. _ready() does one pass over
## every (x, y) in the grid, deriving that pen's animal_id and calling
## AnimalManager.has_animal()/get_animal() -- both public. After that
## initial pass, every visual update comes from AnimalManager's public
## signals (animal_added/animal_fed/animal_brushed/product_collected) --
## never a private field.
##
## Interaction (stretch goal, included, mirrors FarmScene's click-to-plant):
## clicking an empty pen adds a single hardcoded starter species ("chicken")
## since there is no species-selection UI yet; clicking an occupied pen
## feeds it (if not yet fed today), else brushes it (if not yet brushed
## today), else collects its product (if ready) -- one action per click,
## cycling through the daily loop. This is a placeholder interaction model,
## not a designed one, same disclosure FarmScene's docstring makes.

const GRID_WIDTH := 5
const GRID_HEIGHT := 4
const TILE_WIDTH := 64
const TILE_HEIGHT := 32

const STATE_EMPTY := 0
const STATE_UNFED := 1
const STATE_FED := 2
const STATE_READY := 3

const STATE_COLORS := {
	STATE_EMPTY: Color(0.42, 0.34, 0.24),
	STATE_UNFED: Color(0.62, 0.55, 0.32),
	STATE_FED: Color(0.35, 0.58, 0.30),
	STATE_READY: Color(0.86, 0.71, 0.18),
}

## Hardcoded placeholder species choice -- see class docstring. Only used
## by the click-to-add stretch interaction below.
const PLACEHOLDER_SPECIES_ID := "chicken"

const ATLAS_SOURCE_ID := 0

@onready var _tilemap: TileMap = $TileMap

func _ready() -> void:
	_build_tileset()
	_render_all_pens()

	AnimalManager.animal_added.connect(_on_animal_added)
	AnimalManager.animal_fed.connect(_on_animal_changed)
	AnimalManager.animal_brushed.connect(_on_animal_changed)
	AnimalManager.product_collected.connect(_on_product_collected)

## Same shared ProceduralTileArt approach as FarmScene._build_tileset --
## see class docstring for why there's no art asset to load instead.
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID)

func _render_all_pens() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

## Deterministic position <-> animal_id mapping -- see class docstring for
## why this scene derives ids from position rather than tracking a separate
## lookup table.
func _animal_id_for_position(position: Vector2i) -> String:
	return "pen_%d_%d" % [position.x, position.y]

func _position_for_animal_id(animal_id: String) -> Vector2i:
	var parts := animal_id.split("_")
	if parts.size() != 3 or parts[0] != "pen":
		return Vector2i(-1, -1)
	return Vector2i(int(parts[1]), int(parts[2]))

func _refresh_tile(position: Vector2i) -> void:
	_paint_tile(position, _pen_state(position))

func _pen_state(position: Vector2i) -> int:
	var animal_id := _animal_id_for_position(position)
	var animal: Animal = AnimalManager.get_animal(animal_id)
	if animal == null:
		return STATE_EMPTY
	if animal.product_ready:
		return STATE_READY
	if animal.fed_today:
		return STATE_FED
	return STATE_UNFED

func _paint_tile(position: Vector2i, state: int) -> void:
	_tilemap.set_cell(0, position, ATLAS_SOURCE_ID, Vector2i(state, 0))

func _in_grid(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < GRID_WIDTH and position.y >= 0 and position.y < GRID_HEIGHT

func _on_animal_added(animal_id: String, _species_id: String) -> void:
	var position := _position_for_animal_id(animal_id)
	if _in_grid(position):
		_refresh_tile(position)

func _on_animal_changed(animal_id: String) -> void:
	var position := _position_for_animal_id(animal_id)
	if _in_grid(position):
		_refresh_tile(position)

## product_collected fires after AnimalManager has already reset
## product_ready to false, so get_animal() would report STATE_UNFED/FED by
## the time this runs (mirrors FarmScene's crop_withered timing note) --
## _refresh_tile still gives the correct post-collection state here (unlike
## a wither, collection doesn't need a distinct transient visual), so a
## plain refresh is sufficient.
func _on_product_collected(animal_id: String, _item_id: String, _quality: String, _quantity: int) -> void:
	var position := _position_for_animal_id(animal_id)
	if _in_grid(position):
		_refresh_tile(position)

## Click-to-interact stretch goal (see class docstring): mirrors FarmScene's
## _unhandled_input/_handle_tile_click pattern exactly.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	var animal_id := _animal_id_for_position(position)
	var animal: Animal = AnimalManager.get_animal(animal_id)
	if animal == null:
		AnimalManager.add_animal(animal_id, PLACEHOLDER_SPECIES_ID)
	elif not animal.fed_today:
		AnimalManager.feed(animal_id)
	elif not animal.brushed_today:
		AnimalManager.brush(animal_id)
	elif animal.product_ready:
		AnimalManager.collect_product(animal_id)
