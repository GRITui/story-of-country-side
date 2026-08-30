# Attribution — Isometric Miniature Dungeon (Kenney)

- **Original pack**: [Isometric Miniature Dungeon](https://kenney.nl/assets/isometric-miniature-dungeon) by [Kenney](https://kenney.nl) (www.kenney.nl)
- **License**: CC0 1.0 Universal (public domain dedication) — see `License.txt` in this directory, copied verbatim from inside the pack itself (`Dungeon Pack (2.3)`, same CC0 text as `assets/kenney/isometric-miniature-farm/License.txt`, verified independently per-pack rather than assumed from that sibling directory).
- **Retrieved via**: the [Tiddybub/2d-assets](https://github.com/Tiddybub/2d-assets) GitHub mirror (`fantasy/isometric-miniature-dungeon/`), same CC0-only catalog used for the farm pack — see that pack's own `ATTRIBUTION.md` for why this mirror was used instead of kenney.nl directly (egress policy).
- **Files used here** (cropped to their opaque bounding box from the pack's original 256×512 canvas):
  - `barrel_S.png` — decorative barrel
  - `barrelsStacked_S.png` — decorative stacked barrels
  - `chestClosed_S.png` — decorative closed chest
  - `stoneColumn_S.png` — decorative stone support column

## Why these are decoration, not tileset replacements

Same measured incompatibility as the farm pack: this pack's own ground/floor
tiles (`dirt_S.png`) measure the same ~1.84:1 true-isometric footprint
ratio, not the locked 2:1 dimetric convention `design/art/isometric-grid-spec.md`
requires. `MineScene`'s rock/floor/ladder tiles stay on `ProceduralTileArt`
for the same reason `FarmScene`'s ground tiles do. These four props are
standalone `Sprite2D` decorations around the grid border, not part of the
`TileMap`'s tiling math.
