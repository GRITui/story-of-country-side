extends Node2D
class_name VillageSquareScene
## PO-16BIT-WORLD-4 Zone3 Village Square (Store, Blacksmith, Shrine, Townhall).
## 8x8 grid logical zone within 64x64 WorldMap (ZONE_VILLAGE 40x24 tile slice).
## Props: kawara_roof + jizo_statue (Shrine), farmhouse as Store, barn as Blacksmith.
## NPCs: Elder Taro, Hanako, Takeshi via NPCRoster. Waypoint pathfinding via WorldMap blocked rects.
## Interaction: Talk -> RelationshipManager.talk_to + emote, Gift -> give_gift + DialogueBox + emote.
## Reuses FarmScene patterns (YSort DynamicLayer, TileMap, PlayerAvatar, DialogueBox) without duplication.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const ATLAS_SOURCE_ID := 0
const HOME_SCENE_NAME := "Village"

const DECORATIVE_PROPS := [
	{"path": "res://assets/16bit/props/kawara_roof.png", "grid_pos": Vector2i(4, 0)},
	{"path": "res://assets/16bit/props/jizo_statue.png", "grid_pos": Vector2i(5, 1)},
	{"path": "res://assets/16bit/props/farmhouse.png", "grid_pos": Vector2i(2, 2)}, # Store
	{"path": "res://assets/16bit/props/barn.png", "grid_pos": Vector2i(6, 2)}, # Blacksmith
	{"path": "res://assets/16bit/props/tree_2.png", "grid_pos": Vector2i(2, 6)},
	{"path": "res://assets/16bit/props/fruit_tree.png", "grid_pos": Vector2i(6, 6)},
	{"path": "res://assets/16bit/props/fence_h.png", "grid_pos": Vector2i(3, -1)},
	{"path": "res://assets/16bit/props/fence_v.png", "grid_pos": Vector2i(-1, 3)},
]

@onready var _tilemap: TileMap = $TileMap
var _player_avatar: PlayerAvatar
var _dynamic_layer: Node2D
var _npcs: Array[NPCController] = []
var _dialogue_box: DialogueBox
var _relationships_overlay: RelationshipsOverlay

func _ready() -> void:
	_build_tileset()
	_render_all()
	_add_decorative_props()
	_add_dynamic_layer()
	_add_player_avatar()
	_add_villagers()
	_wire_npc_waypoints()
	_wire_avatar_collision()

func _build_tileset() -> void:
	var png_map := {
		0: "res://assets/16bit/tiles/path.png",
		1: "res://assets/16bit/tiles/grass.png",
		2: "res://assets/16bit/tiles/dirt.png",
		3: "res://assets/16bit/tiles/grass_clover.png",
	}
	var tileset := _try_build_pixelart_tileset(png_map, [])
	_tilemap.tile_set = tileset
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_tilemap.set_cell(0, Vector2i(x, y), ATLAS_SOURCE_ID, Vector2i(0, 0))

func _try_build_pixelart_tileset(png_map: Dictionary, _glow: Array = []) -> TileSet:
	var states: Array = png_map.keys()
	states.sort()
	var textures: Dictionary = {}
	for state in states:
		var tex: Texture2D = load(png_map[state])
		if tex == null or tex.get_image() == null:
			continue
		textures[state] = tex
	var atlas_img := Image.create(TILE_WIDTH * states.size(), TILE_HEIGHT, false, Image.FORMAT_RGBA8)
	for i in range(states.size()):
		if not textures.has(states[i]): continue
		var tex: Texture2D = textures[states[i]]
		var img: Image = tex.get_image()
		atlas_img.blit_rect(img, Rect2i(0, 0, mini(img.get_width(), TILE_WIDTH), mini(img.get_height(), TILE_HEIGHT)), Vector2i(i * TILE_WIDTH, 0))
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

func _render_all() -> void:
	pass

func _add_decorative_props() -> void:
	for prop in DECORATIVE_PROPS:
		var tex: Texture2D = load(prop["path"])
		if tex == null: continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		s.position = _tilemap.map_to_local(prop["grid_pos"])
		add_child(s)

func _add_dynamic_layer() -> void:
	_dynamic_layer = Node2D.new()
	_dynamic_layer.name = "DynamicLayer"
	_dynamic_layer.y_sort_enabled = true
	add_child(_dynamic_layer)

func _add_player_avatar() -> void:
	_player_avatar = PlayerAvatar.new()
	_player_avatar.position = _tilemap.map_to_local(Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2))
	_dynamic_layer.add_child(_player_avatar)

