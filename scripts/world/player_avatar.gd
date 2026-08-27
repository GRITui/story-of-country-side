extends CharacterBody2D
class_name PlayerAvatar
## Visible main character for Squad Alpha P0 (#100).
##
## Sprite + 4-dir walk + tool-hold + shadow, grid-aligned to
## design/art/isometric-grid-spec.md (64x32 tile, 2:1 diamond, same
## screen_x/y formulas the spec defines). Reads no autoload private fields;
## movement respects TimeManager.is_frozen() and world scenes wire via
## public methods/signals only (SQUAD-SPLIT contract).
##
## Deterministic tint per save: hue derived from hash("player_avatar") so
## the same build always renders the same tint, and re-instantiation after
## save/load or travel_to() is stable without stored state. A future
## cosmetics system can replace _avatar_tint() with a persisted choice.
##
## Shadow: small dark ellipse at feet (same ground-contact idea as
## ProceduralCharacterArt's NPC shadow) so the figure reads as standing on
## the tile rather than floating. Tool swing: brief scale + modulate pulse
## on the tool child, non-blocking.

signal moved(grid_pos: Vector2i)

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MOVE_SPEED := 110.0
const SPRITE_HEIGHT := 48

var grid_bounds: Rect2i = Rect2i(0, 0, 8, 8) ## caller (FarmScene/RanchScene) sets to its own GRID_WIDTH/HEIGHT
var spawn_grid: Vector2i = Vector2i(1, 1)

var _facing: String = "down" ## down/up/left/right
var _last_grid: Vector2i = Vector2i.MIN
var _is_swinging: bool = false
var _sprite: Sprite2D
var _shadow: Sprite2D
var _tool: Sprite2D

func _ready() -> void:
	_create_shadow()
	_create_sprite()
	_create_tool()
	# Place at spawn_grid -> world anchor (bottom-center of that tile's diamond).
	position = grid_to_world(spawn_grid)
	_last_grid = world_to_grid(position)
	_update_facing_visual()

func _physics_process(delta: float) -> void:
	if TimeManager and TimeManager.is_frozen():
		return
	var dir := _get_input_dir()
	if dir != Vector2.ZERO:
		_update_facing(dir)
		var next_pos := position + dir * MOVE_SPEED * delta
		var next_grid := world_to_grid(next_pos)
		if is_inside_grid(next_grid):
			velocity = dir * MOVE_SPEED
			move_and_slide()
			# clamp after slide in case physics pushed outside
			var clamped_grid := world_to_grid(position)
			if not is_inside_grid(clamped_grid):
				var cgx := clampi(clamped_grid.x, grid_bounds.position.x, grid_bounds.position.x + grid_bounds.size.x - 1)
				var cgy := clampi(clamped_grid.y, grid_bounds.position.y, grid_bounds.position.y + grid_bounds.size.y - 1)
				position = grid_to_world(Vector2i(cgx, cgy))
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	var cur_grid := world_to_grid(position)
	if cur_grid != _last_grid:
		_last_grid = cur_grid
		moved.emit(cur_grid)

func _get_input_dir() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		y += 1.0
	var d := Vector2(x, y)
	if d.length() > 1.0:
		d = d.normalized()
	return d

func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_facing = "right" if dir.x > 0 else "left"
	elif dir != Vector2.ZERO:
		_facing = "down" if dir.y > 0 else "up"
	_update_facing_visual()

func _update_facing_visual() -> void:
	if _sprite == null:
		return
	match _facing:
		"left":
			_sprite.flip_h = true
			_sprite.scale = Vector2(1, 1)
		"right":
			_sprite.flip_h = false
			_sprite.scale = Vector2(1, 1)
		"up":
			_sprite.flip_h = false
			_sprite.scale = Vector2(0.95, 1.02)
		"down":
			_sprite.flip_h = false
			_sprite.scale = Vector2(1, 1)
	# offset tool to match facing
	if _tool != null:
		match _facing:
			"left":
				_tool.position = Vector2(-8, -18)
				_tool.flip_h = true
			"right":
				_tool.position = Vector2(8, -18)
				_tool.flip_h = false
			"up":
				_tool.position = Vector2(0, -20)
				_tool.flip_h = false
			_:
				_tool.position = Vector2(6, -14)
				_tool.flip_h = false

