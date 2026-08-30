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
## ladder also gets ProceduralTileArt's center-weighted glow accent so it
## visually reads as the interactive exit tile.
## No visual distinction between plain stone and ore-bearing rock (can't
## be, see above), no per-ore-type sprite variety once broken (the tile
## just becomes floor). A later pass with real art (human artist or an
## image-gen pipeline) should replace _build_tileset with real tile/prop
## art without needing to touch the signal-binding logic below.
##
## Decorative props (Studio Head-greenlit free-asset pass, see
## assets/kenney/isometric-miniature-dungeon/ATTRIBUTION.md): real
## illustrated CC0 sprites (Kenney's Isometric Miniature Dungeon pack --
## same license verification and same measured ~1.84:1 ground-tile
## incompatibility with the locked 2:1 convention as
## assets/kenney/isometric-miniature-farm's ATTRIBUTION.md documents, so
## floor/rock/ladder tiles stay on ProceduralTileArt) placed as static,
## non-interactive Sprite2D set dressing around the floor's border --
## barrels, stacked barrels, a chest, a stone column. Positions are
## computed from get_floor_size() at _ready() time, not hardcoded, since
## unlike FarmScene's fixed 8x8 grid this scene's grid size is
## MiningManager's own content decision.
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
## Villagers (#102): Colton and Tobias are instantiated here per NPCRoster's
## placeholder daily schedule (see farm_scene.gd's own docstring for the
## full rationale -- dynamic entities under a YSort `_dynamic_layer`,
## clicking a villager opens RelationshipsOverlay instead of acting on the
## tile behind them).
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

## Matches NPCRoster.NPC_HOME_SCENE's "Mine" value -- see npc_roster.gd.
const HOME_SCENE_NAME := "Mine"

## Real illustrated CC0 decorative prop textures (see class docstring).
## Paired with grid positions computed from get_floor_size() in
## _add_decorative_props() -- not hardcoded, since this scene's grid size
## isn't a fixed constant the way FarmScene's is.
const DECORATIVE_PROP_PATHS := [
	"res://assets/kenney/isometric-miniature-dungeon/barrel_S.png",
	"res://assets/kenney/isometric-miniature-dungeon/barrelsStacked_S.png",
	"res://assets/kenney/isometric-miniature-dungeon/chestClosed_S.png",
	"res://assets/kenney/isometric-miniature-dungeon/stoneColumn_S.png",
]

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar
var _relationships_overlay: RelationshipsOverlay
var _dynamic_layer: Node2D
var _npcs: Array[NPCController] = []

func _ready() -> void:
	_build_tileset()
	_render_all_tiles()
	_add_decorative_props()
	_add_dynamic_layer()
	_add_player_avatar()
	_add_villagers()

	MiningManager.rock_broken.connect(_on_rock_broken)
	MiningManager.floor_descended.connect(_on_floor_descended)

## Tries pixelart tiles first (mine_floor/mine_rock/path variants), falls
## back to ProceduralTileArt. Preserves 64x32 isometric spec.
func _build_tileset() -> void:
	var png_map := {
		STATE_ROCK: "res://assets/pixelart/tiles/mine_rock.png",
		STATE_FLOOR: "res://assets/pixelart/tiles/mine_floor.png",
		STATE_LADDER: "res://assets/pixelart/tiles/path.png",
	}
	var tileset := _try_build_pixelart_tileset(png_map, [STATE_LADDER])
	if tileset != null:
		_tilemap.tile_set = tileset
	else:
		_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_LADDER])

func _try_build_pixelart_tileset(png_map: Dictionary, _glow_states: Array = []) -> TileSet:
	var states: Array = png_map.keys()
	states.sort()
	var textures: Dictionary = {}
	for state in states:
		var tex: Texture2D = load(png_map[state])
		if tex == null or tex.get_image() == null:
			return null
		textures[state] = tex
	var atlas_img := Image.create(TILE_WIDTH * states.size(), TILE_HEIGHT, false, Image.FORMAT_RGBA8)
	for i in range(states.size()):
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

func _render_all_tiles() -> void:
	var floor_size := MiningManager.get_floor_size()
	for x in range(floor_size.x):
		for y in range(floor_size.y):
			_refresh_tile(Vector2i(x, y))

## Instantiates DECORATIVE_PROP_PATHS + pixelart mine props as bottom-
## anchored Sprite2D children. Positions are scaled from get_floor_size().
const PIXELART_MINE_PROPS := [
	"res://assets/pixelart/props/rock.png",
	"res://assets/pixelart/props/rock_large.png",
	"res://assets/pixelart/props/mine_cart.png",
	"res://assets/pixelart/props/ladder.png",
]

func _add_decorative_props() -> void:
	var floor_size := MiningManager.get_floor_size()
	var positions := [
		Vector2i(-1, 1),
		Vector2i(-1, floor_size.y - 2),
		Vector2i(1, -1),
		Vector2i(floor_size.x - 2, -1),
	]
	for i in range(DECORATIVE_PROP_PATHS.size()):
		var texture: Texture2D = load(DECORATIVE_PROP_PATHS[i])
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
		sprite.position = _tilemap.map_to_local(positions[i])
		add_child(sprite)
	# Pixelart mine props at additional border positions
	var pixel_positions: Array[Vector2i] = [
		Vector2i(-1, floor_size.y / 2),
		Vector2i(floor_size.x, 1),
		Vector2i(floor_size.x / 2, -1),
		Vector2i(floor_size.x - 1, floor_size.y),
	]
	for i in range(PIXELART_MINE_PROPS.size()):
		if i >= pixel_positions.size():
			break
		var texture: Texture2D = load(PIXELART_MINE_PROPS[i])
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
		sprite.position = _tilemap.map_to_local(pixel_positions[i])
		add_child(sprite)

## Player avatar (#100): mirrors farm_scene.gd's _add_player_avatar.
## Anchored at the floor's center (from get_floor_size(), same "don't
## hardcode a size this scene doesn't own" discipline _add_decorative_props
## already follows), moved toward each clicked tile thereafter.
func _add_player_avatar() -> void:
	var floor_size := MiningManager.get_floor_size()
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(floor_size.x / 2, floor_size.y / 2))
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

## #101: direct keyboard movement -- mirrors farm_scene.gd's _process
## exactly, see that file for the precedence-rule docstring.
func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player_avatar.move_by_input(direction, delta)

## Resolves the interact-action target tile -- mirrors farm_scene.gd's
## _facing_tile() exactly.
func _facing_tile() -> Vector2i:
	return _tilemap.local_to_map(_player_avatar.position + _player_avatar.facing * TILE_HEIGHT)

## Click-to-interact (see class docstring): mirrors every prior world
## scene's _unhandled_input pattern exactly, plus the `interact` action
## (#101) driving _handle_tile_click against _facing_tile().
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

func _handle_tile_click(tile: Vector2i) -> void:
	if not _in_grid(tile):
		return
	_player_avatar.move_to(_tilemap.map_to_local(tile))
	var acted := false
	if tile == MiningManager.get_ladder_position():
		acted = MiningManager.descend_ladder()
	elif MiningManager.has_rock(tile):
		acted = not MiningManager.break_rock(tile).is_empty()
	if acted:
		_player_avatar.pulse_tool_use()
