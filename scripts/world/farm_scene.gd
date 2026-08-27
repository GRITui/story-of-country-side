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
## Decorative props (Studio Head-greenlit free-asset pass, see
## assets/kenney/isometric-miniature-farm/ATTRIBUTION.md): a handful of
## real illustrated CC0 sprites (Kenney's Isometric Miniature Farm pack --
## verified CC0-1.0 from the pack's own bundled License.txt, not just a
## mirror's label) placed as static, non-interactive set dressing around
## the grid's border -- Sprite2D nodes, not TileMap tiles, so they don't
## touch the click-to-interact/signal logic at all. Ground tiles still
## stay on ProceduralTileArt: this pack's own ground pieces measure a
## true-isometric ~1.73-1.84:1 footprint ratio, not the locked 2:1
## dimetric convention every already-shipped tile uses, so they'd
## misalign the TileMap if used as floor tiles -- a verified
## incompatibility, not a workaround, per ATTRIBUTION.md's measurements.
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
##
## Seed Shop (#123): pressing "B" toggles scenes/ui/ShopOverlay.tscn, a
## minimal restock UI for FarmPlotManager.buy_seed() -- see
## scripts/ui/shop_overlay.gd's own docstring and _toggle_shop() below.

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

## Real illustrated CC0 decorative props (see class docstring). grid_pos is
## deliberately outside the 0..GRID_WIDTH/HEIGHT-1 playable range -- border
## set dressing, never on top of an interactive plot.
const DECORATIVE_PROPS := [
	{"path": "res://assets/kenney/isometric-miniature-farm/hayBales_S.png", "grid_pos": Vector2i(-1, 3)},
	{"path": "res://assets/kenney/isometric-miniature-farm/sacksCrate_S.png", "grid_pos": Vector2i(-1, 5)},
	{"path": "res://assets/kenney/isometric-miniature-farm/fenceLow_S.png", "grid_pos": Vector2i(3, -1)},
	{"path": "res://assets/kenney/isometric-miniature-farm/cornDouble_S.png", "grid_pos": Vector2i(8, 2)},
]

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar
var _shop_overlay: ShopOverlay

func _ready() -> void:
	_build_tileset()
	_render_all_plots()
	_add_decorative_props()
	_add_player_avatar()

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

## Instantiates DECORATIVE_PROPS as bottom-anchored Sprite2D children (see
## class docstring) -- map_to_local() already applies the isometric
## transform, same as the interactive plot cells, so props line up with
## the grid without duplicating the coordinate math.
func _add_decorative_props() -> void:
	for prop in DECORATIVE_PROPS:
		var texture: Texture2D = load(prop["path"])
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
		sprite.position = _tilemap.map_to_local(prop["grid_pos"])
		add_child(sprite)

## Player avatar (#100): places a PlayerAvatar at the grid's center anchor
## on scene entry -- see player_avatar.gd's own docstring for why a scene-
## local reset-per-entry is acceptable v1. Every subsequent tile click
## moves it toward the clicked cell (see _handle_tile_click).
func _add_player_avatar() -> void:
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2))
	add_child(_player_avatar)

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

## #101: direct keyboard movement, additive alongside the click-to-move
## stand-in below -- see player_avatar.gd's move_by_input() docstring for
## the precedence rule (a movement key press cancels any in-flight click
## move). Input.get_vector already zeroes out when nothing is pressed, so
## the no-call-when-idle contract move_by_input() documents is satisfied
## by just always calling it here.
func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player_avatar.move_by_input(direction, delta)

## Resolves the tile the interact action (#101) should act on: one nominal
## tile-step in front of the avatar, in whatever direction it last faced
## (see player_avatar.gd's `facing`). Reuses the same tilemap.local_to_map()
## transform the mouse-click path already uses (both _player_avatar.position
## and the tilemap share this scene's local coordinate space), so this
## stays correct under the isometric projection without any separate
## grid-direction math.
func _facing_tile() -> Vector2i:
	return _tilemap.local_to_map(_player_avatar.position + _player_avatar.facing * TILE_HEIGHT)

## Click-to-interact stretch goal (see class docstring): a single click
## plants (if empty), waters (if planted and not yet watered today), or
## harvests (if ready) -- one action per click, cycling through the plot's
## lifecycle. Whichever FarmPlotManager call applies returns false and is a
## silent no-op if its own preconditions aren't met (wrong season, already
## watered, etc.) -- this scene never duplicates that validation.
##
## #101: the `interact` action runs the identical cycle against
## _facing_tile() instead of a clicked cell -- one shared _handle_tile_click
## body, two ways to trigger it, per the issue's own ask ("wire interact to
## whatever the avatar is adjacent to"). Mouse click remains the primary
## targeting input, per the issue's scope guard.
##
## Seed Shop toggle (#123: buy_seed() had no UI hook -- see
## scripts/ui/shop_overlay.gd's own docstring for the overlay itself).
## "B" is still checked as a raw physical keycode rather than a named
## input action -- #101 (landed the same sprint, in parallel) registered
## project.godot's [input] section for movement/interact/dialog, but no
## shop-toggle action was part of that spec, and no dedicated shopkeeper
## NPC/building exists yet either (out of scope for #123's v1), so a raw
## key check remains the simplest toggle that doesn't require either.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)
	elif event.is_action_pressed("interact"):
		_handle_tile_click(_facing_tile())
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_B:
		_toggle_shop()

func _toggle_shop() -> void:
	if _shop_overlay != null and is_instance_valid(_shop_overlay):
		_close_shop()
	else:
		_open_shop()

func _open_shop() -> void:
	_shop_overlay = load("res://scenes/ui/ShopOverlay.tscn").instantiate()
	add_child(_shop_overlay)
	_shop_overlay.closed.connect(_close_shop)

func _close_shop() -> void:
	if _shop_overlay != null and is_instance_valid(_shop_overlay):
		# free(), not queue_free() -- a re-press of "B" in the same frame
		# (or a headless test asserting the overlay is gone right after
		# closing) needs the node actually out of the tree immediately,
		# same precedent InventoryOverlay's row-removal already documents.
		_shop_overlay.free()
	_shop_overlay = null

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	_player_avatar.move_to(_tilemap.map_to_local(position))
	var plot: FarmPlot = FarmPlotManager.get_plot(position)
	var acted := false
	if plot == null or plot.is_empty():
		acted = FarmPlotManager.plant(position, PLACEHOLDER_PLANT_CROP_ID)
	elif plot.harvest_ready:
		acted = not FarmPlotManager.harvest(position).is_empty()
	elif not plot.watered_today:
		acted = FarmPlotManager.water(position)
	if acted:
		_player_avatar.pulse_tool_use()
