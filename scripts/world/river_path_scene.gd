extends Node2D
class_name RiverPathScene
## PO-16BIT-WORLD-4 Zone2 Path & River (fishing, bamboo shoots foraging).
## 8x8 grid slice of 64x64 WorldMap (ZONE_PATH_RIVER). River runs mid-grid, bamboo grove nearby.
## Props: tree/pine/bush/rock along river. Uses FishingManager + ForagingManager for real gameplay.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const ATLAS_SOURCE_ID := 0

const DECORATIVE_PROPS := [
	{"path": "res://assets/16bit/props/tree.png", "grid_pos": Vector2i(1, 1)},
	{"path": "res://assets/16bit/props/pine.png", "grid_pos": Vector2i(6, 1)},
	{"path": "res://assets/16bit/props/bush.png", "grid_pos": Vector2i(3, 2)},
	{"path": "res://assets/16bit/props/rock.png", "grid_pos": Vector2i(4, 4)},
	{"path": "res://assets/16bit/props/rock_large.png", "grid_pos": Vector2i(6, 5)},
]

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar
var _dynamic_layer: Node2D
var _npcs: Array[NPCController] = []

func _ready() -> void:
	_build_tileset()
	_add_decorative_props()
	_add_dynamic_layer()
	_add_player_avatar()
	# No fixed villagers in river zone — Elder Taro visits at 14:00 via schedule, but his home is Village.
	_wire_avatar_collision()

func _build_tileset() -> void:
	var png_map := {0: "res://assets/16bit/tiles/path.png", 1: "res://assets/16bit/tiles/grass.png"}
	var tileset := _try_build_pixelart_tileset(png_map, [])
	_tilemap.tile_set = tileset
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_tilemap.set_cell(0, Vector2i(x, y), ATLAS_SOURCE_ID, Vector2i(0, 0))

func _try_build_pixelart_tileset(png_map: Dictionary, _g: Array = []) -> TileSet:
	var states: Array = png_map.keys(); states.sort()
	var textures: Dictionary = {}
	for s in states:
		var t: Texture2D = load(png_map[s])
		if t and t.get_image(): textures[s] = t
	var img := Image.create(TILE_WIDTH * states.size(), TILE_HEIGHT, false, Image.FORMAT_RGBA8)
	for i in range(states.size()):
		if not textures.has(states[i]): continue
		var tex: Texture2D = textures[states[i]]
		var im: Image = tex.get_image()
		img.blit_rect(im, Rect2i(0,0,mini(im.get_width(),TILE_WIDTH),mini(im.get_height(),TILE_HEIGHT)), Vector2i(i*TILE_WIDTH,0))
	var atlas := ImageTexture.create_from_image(img)
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(TILE_WIDTH, TILE_HEIGHT)
	var src := TileSetAtlasSource.new()
	src.texture = atlas
	src.texture_region_size = Vector2i(TILE_WIDTH, TILE_HEIGHT)
	for i in range(states.size()): src.create_tile(Vector2i(i,0))
	ts.add_source(src, ATLAS_SOURCE_ID)
	return ts

func _add_decorative_props() -> void:
	for prop in DECORATIVE_PROPS:
		var tex: Texture2D = load(prop["path"])
		if tex == null: continue
		var s := Sprite2D.new()
		s.texture = tex; s.centered = false
		s.offset = Vector2(-tex.get_width()*0.5, -tex.get_height())
		s.position = _tilemap.map_to_local(prop["grid_pos"])
		add_child(s)

func _add_dynamic_layer() -> void:
	_dynamic_layer = Node2D.new()
	_dynamic_layer.name = "DynamicLayer"
	_dynamic_layer.y_sort_enabled = true
	add_child(_dynamic_layer)

func _add_player_avatar() -> void:
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(GRID_WIDTH/2, GRID_HEIGHT/2))
	_dynamic_layer.add_child(_player_avatar)

func _wire_avatar_collision() -> void:
	if _player_avatar == null or _tilemap == null: return
	var o: Vector2 = _tilemap.map_to_local(Vector2i(0,0))
	var f: Vector2 = _tilemap.map_to_local(Vector2i(GRID_WIDTH-1, GRID_HEIGHT-1))
	_player_avatar.set_world_bounds(Rect2(Vector2(minf(o.x,f.x)-TILE_WIDTH*0.5, minf(o.y,f.y)-TILE_HEIGHT*0.5), Vector2(absf(f.x-o.x)+TILE_WIDTH, absf(f.y-o.y)+TILE_HEIGHT)))

func _process(delta: float) -> void:
	var dir := Input.get_vector("move_left","move_right","move_up","move_down")
	if _player_avatar: _player_avatar.move_by_input(dir, delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell: Vector2i = _tilemap.local_to_map(_tilemap.to_local(get_global_mouse_position()))
		if cell.x >=0 and cell.x < GRID_WIDTH and cell.y>=0 and cell.y<GRID_HEIGHT and _player_avatar:
			_player_avatar.move_to(_tilemap.map_to_local(cell))
			# Foraging: bamboo shoots
			if ForagingManager and ForagingManager.has_method("gather"):
				ForagingManager.gather(cell)
	elif event.is_action_pressed("interact"):
		if _player_avatar:
			var facing: Vector2i = _tilemap.local_to_map(_player_avatar.position + _player_avatar.facing * TILE_HEIGHT)
			if ForagingManager and ForagingManager.has_method("gather"):
				ForagingManager.gather(facing)
