# Attribution — Isometric Miniature Farm (Kenney)

- **Original pack**: [Isometric Miniature Farm](https://kenney.nl/assets/isometric-miniature-farm) by [Kenney](https://kenney.nl) (www.kenney.nl)
- **License**: CC0 1.0 Universal (public domain dedication) — see `License.txt` in this directory, copied verbatim from inside the pack itself. Free for personal, educational, and commercial use; attribution appreciated but not required.
- **Retrieved via**: the [Tiddybub/2d-assets](https://github.com/Tiddybub/2d-assets) GitHub mirror (`nature/isometric-miniature-farm/`), a CC0-only asset catalog that re-hosts the same pack under the same CC0-1.0 license (see that repo's own `LICENSE` and this pack's `SOURCE.md`, both copied here). Not fetched from kenney.nl directly — this environment's egress policy blocks kenney.nl, opengameart.org, and itch.io; GitHub is reachable, and this mirror's provenance was verified against the pack's own bundled `License.txt` before use, not trusted on the mirror's label alone.
- **Files used here** (cropped to their opaque bounding box from the pack's original 256×512 canvas — see below):
  - `hayBales_S.png` — decorative hay bale stack
  - `sacksCrate_S.png` — decorative sack/crate stack
  - `fenceLow_S.png` — decorative low fence section
  - `cornDouble_S.png` — decorative corn stalk pair

## Why these are decoration, not tileset replacements

The pack's own ground/floor pieces (`dirt_S.png`, `dirtFarmland_S.png`, etc.) are true-isometric (~30°) renders with a measured footprint ratio of roughly 1.73:1–1.84:1 (width:height of the opaque diamond), not the 2:1 dimetric ratio `design/art/isometric-grid-spec.md` locks in (the RollerCoaster-Tycoon/Age-of-Empires-II-style convention Godot's `TileSet.TILE_SHAPE_ISOMETRIC` math assumes). Stretching them to fit would visibly distort the art; using them un-stretched would misalign the `TileMap`'s diamond-down tiling against every other already-shipped ground tile. So the four world scenes' ground tiles stay on `ProceduralTileArt` (see that file's own docstring) — this pack is used only for standalone decorative props, which aren't part of the `TileMap`'s tiling math and can be any size/shape, the same way `ProceduralCharacterArt`'s NPC silhouette is a free-floating `Sprite2D`, not a tile.
