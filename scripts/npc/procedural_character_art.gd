class_name ProceduralCharacterArt
## Shared procedural sprite generator for character placeholders.
##
## Art Squad (#52 adjacent sub-scope): NPCController (#18, already merged)
## has driven schedule-based movement since it landed, but has never had
## any visual representation at all -- it's a bare Node2D with no Sprite2D
## or any other visual child anywhere in the tree, in this repo's history.
## No world scene currently instantiates an NPC either (grep confirms
## NPCController has no .tscn usage yet), so this doesn't fix a visible bug
## today -- it closes the gap for whenever a future scene does place NPCs,
## so they don't silently render as nothing.
##
## Same honesty as procedural_tile_art.gd: no image-generation tool exists
## in this environment, so this is a simple procedurally-drawn humanoid
## silhouette (circular head + rounded body, soft directional shading, a
## ground-contact shadow) -- not illustrated character art. A human artist
## or an image-gen pipeline is still the real answer for actual character
## design (distinct NPC likenesses, clothing, animation frames).
##
## Anchor: bottom-center, matching design/art/isometric-grid-spec.md
## section 4's object-anchor convention (entities anchor at the tile
## diamond's bottom-center so YSort draw order falls out of screen-Y
## automatically). Callers should set Sprite2D.centered = false and offset
## by (-width / 2, -height) so the sprite's Node2D origin sits at its feet.

const LIGHT_STRENGTH := 0.25

## Builds a small humanoid silhouette texture tinted `tint`, `height` px
## tall (width is derived proportionally). Deterministic for a given tint
## (no per-run randomness) so repeated calls with the same NPC color
## produce pixel-identical output.
static func build_silhouette_texture(tint: Color, height: int = 48) -> ImageTexture:
	var width := int(height * 0.6)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	# Ground-contact shadow: a flattened dark ellipse at the feet, so the
	# figure reads as standing on the tile rather than floating.
	var shadow_color := Color(0.0, 0.0, 0.0, 0.35)
	_fill_ellipse(image, Vector2(width / 2.0, height - 2.0), width * 0.32, height * 0.06, shadow_color)

	# Body: a rounded capsule occupying the lower ~62% of the sprite.
	var body_top := height * 0.36
	var body_bottom := height * 0.92
	var body_half_width := width * 0.28
	_fill_capsule(image, width / 2.0, body_top, body_bottom, body_half_width, tint)

	# Head: a circle centered in the upper portion, slightly overlapping
	# the body so there's no visible seam.
	var head_radius := width * 0.26
	var head_center := Vector2(width / 2.0, height * 0.22)
	_fill_ellipse(image, head_center, head_radius, head_radius, tint)

	return ImageTexture.create_from_image(image)

static func _fill_ellipse(image: Image, center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var min_x := maxi(0, int(center.x - radius_x) - 1)
	var max_x := mini(image.get_width() - 1, int(center.x + radius_x) + 1)
	var min_y := maxi(0, int(center.y - radius_y) - 1)
	var max_y := mini(image.get_height() - 1, int(center.y + radius_y) + 1)
	for py in range(min_y, max_y + 1):
		for px in range(min_x, max_x + 1):
			var nx := (px + 0.5 - center.x) / radius_x
			var ny := (py + 0.5 - center.y) / radius_y
			if nx * nx + ny * ny <= 1.0:
				_blend_shaded_pixel(image, px, py, nx, ny, color)

## A vertically-stretched "capsule" (rounded rectangle): a rect body with a
## half-ellipse cap at the top edge only (bottom stays flat -- feet planted
## on the ground plane).
static func _fill_capsule(image: Image, center_x: float, top: float, bottom: float, half_width: float, color: Color) -> void:
	var cap_height := half_width
	var min_x := maxi(0, int(center_x - half_width) - 1)
	var max_x := mini(image.get_width() - 1, int(center_x + half_width) + 1)
	var min_y := maxi(0, int(top) - 1)
	var max_y := mini(image.get_height() - 1, int(bottom) + 1)
	for py in range(min_y, max_y + 1):
		for px in range(min_x, max_x + 1):
			var nx := (px + 0.5 - center_x) / half_width
			if absf(nx) > 1.0:
				continue
			var inside := false
			var ny := 0.0
			if py < top + cap_height:
				ny = (py + 0.5 - (top + cap_height)) / cap_height
				inside = nx * nx + ny * ny <= 1.0
			else:
				inside = py <= bottom
			if inside:
				_blend_shaded_pixel(image, px, py, nx, ny, color)

## Directional shading (same fixed upper-left light convention as
## procedural_tile_art.gd) blended onto color, then written to the pixel.
static func _blend_shaded_pixel(image: Image, px: int, py: int, nx: float, ny: float, color: Color) -> void:
	var light := 1.0 + LIGHT_STRENGTH * (-nx - ny) * 0.5
	image.set_pixel(px, py, Color(
		clampf(color.r * light, 0.0, 1.0),
		clampf(color.g * light, 0.0, 1.0),
		clampf(color.b * light, 0.0, 1.0),
		1.0
	))
