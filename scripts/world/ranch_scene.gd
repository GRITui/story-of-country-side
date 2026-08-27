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
const BED_POSITION := Vector2i(GRID_WIDTH - 1, GRID_HEIGHT - 1) ## far corner, avoids (0,0) used by tests

@onready var _tilemap: TileMap = $TileMap
var _avatar: PlayerAvatar

func _ready() -> void:
	_build_tileset()
	_render_all_pens()
	_spawn_avatar()

	AnimalManager.animal_added.connect(_on_animal_added)
	AnimalManager.animal_fed.connect(_on_animal_changed)
	AnimalManager.animal_brushed.connect(_on_animal_changed)
	AnimalManager.product_collected.connect(_on_product_collected)

## Same shared ProceduralTileArt approach as FarmScene._build_tileset —
## see class docstring for why there's no art asset to load instead.
func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, TILE_WIDTH, TILE_HEIGHT, ATLAS_SOURCE_ID, [STATE_READY])

func _spawn_avatar() -> void:
	var existing := get_node_or_null("PlayerAvatar")
	if existing is PlayerAvatar:
		_avatar = existing
	else:
		var scene := load("res://scenes/world/PlayerAvatar.tscn")
		if scene != null:
			_avatar = scene.instantiate()
			add_child(_avatar)
		else:
			_avatar = PlayerAvatar.new()
			_avatar.name = "PlayerAvatar"
			add_child(_avatar)
	_avatar.grid_bounds = Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT)
	_avatar.spawn_grid = Vector2i(1, 1)
	_avatar.set_grid_position(Vector2i(1, 1))
	_avatar.moved.connect(_on_avatar_moved)

func _render_all_pens() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_refresh_tile(Vector2i(x, y))

## Deterministic position <-> animal_id mapping — see class docstring for
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

func _is_bed_tile(position: Vector2i) -> bool:
	return position == BED_POSITION

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

func _on_avatar_moved(_grid_pos: Vector2i) -> void:
	pass

## Click-to-interact stretch goal (see class docstring): mirrors FarmScene's
## _unhandled_input/_handle_tile_click pattern exactly, plus bed tile
## sleep at BED_POSITION.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = _tilemap.to_local(get_global_mouse_position())
		var cell: Vector2i = _tilemap.local_to_map(local_pos)
		_handle_tile_click(cell)

func _handle_tile_click(position: Vector2i) -> void:
	if not _in_grid(position):
		return
	if _avatar != null:
		_avatar.face_grid(position)
	if _is_bed_tile(position):
		if TimeManager.can_sleep():
			if TimeManager.sleep():
				if _avatar != null:
					_avatar.swing_tool()
		return
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
		var result := AnimalManager.collect_product(animal_id)
		acted = not result.is_empty()
	if acted and _avatar != null:
		_avatar.swing_tool()
