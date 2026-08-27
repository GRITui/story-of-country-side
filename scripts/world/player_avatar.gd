extends CharacterBody2D
class_name PlayerAvatar
## Visible player character in world scenes.
##
## Spawns a procedural humanoid silhouette (ProceduralCharacterArt) tinted
## blue to distinguish from NPCController's per-name hue. Reads
## MainController.get_movement_vector() for WASD/arrow input and drives
## CharacterBody2D movement at ~100 px/sec. Anchor is bottom-center per
## isometric-grid-spec.md section 4, same convention NPCController uses.
##
## Each world scene is responsible for instantiating PlayerAvatar and
## reparenting its own Camera2D to follow (see farm_scene.gd etc.).

const MOVE_SPEED := 100.0
const SPRITE_HEIGHT_PX := 48

const PLAYER_TINT := Color(0.30, 0.45, 0.85)

func _ready() -> void:
	_add_placeholder_sprite()

## ProceduralCharacterArt silhouette tinted blue -- same pattern as
## NPCController._add_placeholder_sprite() but with a fixed player color
## so the player always reads as visually distinct from any NPC.
func _add_placeholder_sprite() -> void:
	var texture := ProceduralCharacterArt.build_silhouette_texture(PLAYER_TINT, SPRITE_HEIGHT_PX)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	add_child(sprite)

func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	var controller := _find_main_controller()
	if controller:
		dir = controller.get_movement_vector()
	else:
		dir = _fallback_movement_input()
	velocity = dir * MOVE_SPEED
	move_and_slide()

## Walks up the scene tree to find the MainController instance that
## contains this world scene. Returns null when running outside the
## normal game tree (e.g. headless tests that instantiate scenes
## directly under a test runner node).
func _find_main_controller() -> Node:
	var node := get_parent()
	while node != null:
		if node is MainController:
			return node
		node = node.get_parent()
	return null

## Headless/test fallback when MainController autoload is unavailable --
## reads raw Input directly so the avatar still moves in test harnesses
## that don't bootstrap MainController.
func _fallback_movement_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	return dir
