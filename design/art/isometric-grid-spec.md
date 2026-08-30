# Isometric Grid — Spec (UX-GRID)

Squad: UX-UI-Designer
Source: `backlog-inbox.md` item `UX-GRID`
Scope: the technical/art convention for the 2.5D isometric grid decided in
DEC-E (#6) — ratio, tile dimensions, coordinate transform, and depth
sorting. Not a game-design decision; a standard, well-precedented
implementation convention that unblocks environment art and tilemap work
without needing further owner input.

This has been the single blocker standing between ENG-13/14/16/17
(Agriculture, Ranching, Mining, Foraging environments) and being picked
up for several epochs — everything else those sub-issues need
(TimeManager, SkillManager) already shipped.

## 1. Grid ratio

**2:1** (width:height diamond) — the standard for pixel-art isometric,
used by the genre's closest precedent for this camera style (RollerCoaster
Tycoon, Age of Empires II, Diablo-era isometric ARPGs). Godot's TileMap
has native isometric mode built around this same ratio, so it costs
nothing against the ENG-STACK decision (#30, Godot).

## 2. Base tile dimensions

**64×32 px** ground tile footprint at runtime (Godot `TILE_SHAPE_ISOMETRIC`). Source authoring is **16×16 px** (PO-16BIT-GFX-2) — deterministic Pillow tiles are generated at 16×16 and scaled/stitched to 64×32 atlas via `_try_build_pixelart_tileset()` so the engine compat layer is untouched. Large enough for readable pixel-art
detail at typical modern display scales, small enough to keep the
environment-art backlog's per-tile-variant cost (flagged in DEC-E's
resolution comment on #6) from ballooning further. Object/prop sprites are
not fixed to this size — only the ground tile footprint is.

## 3. Coordinate transform

Grid coordinates `(gx, gy)` (integer tile indices) to screen/world pixel
position:

```
screen_x = (gx - gy) * (TILE_WIDTH / 2)   # TILE_WIDTH = 64
screen_y = (gx + gy) * (TILE_HEIGHT / 2)  # TILE_HEIGHT = 32
```

Inverse (screen pixel position to grid coordinates), for click-to-move or
placement logic:

```
gx = (screen_x / (TILE_WIDTH / 2) + screen_y / (TILE_HEIGHT / 2)) / 2
gy = (screen_y / (TILE_HEIGHT / 2) - screen_x / (TILE_WIDTH / 2)) / 2
```

Round `gx`/`gy` to the nearest integer tile when converting a click/tap
position to a tile index.

## 4. Object anchor & depth sorting

- Entities and props anchor at the **bottom-center** of the tile diamond
  they occupy — matches how Godot's `YSort`-enabled container draws
  children correctly without manual z-index math, as long as each
  entity's `position.y` reflects its visual "feet" point.
- Recommended scene structure: static terrain on a Godot `TileMap` in
  isometric mode; dynamic objects (NPCs, player, droppable items, props)
  under a single `YSort`-enabled `Node2D` parent, so draw order falls out
  of screen-Y automatically instead of being hand-maintained per object
  type.

## 5. Compatibility note — no changes needed to already-shipped code

`NPCController` (#18, already merged) operates entirely in continuous
`Vector2` world/pixel positions — it never did grid-index math and doesn't
need to. This spec's transform only matters for *placing* things onto the
grid (environment tilemaps, click-to-move target resolution); once an
entity has a world position, existing movement code is unaffected. No
retrofit required.

## 6. Open items for Engineer squad (not decided by this spec)

- Exact tile art per terrain type (farmland states, mine floor variants,
  etc.) — content, not convention; still gated on actual art production.
- Click-to-move / tile-picking implementation details — this spec gives
  the transform math, not the input-handling code.
- Any camera zoom/pan constraints — out of scope here.

## 7. Traceability

| Element | Consumer |
|---|---|
| Grid ratio, tile size | Environment tilemaps: #13, #14, #16, #17 |
| Coordinate transform | Any future click-to-move / placement logic |
| Depth sorting convention | All dynamic scene objects, including #18's `NPCController` (no change needed) |
| Godot isometric TileMap fit | Confirms no reopening of ENG-STACK (#30) |