## Public: face a target grid cell (called by world scene on tile click so
## the avatar visually orients toward the interaction).
func face_grid(target: Vector2i) -> void:
	var cur := world_to_grid(position)
	var delta := target - cur
	if delta == Vector2i.ZERO:
		return
	var dir := Vector2(delta.x, delta.y)
	_update_facing(dir)

## Public: brief tool-swing pulse (called by FarmScene/RanchScene after a
## successful plant/water/harvest/feed/etc.). Non-blocking, re-entrant.
func swing_tool() -> void:
	if _is_swinging or _tool == null:
		return
	_is_swinging = true
	var orig_scale := _tool.scale
	var orig_mod := _tool.modulate
	var tween := create_tween()
	tween.tween_property(_tool, "scale", orig_scale * 1.35, 0.07)
	tween.parallel().tween_property(_tool, "rotation_degrees", 28.0, 0.07)
	tween.tween_property(_tool, "scale", orig_scale, 0.10)
	tween.parallel().tween_property(_tool, "rotation_degrees", 0.0, 0.10)
	tween.tween_callback(func() -> void:
		_tool.modulate = orig_mod
		_is_swinging = false
	)
	# bright pulse
	_tool.modulate = Color(1.3, 1.3, 1.05)

func get_grid_position() -> Vector2i:
	return world_to_grid(position)

func set_grid_position(grid: Vector2i) -> void:
	if is_inside_grid(grid):
		position = grid_to_world(grid)
		var cur := world_to_grid(position)
		if cur != _last_grid:
			_last_grid = cur
			moved.emit(cur)

func is_inside_grid(grid: Vector2i) -> bool:
	return grid_bounds.has_point(grid)

## Isometric spec helpers — must match design/art/isometric-grid-spec.md
## section 3 exactly so avatar feet align with TileMap diamonds.

func grid_to_world(grid: Vector2i) -> Vector2:
	# Same formulas as spec: screen_x = (gx - gy) * (W/2), screen_y = (gx + gy)*(H/2)
	# Position is the bottom-center of the diamond (YSort anchor convention, spec §4).
	var wx := (grid.x - grid.y) * (TILE_WIDTH * 0.5)
	var wy := (grid.x + grid.y) * (TILE_HEIGHT * 0.5)
	return Vector2(wx, wy)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Inverse of above, rounded to nearest tile.
	var nx := world_pos.x / (TILE_WIDTH * 0.5)
	var ny := world_pos.y / (TILE_HEIGHT * 0.5)
	var gx := int(round((nx + ny) * 0.5))
	var gy := int(round((ny - nx) * 0.5))
	return Vector2i(gx, gy)

func _avatar_tint() -> Color:
	var h: int = absi(hash("player_avatar"))
	return Color.from_hsv(float(h % 360) / 360.0, 0.52, 0.88)

func _create_sprite() -> void:
	var tint := _avatar_tint()
	var tex: ImageTexture = ProceduralCharacterArt.build_silhouette_texture(tint, SPRITE_HEIGHT)
	_sprite = Sprite2D.new()
	_sprite.name = "AvatarSprite"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	add_child(_sprite)

func _create_shadow() -> void:
	# Small dark ellipse at feet — matches the ground-contact shadow
	# ProceduralCharacterArt draws under NPCs.
	var w := 18
	var h := 6
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w * 0.5
	var cy := h * 0.5
	var rx := w * 0.45
	var ry := h * 0.45
	for py in range(h):
		for px in range(w):
			var nx := (px + 0.5 - cx) / rx
			var ny := (py + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(px, py, Color(0, 0, 0, 0.33))
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	_shadow.texture = ImageTexture.create_from_image(img)
	_shadow.centered = false
	_shadow.offset = Vector2(-w * 0.5, -2)
	_shadow.z_index = -1
	add_child(_shadow)

func _create_tool() -> void:
	# Tiny placeholder tool sprite (brown rectangle) held at hand height.
	# Real art can replace texture without touching swing logic.
	var tw := 6
	var th := 14
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.38, 0.18, 1.0))
	_tool = Sprite2D.new()
	_tool.name = "ToolSprite"
	_tool.texture = ImageTexture.create_from_image(img)
	_tool.centered = true
	_tool.position = Vector2(6, -14)
	add_child(_tool)

## Helper for clamp_grid (Rect2i has no clamp method in GDScript, so inline).
