extends Node2D
class_name RanchScene
## Frontend (#52 sub-scope + Squad Alpha P0 #100/#93): world/tile-rendering
## scene for AnimalManager + visible player avatar.
##
## Pen rendering unchanged from pre-avatar implementation (reactive
## TileMap, ProceduralTileArt, 5x4 pens). Squad Alpha adds the same
## PlayerAvatar wiring as FarmScene: WASD/arrows, clamped to pen bounds,
## faces clicked tile, tool swing on feed/brush/collect, bed tile that
## calls TimeManager.sleep() via the public can_sleep()/sleep() API only.
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
## product ready also gets ProceduralTileArt's center-weighted glow accent
## so a ready pen visually calls attention to itself.
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
##
## Villagers (#102): Sana is instantiated here per NPCRoster's placeholder
## daily schedule (see farm_scene.gd's own docstring for the full rationale
## -- dynamic entities under a YSort `_dynamic_layer`, clicking a villager
## opens RelationshipsOverlay instead of acting on the pen behind them).
##
## Squad Alpha branch commentary (unioned per QA merge guidance; the merged file ships base's PlayerAvatar contract -- see player_avatar.gd):
## Bed tile shares the same corner as FarmScene (0,0) for consistency
## across locations — or TimeManager.sleep() can be called anywhere for now
## per spec's minimal sleep surface.

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

## Hardcoded placeholder species choice — see class docstring. Only used
## by the click-to-add stretch interaction below.
const PLACEHOLDER_SPECIES_ID := "chicken"

const ATLAS_SOURCE_ID := 0
## Matches NPCRoster.NPC_HOME_SCENE's "Ranch" value -- see npc_roster.gd.
const HOME_SCENE_NAME := "Ranch"

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar
var _relationships_overlay: RelationshipsOverlay
var _dynamic_layer: Node2D
var _npcs: Array[NPCController] = []

func _ready() -> void:
	_build_tileset()
	_render_all_pens()
	_add_dynamic_layer()
	_add_player_avatar()
	_add_villagers()

	AnimalManager.animal_added.connect(_on_animal_added)
	AnimalManager.animal_fed.connect(_on_animal_changed)
	AnimalManager.animal_brushed.connect(_on_animal_changed)
	AnimalManager.product_collected.connect(_on_product_collected)

## Same shared ProceduralTileArt approach as FarmScene._build_tileset —
## see class docstring for why there's no art asset to load instead.
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_READY])

func _render_all_pens() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

## Player avatar (#100): mirrors farm_scene.gd's _add_player_avatar --
## placed at the pen grid's center anchor on scene entry, moved toward each
## clicked pen thereafter.
func _add_player_avatar() -> void:
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2))
	_dynamic_layer.add_child(_player_avatar)

## Depth-sort container (#102) -- mirrors farm_scene.gd's
## _add_dynamic_layer() exactly, see that file for the docstring.
func _add_dynamic_layer() -> void:
	_dynamic_layer = Node2D.new()
	_dynamic_layer.name = "DynamicLayer"
	_dynamic_layer.y_sort_enabled = true
	add_child(_dynamic_layer)

## Villagers (#102) -- mirrors farm_scene.gd's _add_villagers() exactly,
## see that file's and npc_roster.gd's own docstrings.
func _add_villagers() -> void:
	for npc_name in NPCRoster.npcs_for_scene(HOME_SCENE_NAME):
		var npc := NPCController.new()
		npc.npc_name = npc_name
		npc.schedule = NPCRoster.build_schedule(npc_name, _tilemap)
		_dynamic_layer.add_child(npc)
		_npcs.append(npc)

## Mirrors farm_scene.gd's _npc_at_local_point() exactly.
func _npc_at_local_point(local_pos: Vector2) -> NPCController:
	const HALF_WIDTH := 20.0
	const HEIGHT := 54.0
	for npc in _npcs:
		if local_pos.x >= npc.position.x - HALF_WIDTH and local_pos.x <= npc.position.x + HALF_WIDTH \
				and local_pos.y <= npc.position.y and local_pos.y >= npc.position.y - HEIGHT:
			return npc
	return null

## Mirrors farm_scene.gd's _open_relationships_for()/_close_relationships()
## exactly -- see that file's docstring.
func _open_relationships_for(_npc_name: String) -> void:
	if _relationships_overlay != null and is_instance_valid(_relationships_overlay):
		return
	_relationships_overlay = load("res://scenes/ui/RelationshipsOverlay.tscn").instantiate()
	add_child(_relationships_overlay)
	_relationships_overlay.closed.connect(_close_relationships)

func _close_relationships() -> void:
	if _relationships_overlay != null and is_instance_valid(_relationships_overlay):
		_relationships_overlay.free()
	_relationships_overlay = null

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
## the time this runs (mirrors FarmScene's crop_withered timing note) —
## _refresh_tile still gives the correct post-collection state here (unlike
## a wither, collection doesn't need a distinct transient visual), so a
## plain refresh is sufficient.
func _on_product_collected(animal_id: String, _item_id: String, _quality: String, _quantity: int) -> void:
	var position := _position_for_animal_id(animal_id)
	if _in_grid(position):
		_refresh_tile(position)

## #101: direct keyboard movement -- mirrors farm_scene.gd's _process
## exactly, see that file for the precedence-rule docstring.
func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player_avatar.move_by_input(direction, delta)

## Resolves the interact-action target tile -- mirrors farm_scene.gd's
## _facing_tile() exactly.
func _facing_tile() -> Vector2i:
	return _tilemap.local_to_map(_player_avatar.position + _player_avatar.facing * TILE_HEIGHT)

## Click-to-interact stretch goal (see class docstring): mirrors FarmScene's
## _unhandled_input/_handle_tile_click pattern exactly, plus the `interact`
## action (#101) driving the same _handle_tile_click against _facing_tile().
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var clicked_npc := _npc_at_local_point(local_pos)
		if clicked_npc != null:
			_open_relationships_for(clicked_npc.npc_name)
			return
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)
	elif event.is_action_pressed("interact"):
		_handle_tile_click(_facing_tile())

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	_player_avatar.move_to(_tilemap.map_to_local(position))
	var animal_id := _animal_id_for_position(position)
	var animal: Animal = AnimalManager.get_animal(animal_id)
	var acted := false
	if animal == null:
		acted = AnimalManager.add_animal(animal_id, PLACEHOLDER_SPECIES_ID)
	elif not animal.fed_today:
		acted = AnimalManager.feed(animal_id)
	elif not animal.brushed_today:
		acted = AnimalManager.brush(animal_id)
	elif animal.product_ready:
		acted = not AnimalManager.collect_product(animal_id).is_empty()
	if acted:
		_player_avatar.pulse_tool_use()
