extends Node2D
class_name FarmScene
## Frontend (#52 sub-scope + Squad Alpha P0 #100/#93): world/tile-rendering
## scene for FarmPlotManager + visible player avatar.
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
## diamonds with directional shading, an edge outline, and speckle-grain
## texture, still one base color per FarmPlot state:
##   empty        -> bare dirt brown   (Color(0.45, 0.36, 0.22))
##   planted      -> seedling green    (Color(0.31, 0.55, 0.25))
##   watered      -> darker wet green  (Color(0.16, 0.35, 0.32))
##   harvest_ready-> bright gold       (Color(0.86, 0.71, 0.18))
##   withered     -> ash gray          (Color(0.35, 0.32, 0.30))
## glow_states) so a ready-to-harvest tile visually calls attention to
## itself, same idea a real art pass would eventually express with a
## dedicated sprite/VFX instead.
## No crop-specific sprites, no growth-stage variants -- state alone drives
## color. A later pass with real illustrated art (human artist or an
## image-gen pipeline) should replace _build_tileset with real tile art
## without needing to touch the signal-binding logic below.
##
## Decorative props (Studio Head-greenlit free-asset pass, see
## verified CC0-1.0 from the pack's own bundled License.txt, not just a
## mirror's label) placed as static, non-interactive set dressing around
## the grid's border -- Sprite2D nodes, not TileMap tiles, so they don't
## touch the click-to-interact/signal logic at all. Ground tiles still
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
##
## Villagers (#102): the shipped NPC-schedule/relationship backend
## (NPCController/NPCSchedule, RelationshipManager, MarriageManager) had no
## scene presence anywhere in the repo -- six villagers existed only as
## names in a gift/relationship menu. Elena and Priya (see
## npc_roster.gd's own docstring for the archetype-to-scene mapping) are
## instantiated here per NPCRoster's placeholder daily schedule, walking
## between grid positions across the day exactly like the player avatar
## does, just driven by NPCSchedule instead of input/clicks. Dynamic
## entities (player + villagers) now sit under a YSort-enabled
## `_dynamic_layer` node per design/art/isometric-grid-spec.md section 4's
## depth-sorting convention -- decorative props stay direct scene children
## since they're static border dressing outside the playable grid, not
## something that needs draw-order resolution against a moving entity.
## Clicking a villager's sprite opens RelationshipsOverlay (the existing
## gift/relationship UI, already reachable from the pause menu) instead of
## acting on whatever tile is behind them -- #102's own "smallest possible
## interaction" scope guard: no new dialog system, just a shortcut to UI
## that already exists.
##
## Squad Alpha branch commentary (unioned per QA merge guidance; the merged file ships base's PlayerAvatar contract -- see player_avatar.gd):
## FarmPlot rendering unchanged from the pre-avatar implementation (reactive
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
## Matches NPCRoster.NPC_HOME_SCENE's "Farm" value -- see npc_roster.gd.
const HOME_SCENE_NAME := "Farm"

## Real illustrated CC0 decorative props (see class docstring). grid_pos is
## deliberately outside the 0..GRID_WIDTH/HEIGHT-1 playable range -- border
## set dressing, never on top of an interactive plot.

## Generated 16-bit props (assets/16bit/props/) — bottom-center anchored,
## placed at border grid positions via TileMap.map_to_local. Complements the

const DECORATIVE_PROPS := [
	{"path": "res://assets/16bit/props/tree.png", "grid_pos": Vector2i(-1, 1)},
	{"path": "res://assets/16bit/props/tree_2.png", "grid_pos": Vector2i(-1, 3)},
	{"path": "res://assets/16bit/props/pine.png", "grid_pos": Vector2i(-1, 7)},
	{"path": "res://assets/16bit/props/fruit_tree.png", "grid_pos": Vector2i(8, 2)},
	{"path": "res://assets/16bit/props/bush.png", "grid_pos": Vector2i(9, 1)},
	{"path": "res://assets/16bit/props/farmhouse.png", "grid_pos": Vector2i(3, -2)},
	{"path": "res://assets/16bit/props/barn.png", "grid_pos": Vector2i(-1, 0)},
	{"path": "res://assets/16bit/props/coop.png", "grid_pos": Vector2i(8, 5)},
	{"path": "res://assets/16bit/props/well.png", "grid_pos": Vector2i(9, 3)},
	{"path": "res://assets/16bit/props/fence_h.png", "grid_pos": Vector2i(1, -1)},
	{"path": "res://assets/16bit/props/fence_v.png", "grid_pos": Vector2i(-1, 5)},
	{"path": "res://assets/16bit/props/shipping_bin.png", "grid_pos": Vector2i(8, 6)},
	# PO-16BIT-GFX-2 Japanese placeholders (reuse 16bit prop pipeline, documented in 16bit-style-guide)
	{"path": "res://assets/16bit/props/kawara_roof.png", "grid_pos": Vector2i(3, -1)},
	{"path": "res://assets/16bit/props/jizo_statue.png", "grid_pos": Vector2i(9, 5)},
]

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar
var _shop_overlay: ShopOverlay
var _relationships_overlay: RelationshipsOverlay
var _dynamic_layer: Node2D
var _npcs: Array[NPCController] = []

