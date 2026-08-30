# 16-bit Style Guide

Source: #141. Kills all prior art (ProceduralTileArt flat, Kenney mixed, truecolor pixelart) → single 16-bit source of truth. All assets under `assets/16bit/` deterministic Pillow, CC0.

## Lock
- Grid `design/art/isometric-grid-spec.md` 2:1 64×32 diamond, bottom-center YSort unchanged — no engine change.

## Palette (SNES BGR555-ish, 15+transparent, 4bpp per asset, 1px black outline #1a1a2e)
- Earth: #8b6f47 #a0826d #c9b896 #5a3e2b
- Grass: #5a9a3a #7bc45a #3a6b2a #a8e090 flower #fff08c dot #fff
- Dirt/farmland: #9a7a4a / #7a5a3a wet #4a3a2a sheen #c9a87c
- Sand: #e8dcc0 shell #fff, path #d4c4a0 pebble #a09070
- Water: #3a6ea5 #5a8ec5 #2a4a7a wave #7ab8e0
- Mine: floor #4a3a36 highlight #6a5a56 rock #3a3a42 shadow #1e1e28 ladder #c9a43a
- Snow: #e8f0f8 blue #c0d0e8, wood #8b6b4a grain #6b4a2a
- Accent: red #d94a4a green #5ad94a yellow #f0d860 white #f8f8f0 black #1a1a2e
- Characters: 4 colors + outline per sheet, distinct cast (player green denim #5aaa5a/#4a5a8a, colton grey #6a6a7a beard #3a3a42, elena lavender #b080c0, etc.)

## Tile 64×32 (16×16 source, Godot 64×32 compat)
Source authoring is **16×16 px** per PO-16BIT-GFX-2 (deterministic Pillow), rendered as **64×32 isodiamond** at runtime via `TILE_WIDTH=64 TILE_HEIGHT=32 TILE_SHAPE_ISOMETRIC TILE_LAYOUT_DIAMOND_DOWN` compat layer (`design/art/isometric-grid-spec.md`). No engine break — atlas is still 64×32, transparent outside diamond.
1px outline, 2-level checker dither, light UL 0.22, speckle 0.06, edge darken 0.52, glow center 0.4 for STATE_READY.

## Layer Stack (Canvas)
Ground (TileMap) → Tilled/Watered Overlay (second TileMap state or atlas tile) → **Y-sorted Entities** `DynamicLayer` (`y_sort_enabled=true`, sort by `footY = position.y`, i.e. `a.footY - b.footY`) → Canopy/Trees (Sprite2D above entities) → Weather/DayNight overlay (`DayNightOverlay` ColorRect/CanvasModulate top).

## Chibi Spec
Base 16×16 grid, character footprint **24×32 px, 1:2.2 head**, head 55–60% (18px of 32px), eyes 3–6px with catchlight, hue-shifted 3–4 shades, sel-out navy/burgundy, 3/4 oblique 30–45°, shadow 8×4/12×6. 4 dirs Down/Up/Left/Right: Idle 2F breath/blink, Walk 4F 1px head bob +1F hair lag, **Tool Swing 3F Anticipation-Impact-Recovery**, Holding overhead (item 8px above head, arms raised).

## Japanese Tileset Placeholders
Farmland uses 16-bit props as placeholders: mossy stone walls (`rock`/`rock_large` recolor), **kawara roofs** (`kawara_roof.png` — dark tile grey #4a4a5a with ridge highlight, from `gen_props.py`), canals animated water (`water_0/1`), **Jizō statues** (`jizo_statue.png` — 16×28 stone with red bib). Full Japanese tileset is a future illustrated pass; current placeholders reuse 16-bit prop pipeline and are documented here for wiring without breaking Godot's 64×32 compat.

## Lighting LUT (Day/Night)
Driven by `TimeManager.hour` via `scripts/world/day_night_overlay.gd` (ColorRect overlay, not shader): 06:00 warm amber `Color(1.10,0.98,0.84)` modulate 1.0 + soft alpha 0.08, 10:00 crisp saturated `Color(1.0,1.0,1.0)` alpha 0.0, 17:00 golden vermilion `Color(1.12,0.78,0.62)` alpha 0.14, 20:00 cool indigo `Color(0.72,0.78,1.10)` alpha 0.22 + lantern point lights (modulate). Lerp between keys per hour. Deterministic, no shader.

## Characters 48×120 (3×2 24×40), portrait 32×32, props 16–64px, items 16×16, crops 192×48 4-stage, animals 96×32 3-frame, map 256×256, UI 16×16 — all 4-color+outline, bottom-center anchor, deterministic Random(seed).

## Generators `assets/16bit/generator/*.py`
- `gen_tiles.py` → 13 tiles
- `gen_characters.py` → 14 sheets/portraits
- `gen_crops.py` → 7, `gen_animals.py` →5, `gen_items.py` →40, `gen_props.py` →16, `gen_map.py` →1, `gen_ui_icons.py` →13 = 109 PNGs
- No image-gen tool, Pillow only, byte-identical rerun.

## Wiring
Hard require: `scripts/world/*_scene.gd:_build_tileset()` stitches `assets/16bit/tiles/*.png` atlas, `player_avatar.gd`/`npc_controller.gd` region anim, `map_overlay.gd` world_map, no Procedural* fallback.
