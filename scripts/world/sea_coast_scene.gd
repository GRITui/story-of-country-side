extends Node2D
class_name SeaCoastScene
## Frontend (#105): pier scene giving ocean fish pools a home.
##
## Same gap every prior world scene closed for its own manager: FishingManager
## (#15/#53) registers 11 fish across pond/river/lake/ocean but the player
## had no coastal place to stand -- FishingOverlay opened over whatever scene
## happened to be active, so ocean pools were reachable but had no thematic
## home. This scene is that home -- a shoreline + pier rendered via the same
## isometric TileMap contract every world scene already uses (64x32px,
##
## Grid: 8x8, same as FarmScene/ForageScene. No design-doc number dictates a
## different size, so this reuses the established footprint (SQUAD-SPLIT
## content-gap norm: document the placeholder sizing here, same as every
## prior scene's docstring).
##
## Tiles:
##   WATER (0)  -- deep ocean, non-interactive filler.
##   SAND  (1)  -- beach strip where shoreline forage spawns.
##   PIER  (2)  -- wooden pier; clicking fishes the "ocean" location via
##                FishingManager.get_available_fish("ocean", season, hour).
##                  Picking a random available fish and calling
##                  attempt_catch with a fixed placeholder performance keeps
##                  this scene's interaction model identical in shape to
##                  MineScene/ForageScene's direct-manager-call pattern.
##   FORAGE (3) -- sand tile currently holding an available
##                ForageNode; visual overlay on sand when ForagingManager
##                reports is_available at that Vector2i.
##
## Forage nodes: mirrors ForageScene -- every sand/forage tile is
## pre-registered via ForagingManager.register_node(), no-op on re-enter
## after a save load. Beach forage uses the same placeholder pool as the
## forest (wild_berries/sweet_pea/shell stand-ins) so no new backend
## content is required v1; Content lane can retune the pool later without
## touching this scene.
##
## Fishing: pier tiles call FishingManager.get_available_fish("ocean", ...)
## so the ocean pool (tuna/sardine/squid etc.) finally has a dedicated
## location. Uses a fixed Great-Effort performance (0.95) same as
## FishingOverlay's own placeholder -- no mini-game here, just the catch
## contract FishingManager already exposes. ForageNode is also handled here
## so beach shells can share the same grid (mirrors the spec's optional
## garnish #105.4).
##
## (water deep blue, sand warm beige, pier brown, forage lush) -- same
## alpha-masked diamond + shading pipeline every prior world scene uses.
## PIER and FORAGE get the center-weighted glow accent as the interactive
## tiles.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const TILE_WIDTH := 64
const TILE_HEIGHT := 32

const STATE_WATER := 0
const STATE_SAND := 1
const STATE_PIER := 2
const STATE_FORAGE := 3

const STATE_COLORS := {
	STATE_WATER: Color(0.15, 0.32, 0.55),
	STATE_SAND: Color(0.76, 0.68, 0.50),
	STATE_PIER: Color(0.55, 0.42, 0.28),
	STATE_FORAGE: Color(0.28, 0.50, 0.22),
}

const ATLAS_SOURCE_ID := 0

## Pier occupies a short jetty along the bottom edge, plus one column out
## into the water so it reads as a pier rather than a straight dock wall.
const PIER_TILES: Array[Vector2i] = [
	Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
	Vector2i(3, 5), Vector2i(3, 4), Vector2i(3, 3),
]
## Water is the top half of the grid (opposite the pier) so the pier
## visually reaches into it.
const WATER_ROWS := 4

const DECORATIVE_PROPS := [
	{"path": "res://assets/16bit/props/pine.png", "grid_pos": Vector2i(-1, 6)},
	{"path": "res://assets/16bit/props/bush.png", "grid_pos": Vector2i(-1, 2)},
	{"path": "res://assets/16bit/props/rock.png", "grid_pos": Vector2i(8, 2)},
	{"path": "res://assets/16bit/props/rock_large.png", "grid_pos": Vector2i(8, 6)},
	{"path": "res://assets/16bit/props/tree.png", "grid_pos": Vector2i(-1, 0)},
]

@onready var _tilemap: TileMap = $TileMap

func _ready() -> void:
	_build_tileset()
	_register_forage_nodes()
	_render_all_tiles()

	ForagingManager.forage_gathered.connect(_on_forage_gathered)
	ForagingManager.forage_node_rerolled.connect(_on_forage_node_rerolled)

func _build_tileset() -> void:
	var png_map := {
		STATE_WATER: "res://assets/16bit/tiles/water_0.png",
		STATE_SAND: "res://assets/16bit/tiles/sand.png",
		STATE_PIER: "res://assets/16bit/tiles/wood_floor.png",
		STATE_FORAGE: "res://assets/16bit/tiles/grass_clover.png"
	}
	var tileset := _try_build_pixelart_tileset(png_map, [STATE_PIER, STATE_FORAGE])
	_tilemap.tile_set = tileset

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

func _register_forage_nodes() -> void:
	for pos in _sand_positions():
		ForagingManager.register_node(pos)

func _render_all_tiles() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

func _sand_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var p := Vector2i(x, y)
			if _is_pier(p) or _is_water(p):
				continue
			result.append(p)
	return result

func _is_water(pos: Vector2i) -> bool:
	return pos.y < WATER_ROWS and not _is_pier(pos)

func _is_pier(pos: Vector2i) -> bool:
	return pos in PIER_TILES

func _tile_state(pos: Vector2i) -> int:
	if _is_pier(pos):
		return STATE_PIER
	if _is_water(pos):
		return STATE_WATER
	# Sand/forage: if ForagingManager reports an available node here, show forage variant
	var node: ForageNode = ForagingManager.get_forage_node(pos)
	if node != null and node.is_available():
		return STATE_FORAGE
	return STATE_SAND

func _refresh_tile(pos: Vector2i) -> void:
	_paint_tile(pos, _tile_state(pos))

func _paint_tile(pos: Vector2i, state: int) -> void:
	_tilemap.set_cell(0, pos, ATLAS_SOURCE_ID, Vector2i(state, 0))

func _in_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func _on_forage_gathered(position: Vector2i, _item_id: String, _quantity: int) -> void:
	if _in_grid(position):
		_refresh_tile(position)

func _on_forage_node_rerolled(position: Vector2i, _item_id: String) -> void:
	if _in_grid(position):
		_refresh_tile(position)

## Returns ocean fish available right now, per the spec's
## FishingManager.get_available_fish("ocean", ...) wiring.
func get_ocean_fish_preview() -> Array[String]:
	var season := ""
	var hour := 12
	if TimeManager:
		season = TimeManager.current_season()
		hour = TimeManager.hour
	return FishingManager.get_available_fish("ocean", season, hour)

## Click-to-interact: pier tiles fish ocean pools, forage tiles gather.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(pos: Vector2i) -> void:
	if not _in_grid(pos):
		return
	if _is_pier(pos):
		_try_ocean_fish()
	elif ForagingManager.is_available(pos):
		ForagingManager.gather(pos)

func _try_ocean_fish() -> void:
	var available := get_ocean_fish_preview()
	if available.is_empty():
		return
	# Placeholder catch: random ocean fish at Great Effort 0.95, mirrors
	# FishingOverlay's _on_cast_pressed pattern.
	var fish_id: String = available[randi() % available.size()]
	FishingManager.attempt_catch(fish_id, 0.95)