func _ready() -> void:
	_build_tileset()
	_render_all_plots()
	_add_decorative_props()
	_add_dynamic_layer()
	_add_player_avatar()
	_add_villagers()
	_add_day_night_overlay()
	_wire_avatar_collision()
	_ensure_mobile_controls()
	_ensure_canvas_focus()

	FarmPlotManager.crop_planted.connect(_on_crop_planted)
	FarmPlotManager.crop_watered.connect(_on_crop_watered)
	FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	FarmPlotManager.crop_withered.connect(_on_crop_withered)

## PO-16BIT-GFX-2 Day/Night LUT — CanvasModulate + ColorRect overlay driven by TimeManager.hour.
## Layer: Canopy→Weather/DayNight overlay (top). Minimal, deterministic, no shader.
func _add_day_night_overlay() -> void:
	var overlay := DayNightOverlay.new()
	add_child(overlay)

## Builds one TileSet at runtime: tries to load generated 16-bit tiles
## (assets/16bit/tiles/*.png, 64x32 isometric diamonds per
## if any PNG is missing. Tile shape/layout/size stay locked to the spec's
## 64x32 / TILE_SHAPE_ISOMETRIC / TILE_LAYOUT_DIAMOND_DOWN convention.
func _build_tileset() -> void:
	var png_map := {
		STATE_EMPTY: "res://assets/16bit/tiles/grass.png",
		STATE_PLANTED: "res://assets/16bit/tiles/farmland.png",
		STATE_WATERED: "res://assets/16bit/tiles/farmland_watered.png",
		STATE_READY: "res://assets/16bit/tiles/grass_clover.png",
		STATE_WITHERED: "res://assets/16bit/tiles/dirt.png"
	}
	var tileset := _try_build_pixelart_tileset(png_map, [STATE_READY])
	_tilemap.tile_set = tileset

## Attempts to build an atlas TileSet from the PNGs in png_map (state->path).
## Returns null if any file is missing or image extraction fails, letting
## tile_shape/layout/size contract.
func _try_build_pixelart_tileset(png_map: Dictionary, _glow_states: Array = []) -> TileSet:
	var states: Array = png_map.keys()
	states.sort()
	var textures: Dictionary = {}
	for state in states:
		var tex: Texture2D = load(png_map[state])
		if tex == null or tex.get_image() == null:
			push_error("Missing 16-bit tile asset: %s" % png_map[state])
			continue
		textures[state] = tex
	if textures.size() != png_map.size():
		push_error("16-bit tileset build failed: missing required PNGs")
	var atlas_img := Image.create(TILE_WIDTH * states.size(), TILE_HEIGHT, false, Image.FORMAT_RGBA8)
	for i in range(states.size()):
		if not textures.has(states[i]):
			continue
		var tex: Texture2D = textures[states[i]]
		var img: Image = tex.get_image()
		var w: int = mini(img.get_width(), TILE_WIDTH)
		var h: int = mini(img.get_height(), TILE_HEIGHT)
		atlas_img.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(i * TILE_WIDTH, 0))
	var atlas_tex := ImageTexture.create_from_image(atlas_img)
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = Vector2i(TILE_WIDTH, TILE_HEIGHT)
	var src := TileSetAtlasSource.new()
	src.texture = atlas_tex
	src.texture_region_size = Vector2i(TILE_WIDTH, TILE_HEIGHT)
	for i in range(states.size()):
		src.create_tile(Vector2i(i, 0))
	tile_set.add_source(src, ATLAS_SOURCE_ID)
	return tile_set


func _render_all_plots() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

## Instantiates DECORATIVE_PROPS + PIXELART_PROPS as bottom-anchored
## Sprite2D children (see class docstring) -- map_to_local() already applies
## the isometric transform, same as the interactive plot cells, so props line
## up with the grid without duplicating the coordinate math. Missing files
## are skipped (fallback-safe for headless/CI where imports may lag).
func _add_decorative_props() -> void:
	for prop in DECORATIVE_PROPS:
		var texture: Texture2D = load(prop["path"])
		if texture == null:
			push_error("Missing 16-bit prop asset: %s" % prop["path"])
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
		sprite.position = _tilemap.map_to_local(prop["grid_pos"])
		add_child(sprite)


func _add_player_avatar() -> void:
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2))
	_dynamic_layer.add_child(_player_avatar)

