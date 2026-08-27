extends CharacterBody2D
class_name PlayerAvatar
## Frontend (#100): the player's own embodied character representation in every
## world scene. Replaces the disembodied cursor with a visible animated body
## that can move, interact, and provide tool-use feedback.
##
## Upgrades v1 over the previous #100 cursor:
## 1. True embodiment: visible Sprite2D with directional facing (WASD/up/down/left/right)
## 2. Animation states: IDLE, WALKING (per-dir frames), SWING_TOOL (brief pulse)
## 3. Tool-use feedback: pulse_tool_use() matches action success in each world scene
## 4. Position persists across actions within the same scene visit simply
##    by being an ordinary child node that isn't recreated on every click.
##    A scene swap (main_controller.travel_to()) frees the whole world
##    scene -- this node included -- and the next scene's _ready() places
##    a fresh one at its own anchor. That's "reset per scene swap\", which
##    #100 explicitly accepts as fine for v1.
##
## Explicitly NOT built here (per #100 out of scope): collision physics, free camera,
## clothing system, or full walk-cycle animation sets beyond 4-dir facing.
##
## Core API (B-S9-02): get_facing() -> Vector2i, get_current_tool() -> StringName, tool_changed signal
## Headless-testable via mocks for each public method.

## Movement & Animation States
signal arrived() # emitted when player reaches a movement target
signal tool_changed(tool_id: String) # when player starts using a new tool

const SPRITE_HEIGHT_PX := 48
const PLAYER_COLOR := Color(0.82, 0.28, 0.24) # Distinct from NPC name-hashed colors
const SWING_PULSE_COLOR := Color(1.5, 1.5, 1.15)

## Direction enum for animation states
enum Direction {
    DOWN,
    UP,
    LEFT,
    RIGHT
}

## Animation state enum
enum AnimationState {
    IDLE,
    WALKING,
    SWING_TOOL
}

@onready var _sprite: Sprite2D = $Sprite
@onready var _animated_sprite: AnimatedSprite2D = $Sprite/AnimatedSprite

## Public API for other systems
var current_tool: StringName = "" setget set_current_tool
var current_direction: Direction = Direction.DOWN setget set_direction
var is_moving: bool = false

## Internal state
var _last_movement_dir: Vector2 = Vector2.DOWN
var _current_animation_state: AnimationState = AnimationState.IDLE
var _has_pending_input: bool = false

func _ready() -> void:
    _initialize_avatar()
    _setup_animations()

func _initialize_avatar() -> void:
    """Build the visual representation"""
    _sprite = Sprite2D.new()
    _sprite.texture = ProceduralCharacterArt.build_silhouette_texture(PLAYER_COLOR, SPRITE_HEIGHT_PX)
    _sprite.centered = false
    _sprite.offset = Vector2(-_sprite.texture.get_width() / 2.0, -_sprite.texture.get_height())
    add_child(_sprite)

func _setup_animations() -> void:
    """Setup animated sprite for directional animation"""
    _animated_sprite = AnimatedSprite2D.new()
    _animated_sprite.sprite_frames = _create_animation_frames()
    _animated_sprite.animation = "idle_down"
    _animated_sprite.play()
    _sprite.add_child(_animated_sprite)

func _create_animation_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    
    # Create simple placeholder frames for each direction
    for direction in [Direction.DOWN, Direction.UP, Direction.LEFT, Direction.RIGHT]:
        # Idle frames (1 per direction)
        var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
        var color := PLAYER_COLOR
        if direction == Direction.UP:
            color = Color(0.2, 0.8, 0.2)
        elif direction == Direction.LEFT:
            color = Color(0.2, 0.2, 0.8)
        elif direction == Direction.RIGHT:
            color = Color(0.8, 0.2, 0.2)
        for y in range(16):
            for x in range(16):
                img.set_pixel(x, y, color)
        var tex := ImageTexture.new()
        tex.create_from_image(img)
        frames.add_frame("idle_" + str(direction), tex)
        
        # Walk frames (1 per direction)
        img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
        color = PLAYER_COLOR
        color.a = 0.7
        for y in range(16):
            for x in range(16):
                img.set_pixel(x, y, color)
        tex = ImageTexture.new()
        tex.create_from_image(img)
        frames.add_frame("walk_" + str(direction), tex)
    
    # Tool swing frame
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    var color := SWING_PULSE_COLOR
    for y in range(16):
        for x in range(16):
            img.set_pixel(x, y, color)
    var tex := ImageTexture.new()
    tex.create_from_image(img)
    frames.add_frame("swing_tool", tex)
    
    return frames

## Public API for backend interaction (B-S9-02)

func get_facing() -> Vector2i:
    """Returns the grid cell the player is facing, for backend queries"""
    # Convert screen direction to grid direction
    var grid_facing: Vector2i = Vector2i.ZERO
    if absf(_last_movement_dir.x) > absf(_last_movement_dir.y):
        grid_facing.x = sign(_last_movement_dir.x)
    else:
        grid_facing.y = sign(_last_movement_dir.y)
    return grid_facing

func get_current_tool() -> StringName:
    """Returns the current tool ID the player has selected"""
    return current_tool

func pulse_tool_use() -> void:
    """Visual feedback when player successfully uses a tool"""
    _current_animation_state = AnimationState.SWING_TOOL
    _animated_sprite.play("swing_tool")

func set_current_tool(new_tool: StringName) -> void:
    if new_tool != current_tool:
        current_tool = new_tool
        tool_changed.emit(new_tool)

func set_direction(new_dir: Direction) -> void:
    current_direction = new_dir
    _update_animation_direction()

func _update_animation_direction() -> void:
    """Update animated sprite based on current direction and animation state"""
    if not _animated_sprite:
        return
    
    var anim_name: String
    if _current_animation_state == AnimationState.SWING_TOOL:
        anim_name = "swing_tool"
    elif _current_animation_state == AnimationState.WALKING:
        anim_name = "walk_" + str(current_direction)
    else:
        anim_name = "idle_" + str(current_direction)
    
    _animated_sprite.play(anim_name)

func _process(delta: float) -> void:
    """Handle continuous input and movement"""
    var direction := Vector2.ZERO
    
    # Check for keyboard input using InputMapManager actions
    if Input.is_action_pressed("move_up"):
        direction.y -= 1
    if Input.is_action_pressed("move_down"):
        direction.y += 1
    if Input.is_action_pressed("move_left"):
        direction.x -= 1
    if Input.is_action_pressed("move_right"):
        direction.x += 1
    
    if direction != Vector2.ZERO:
        direction = direction.normalized()
        _last_movement_dir = direction
        _has_pending_input = true
        _current_animation_state = AnimationState.WALKING
        
        position += direction * 120.0 * delta  # Move at 120 pixels per second
        
        is_moving = true
        _update_animation_direction()
    else:
        _has_pending_input = false
        if _current_animation_state != AnimationState.SWING_TOOL:
            _current_animation_state = AnimationState.IDLE
            _update_animation_direction()
        
        is_moving = false
