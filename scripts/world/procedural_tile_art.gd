class_name ProceduralTileArt
## Shared procedural texture generator for isometric world-scene tilesets.
##
## Art Squad (#52 adjacent sub-scope): every world scene (FarmScene/
## RanchScene/ForageScene/MineScene) previously built its own
## _build_placeholder_tileset() that filled a solid, fully opaque 64x32
## rectangle per tile state -- flat color, no shading, no texture. Two real
## problems with that beyond just looking flat:
##   1. An isometric TileMap in TILE_LAYOUT_DIAMOND_DOWN places each tile's
##      texture with 50% vertical row overlap, expecting the texture to be
##      transparent outside the diamond footprint. A fully opaque rectangle
##      occludes whatever's drawn at the bottom of the row above it.
##   2. No shading/gradient/texture at all reads as a UI color swatch, not
##      ground.
## This generator fixes both while staying honest about what it is: no
## image-generation tool exists in this environment (see
## squad-handshake-art.md), so every pixel here comes from procedural
## Image/Color math -- alpha-masking the actual diamond shape, a fixed-
## direction light gradient, a darkened edge outline for tile definition,
## and deterministic per-pixel speckle grain for texture variety. This is a
## genuine visual upgrade over a flat fill, not illustrated art; a human
## artist or an image-gen pipeline this environment doesn't have is still
## the eventual real answer for Decision E (#6).
##
## Drop-in replacement: same atlas addressing every scene's own
## _paint_tile()/_refresh_tile() already relies on (Vector2i(state, 0) at
## ATLAS_SOURCE_ID = 0), same TileSet shape/layout/tile_size -- this only
## replaces how the TileSet's pixels are generated. No scene's
## STATE_COLORS dictionary, state-derivation logic, or signal wiring
## changes to use this.

## How strongly the simulated upper-left light source brightens/darkens a
## pixel based on its position within the diamond (isometric tile-art
## convention -- see e.g. the genre references design/art/isometric-grid-spec.md
## itself cites).
const LIGHT_STRENGTH := 0.22
## Fraction of the diamond's half-width, measured inward from its edge,
## that gets progressively darkened into a border -- keeps adjacent tiles
## reading as distinct shapes instead of one flat wash.
const EDGE_DARKEN_BAND := 0.07
const EDGE_DARKEN_STRENGTH := 0.55
## Per-pixel deterministic brightness jitter (+/-), giving the fill a
## grain/texture instead of a perfectly smooth gradient.
const SPECKLE_STRENGTH := 0.10
## How much extra brightness a glow_states tile gets at its exact center,
## fading to none by the diamond's edge -- a soft "this tile wants your
## attention" highlight for whichever states a calling scene marks as its
## interactive/rewarding ones (see build_isometric_tileset's glow_states
## param).
const GLOW_STRENGTH := 0.4

## Builds one TileSet whose atlas is a single row of state_colors.size()
## isometric diamond tiles, ordered by ascending integer state key so
## atlas coordinate Vector2i(state, 0) always lands on the right tile --
## every calling scene's states are a contiguous 0..N-1 range, matching
## that assumption exactly.
##
## glow_states (optional): state keys that should render with an added
## center-weighted brightness bloom on top of the normal shading -- for
## whichever state in a calling scene's own STATE_* set marks "available
## to interact with right now" (a ready-to-harvest crop, an available
## forage node, a mine's ladder, etc.). Purely a visual accent; doesn't
## change which states exist or how a scene derives them.
static func build_isometric_tileset(state_colors: Dictionary, tile_width: int, tile_height: int, atlas_source_id: int = 0, glow_states: Array = []) -> TileSet:
	var states := state_colors.keys()
	states.sort()
	var state_count := states.size()

	var image := Image.create(tile_width * state_count, tile_height, false, Image.FORMAT_RGBA8)
	for i in range(state_count):
		var base_color: Color = state_colors[states[i]]
		_paint_tile_diamond(image, i * tile_width, tile_width, tile_height, base_color, states[i], states[i] in glow_states)

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

## Draws one alpha-masked isometric diamond into image at x_offset (tile_width
## wide, tile_height tall): gradient shading + edge darken + deterministic
## speckle grain + an optional center glow, all derived from base_color alone
## so every calling scene's existing STATE_COLORS dictionary works completely
## unmodified. Outside the diamond is left fully transparent (alpha 0),
## matching what an isometric TileMap in diamond-down layout expects.
static func _paint_tile_diamond(image: Image, x_offset: int, tile_width: int, tile_height: int, base_color: Color, noise_seed: int, has_glow: bool = false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed * 9973 + 17 # deterministic per state, stable across runs/tests

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

			image.set_pixel(x_offset + px, py, Color(
				clampf(base_color.r * factor, 0.0, 1.0),
				clampf(base_color.g * factor, 0.0, 1.0),
				clampf(base_color.b * factor, 0.0, 1.0),
				1.0
			))