## PO-16BIT-HCI-3: 12x8 feet collision — clamp avatar feet to grid bounds + prop blockers.
## World bounds derived from TileMap extents; blocked rects from decorative props that are
## solid (farmhouse, barn, fences, well, shipping_bin). Responsive via TileMap.map_to_local.
func _wire_avatar_collision() -> void:
	if _player_avatar == null or _tilemap == null:
		return
	# World bounds: grid extents expanded by half-tile so feet stay inside playable area.
	var origin: Vector2 = _tilemap.map_to_local(Vector2i(0, 0))
	var far: Vector2 = _tilemap.map_to_local(Vector2i(GRID_WIDTH - 1, GRID_HEIGHT - 1))
	var min_x := minf(origin.x, far.x) - TILE_WIDTH * 0.5
	var max_x := maxf(origin.x, far.x) + TILE_WIDTH * 0.5
	var min_y := minf(origin.y, far.y) - TILE_HEIGHT * 0.5
	var max_y := maxf(origin.y, far.y) + TILE_HEIGHT * 0.5
	_player_avatar.set_world_bounds(Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y)))
	# Blocked rects: each decorative prop's feet 12x8 box expanded as solid.
	var blocks: Array[Rect2] = []
	for prop in DECORATIVE_PROPS:
		var gp: Vector2 = _tilemap.map_to_local(prop["grid_pos"])
		# House/barn/coop etc are solid — 48x32 approximate; fences narrower.
		var path: String = prop["path"]
		var is_fence := path.contains("fence")
		var w := 24.0 if is_fence else 56.0
		var h := 16.0 if is_fence else 32.0
		blocks.append(Rect2(gp.x - w * 0.5, gp.y - h, w, h))
	_player_avatar.set_blocked_rects(blocks)

func _ensure_mobile_controls() -> void:
	if has_node("/root/MobileControls"):
		return
	# Lazy instantiate mobile overlay if on touch device; MobileControls itself decides visibility.
	var mc: Node = load("res://scenes/ui/MobileControls.tscn").instantiate()
	add_child(mc)

func _ensure_canvas_focus() -> void:
	# Focus safety — Godot viewport focus is automatic; ensure HTML5 canvas is focused on mount/click.
	if has_node("/root/InputMapManager"):
		var imm: Node = get_node("/root/InputMapManager")
		if imm.has_method("ensure_canvas_focus"):
			imm.ensure_canvas_focus()

## Depth-sort container (#102, design/art/isometric-grid-spec.md section 4):
## a single YSort-enabled Node2D parent for every dynamic entity (player +
## villagers) so draw order falls out of screen-Y automatically instead of
## being hand-maintained. Created at runtime rather than in the .tscn --
## same "no scene-file edit needed" approach every other scene-local node
## here already uses (props, avatar).
func _add_dynamic_layer() -> void:
	_dynamic_layer = Node2D.new()
	_dynamic_layer.name = "DynamicLayer"
	_dynamic_layer.y_sort_enabled = true
	add_child(_dynamic_layer)

## Villagers (#102): one NPCController per villager whose NPCRoster home
## scene is this one -- see npc_roster.gd's own docstring for the
## archetype-to-scene mapping and placeholder-schedule disclosure. Schedule
## positions are converted through this scene's own TileMap so they land on
## the same grid the player avatar and click-to-interact tiles already use.
func _add_villagers() -> void:
	for npc_name in NPCRoster.npcs_for_scene(HOME_SCENE_NAME):
		var npc := NPCController.new()
		npc.npc_name = npc_name
		npc.schedule = NPCRoster.build_schedule(npc_name, _tilemap)
		_dynamic_layer.add_child(npc)
		_npcs.append(npc)

## Hit-tests a scene-local point (same coordinate space as _tilemap and
## _player_avatar.position, e.g. from _tilemap.to_local(mouse_pos)) against
## each villager's bottom-anchored sprite bounding box (see
## procedural_character_art.gd: SPRITE_HEIGHT_PX tall, ~0.6x as wide,
## anchored bottom-center at the NPCController's own position). A small
## padding keeps a near-miss click still registering as an NPC click,
## matching how forgiving a real click target should feel at this sprite
## size. Returns null if no villager's box contains the point.
func _npc_at_local_point(local_pos: Vector2) -> NPCController:
	const HALF_WIDTH := 20.0
	const HEIGHT := 54.0
	for npc in _npcs:
		if local_pos.x >= npc.position.x - HALF_WIDTH and local_pos.x <= npc.position.x + HALF_WIDTH \
				and local_pos.y <= npc.position.y and local_pos.y >= npc.position.y - HEIGHT:
			return npc
	return null

## Villager click (#102 ask #4): opens the existing RelationshipsOverlay --
## same overlay the pause menu's "Relationships" button already opens, no
## new dialog/UI. `_npc_name` isn't threaded into the overlay (it lists
## every villager, not just the clicked one) -- the "smallest possible
## interaction" scope guard explicitly rules out a new focused/scrolled
## variant for v1.
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
## get_plot(position) would report STATE_EMPTY by the time this runs —
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
	# Prevent window scroll — consume wheel events (Godot doesn't scroll window but HTML5 host does).
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
				or event.button_index == MOUSE_BUTTON_WHEEL_LEFT or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_ensure_canvas_focus()
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var clicked_npc := _npc_at_local_point(local_pos)
		if clicked_npc != null:
			_open_relationships_for(clicked_npc.npc_name)
			return
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)
	elif event.is_action_pressed("interact") or event.is_action_pressed("secondary_action") or event.is_action_pressed("primary_action"):
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
		_player_avatar.play_tool_swing()