func _add_villagers() -> void:
	for npc_name in NPCRoster.npcs_for_scene(HOME_SCENE_NAME):
		var npc := NPCController.new()
		npc.npc_name = npc_name
		npc.schedule = NPCRoster.build_schedule(npc_name, _tilemap)
		_dynamic_layer.add_child(npc)
		_npcs.append(npc)

func _wire_npc_waypoints() -> void:
	var blocked: Array[Rect2] = []
	for prop in DECORATIVE_PROPS:
		var gp: Vector2 = _tilemap.map_to_local(prop["grid_pos"])
		blocked.append(Rect2(gp.x - 28, gp.y - 16, 56, 32))
	for npc in _npcs:
		npc.set_blocked_rects(blocked)

func _wire_avatar_collision() -> void:
	if _player_avatar == null or _tilemap == null: return
	var origin: Vector2 = _tilemap.map_to_local(Vector2i(0, 0))
	var far: Vector2 = _tilemap.map_to_local(Vector2i(GRID_WIDTH - 1, GRID_HEIGHT - 1))
	var min_x := minf(origin.x, far.x) - TILE_WIDTH * 0.5
	var max_x := maxf(origin.x, far.x) + TILE_WIDTH * 0.5
	var min_y := minf(origin.y, far.y) - TILE_HEIGHT * 0.5
	var max_y := maxf(origin.y, far.y) + TILE_HEIGHT * 0.5
	_player_avatar.set_world_bounds(Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y)))
	var blocks: Array[Rect2] = []
	for prop in DECORATIVE_PROPS:
		var gp: Vector2 = _tilemap.map_to_local(prop["grid_pos"])
		blocks.append(Rect2(gp.x - 28, gp.y - 16, 56, 32))
	_player_avatar.set_blocked_rects(blocks)

func _npc_at_local_point(local_pos: Vector2) -> NPCController:
	const HALF_WIDTH := 20.0
	const HEIGHT := 54.0
	for npc in _npcs:
		if local_pos.x >= npc.position.x - HALF_WIDTH and local_pos.x <= npc.position.x + HALF_WIDTH \
				and local_pos.y <= npc.position.y and local_pos.y >= npc.position.y - HEIGHT:
			return npc
	return null

func _open_dialogue_for(npc: NPCController) -> void:
	if _dialogue_box != null and is_instance_valid(_dialogue_box):
		return
	# Talk first: affinity + heart check, then dialogue line if any
	var talked := npc.talk()
	var hearts := RelationshipManager.get_hearts(npc.npc_name)
	var line: String = RelationshipManager.get_heart_event_dialogue(npc.npc_name, hearts)
	if line == "":
		line = "%s smiles at you. (%d hearts)" % [npc.npc_name, hearts] if talked else "%s nods. (Already talked today, %d hearts)" % [npc.npc_name, hearts]
	_dialogue_box = load("res://scenes/ui/DialogueBox.tscn").instantiate()
	add_child(_dialogue_box)
	var portrait := "res://assets/16bit/characters/%s.png" % npc.npc_name.to_lower().replace(" ", "_")
	_dialogue_box.show_dialogue(npc.npc_name, portrait, line, "heart" if talked else "")
	_dialogue_box.dialogue_finished.connect(_close_dialogue, CONNECT_ONE_SHOT)

func _close_dialogue() -> void:
	if _dialogue_box and is_instance_valid(_dialogue_box):
		_dialogue_box.queue_free()
	_dialogue_box = null

func _process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _player_avatar:
		_player_avatar.move_by_input(dir, delta)

func _facing_tile() -> Vector2i:
	if _player_avatar == null: return Vector2i.ZERO
	return _tilemap.local_to_map(_player_avatar.position + _player_avatar.facing * TILE_HEIGHT)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var npc := _npc_at_local_point(local_pos)
		if npc != null:
			_open_dialogue_for(npc)
			return
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		if _in_grid(cell) and _player_avatar:
			_player_avatar.move_to(_tilemap.map_to_local(cell))
	elif event.is_action_pressed("interact") or event.is_action_pressed("primary_action") or event.is_action_pressed("secondary_action"):
		var npc2 := _npc_at_local_point(_player_avatar.position + _player_avatar.facing * TILE_HEIGHT * 0.5) if _player_avatar else null
		if npc2 != null:
			_open_dialogue_for(npc2)
		elif _in_grid(_facing_tile()) and _player_avatar:
			_player_avatar.move_to(_tilemap.map_to_local(_facing_tile()))

func _in_grid(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < GRID_WIDTH and p.y >= 0 and p.y < GRID_HEIGHT
