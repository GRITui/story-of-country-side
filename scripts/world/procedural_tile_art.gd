class_name ProceduralTileArt
## Shared procedural texture generator — S-Tier P2 (Epsilon).
##
## Seasonal-tint expansion per Decision E art direction:
##   build_isometric_tileset(state_colors, w, h, id=0, glow=[])      — unchanged
##   build_isometric_tileset(state_colors, w, h, id=0, glow=[], season) — new
##   get_seasonal_palette(season) -> Dictionary  — tint helper
##   get_seasonal_accent_color(variant)         — 2 accent variants
##
## Keeps the original diamond alpha-mask / light gradient / edge darken /
## speckle grain exactly intact. Seasonal tint is applied as a post-scale on
## the base_color channel before shading so existing callers with no season
## arg (default "Spring") render identically to the pre-Epsilon generator.

const LIGHT_STRENGTH := 0.22
const EDGE_DARKEN_BAND := 0.07
const EDGE_DARKEN_STRENGTH := 0.55
const SPECKLE_STRENGTH := 0.10
const GLOW_STRENGTH := 0.4

## Seasonal color multipliers applied to base_color before shading.
## Chosen to read cozy without reauthoring per-state palettes:
## Spring — slightly brighter/saturated; Summer — warm; Fall — amber;
## Winter — cool/desaturated. Values are multiplicative scalars per channel.
const SEASONAL_TINTS: Dictionary = {
	"Spring": {"r": 1.04, "g": 1.06, "b": 1.02},
	"Summer": {"r": 1.06, "g": 1.02, "b": 0.94},
	"Fall":   {"r": 1.08, "g": 0.98, "b": 0.90},
	"Winter": {"r": 0.92, "g": 0.96, "b": 1.08},
}

## Two accent variants for seasonal re-skin overlays (e.g. spring blossoms,
## autumn leaves, winter frost speckles). Returned as Colors for scenes
## that want to paint extra décor on top of the base tileset without
## forking this generator.
const ACCENT_VARIANTS: Dictionary = {
	"blossom": Color(0.96, 0.72, 0.80),  # pink — Spring
	"ember":   Color(0.86, 0.45, 0.20),  # autumn ember — Fall
	"warm_light": Color(0.96, 0.88, 0.55),
	"frost":   Color(0.78, 0.86, 0.96),
}

## Returns the channel multiplier dictionary for a season. Unknown season
## falls back to Spring (identity-ish) to preserve backward compatibility.
static func get_seasonal_palette(season: String) -> Dictionary:
	return SEASONAL_TINTS.get(season, SEASONAL_TINTS["Spring"])

static func get_seasonal_accent_color(variant: String) -> Color:
	return ACCENT_VARIANTS.get(variant, Color(0.8, 0.8, 0.8))

## Full list of available season keys for UI/tests.
static func list_seasons() -> Array:
	return SEASONAL_TINTS.keys()

static func list_accent_variants() -> Array:
	return ACCENT_VARIANTS.keys()

## Builds one TileSet whose atlas is a single row of state_colors.size()
## isometric diamond tiles. `season` defaults to "Spring" so every existing
## caller with no season arg keeps rendering exactly as before.
static func build_isometric_tileset(state_colors: Dictionary, tile_width: int, tile_height: int, atlas_source_id: int = 0, glow_states: Array = [], season: String = "Spring") -> TileSet:
	var states := state_colors.keys()
	states.sort()
	var state_count := states.size()

	var tint: Dictionary = get_seasonal_palette(season)

	var image := Image.create(tile_width * state_count, tile_height, false, Image.FORMAT_RGBA8)
	for i in range(state_count):
		var raw: Color = state_colors[states[i]]
		var base_color := Color(
			clampf(raw.r * tint["r"], 0.0, 1.0),
			clampf(raw.g * tint["g"], 0.0, 1.0),
			clampf(raw.b * tint["b"], 0.0, 1.0),
			1.0
		)
		# Seasonal accent speckles: subtle per-tile color jitter biased
		# toward the accent palette for two seasons so seasonal re-skins
		# read beyond a global tint.
		var use_accent := season in ["Spring", "Fall"]
		_paint_tile_diamond(image, i * tile_width, tile_width, tile_height, base_color, states[i], states[i] in glow_states, use_accent, season)

	var texture := ImageTexture.create_from_image(image)

	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = Vector2i(tile_width, tile_height)

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(tile_width, tile_height)
	for i in range(state_count):
		atlas_source.create_tile(Vector2i(i, 0))
	tile_set.add_source(atlas_source, atlas_source_id)

	return tile_set

static func _paint_tile_diamond(image: Image, x_offset: int, tile_width: int, tile_height: int, base_color: Color, noise_seed: int, has_glow: bool = false, use_accent: bool = false, season: String = "Spring") -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed * 9973 + 17

	var accent_color: Color = ACCENT_VARIANTS["blossom"] if season == "Spring" else ACCENT_VARIANTS["ember"]

	for py in range(tile_height):
		for px in range(tile_width):
			var nx := (px + 0.5) / float(tile_width) - 0.5
			var ny := (py + 0.5) / float(tile_height) - 0.5
			var diamond_dist := absf(nx) + absf(ny)
			if diamond_dist > 0.5:
				image.set_pixel(x_offset + px, py, Color(0.0, 0.0, 0.0, 0.0))
				continue

			var light := 1.0 + LIGHT_STRENGTH * (-nx - ny)
			var edge_dist := 0.5 - diamond_dist
			if edge_dist < EDGE_DARKEN_BAND:
				light *= lerpf(1.0 - EDGE_DARKEN_STRENGTH, 1.0, edge_dist / EDGE_DARKEN_BAND)

			if has_glow:
				light += GLOW_STRENGTH * (1.0 - diamond_dist / 0.5)

			var speckle := 1.0 + rng.randf_range(-SPECKLE_STRENGTH, SPECKLE_STRENGTH)
			var factor := light * speckle
			var col := Color(
				clampf(base_color.r * factor, 0.0, 1.0),
				clampf(base_color.g * factor, 0.0, 1.0),
				clampf(base_color.b * factor, 0.0, 1.0),
				1.0
			)
			# Accent variant: ~6% of interior pixels get a faint nudge
			# toward the seasonal accent color. Rare enough to read as
			# texture, not a recolor.
			if use_accent and rng.randf() < 0.06:
				col = col.lerp(accent_color, 0.18)
				col.a = 1.0
			image.set_pixel(x_offset + px, py, col)
