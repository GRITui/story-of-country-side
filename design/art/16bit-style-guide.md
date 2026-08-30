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

## Tile 64×32
1px outline, 2-level checker dither, light UL 0.22, speckle 0.06, edge darken 0.52, glow center 0.4 for STATE_READY.

## Characters 48×120 (3×2 24×40), portrait 32×32, props 16–64px, items 16×16, crops 192×48 4-stage, animals 96×32 3-frame, map 256×256, UI 16×16 — all 4-color+outline, bottom-center anchor, deterministic Random(seed).

## Generators `assets/16bit/generator/*.py`
- `gen_tiles.py` → 13 tiles
- `gen_characters.py` → 14 sheets/portraits
- `gen_crops.py` → 7, `gen_animals.py` →5, `gen_items.py` →40, `gen_props.py` →16, `gen_map.py` →1, `gen_ui_icons.py` →13 = 109 PNGs
- No image-gen tool, Pillow only, byte-identical rerun.

## Wiring
Hard require: `scripts/world/*_scene.gd:_build_tileset()` stitches `assets/16bit/tiles/*.png` atlas, `player_avatar.gd`/`npc_controller.gd` region anim, `map_overlay.gd` world_map, no Procedural* fallback.
