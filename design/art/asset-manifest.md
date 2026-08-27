# Asset Manifest — `assets/pixelart/`

Origin (Art-Squad): maps every shipped asset to the game content it
represents, so the concurrent Frontend/Building session can wire sprites
in without re-discovering what exists. All assets are **original**, generated
deterministically by `assets/pixelart/generator/*.py`, dedicated CC0
(`assets/pixelart/LICENSE.txt`). 109 PNGs total (see count table below).

**Ground tiles** are 64×32 isometric diamonds (2:1) matching
`design/art/isometric-grid-spec.md` and `ProceduralTileArt`'s convention
(transparent outside the diamond, upper-left light, edge darken, speckle). They
slot in as `TileMap` floor tiles. **Everything else** (characters, crops,
animals, items, props, map, UI) is placed as standalone `Sprite2D` assets
anchored **bottom-center**, the convention locked in `squad-handshake-art.md`
epoch 3/4 — not subject to the TileMap diamond math.

## Directory / file inventory (109 PNGs)

### `tiles/` (13)
| file | intended use |
|---|---|
| grass.png | default outdoors floor (farm/map) |
| grass_clover.png | grass variant (forage/field edges) |
| dirt.png | dirt / tilled plotting floor |
| farmland.png | hoed plot tile |
| farmland_watered.png | watered plot tile |
| path.png | walking path |
| sand.png | river/lake bank (ranch shore) |
| water_0.png, water_1.png | 2-frame animated water |
| mine_floor.png | mine floor tile |
| mine_rock.png | intact rock tile |
| snow.png | winter ground tile |
| wood_floor.png | building interior floor |

### `characters/` (sheet = 48×120; 3 rows × 2 frames, frame 24×40)
Rows: **0 = facing down, 1 = facing up, 2 = facing side** (flip horizontally
at runtime for the opposite side). Frame anchor = bottom-center (feet).
`portrait_<name>.png` = 32×32 headshot for the Relationships overlay.

| File | character | palette notes (matches cast archetypes) |
|---|---|---|
| player.png / portrait_player.png | the player | green shirt, denim |
| colton.png / portrait_colton.png | Colton (miner/blacksmith) | grey work shirt, beard |
| elena.png / portrait_elena.png | Elena | purple dress, long blonde hair |
| marcus.png / portrait_marcus.png | Marcus | teal sweater, grey hair |
| priya.png / portrait_priya.png | Priya | red sari-style dress |
| sana.png / portrait_sana.png | Sana (rancher) | red shirt, ponytail |
| tobias.png / portrait_tobias.png | Tobias (treasure hunter) | khaki + wide hat |

### `crops/` (each = 4-stage horizontal strip, 48px per stage frame)
Stage 0 sprout, 1 juvenile, 2 mature (unharvested), 3 harvest-ready.
Bottom-center anchor. Matches `FarmPlotManager` registered ids:
`crops/<crop_id>.png` → parsnip, cauliflower, tomato, melon, pumpkin,
corn, frost_kale.

### `animals/` (each = 3-frame bob strip, 96×32, frame 32px, facing right)
Matches `AnimalManager` registered species ids:
`chicken, duck, cow, goat, sheep`.

### `items/` (16×16 icons) — `icon_<item_id>.png`
Covers every registered content id at seed time, plus tool/raw-material ids:
crops (7): parsnip cauliflower tomato melon pumpkin corn frost_kale
ores (4): copper_ore iron_ore gold_ore diamond
fish (7): carp trout salmon tuna bream bass sardine
forage (9): wild_berries wild_flower spring_onion sweet_pea mushroom
           hazelnut snow_truffle winter_root four_leaf_clover
animal products (5): egg duck_egg milk goat_milk wool
tools (4): hoe watering_can axe pickaxe
raw (4): stone coal wood gold

### `props/` (16 standalone sprites, bottom-center)
`tree`, `tree_2` (autumn), `pine`, `fruit_tree`, `bush`, `rock`,
`rock_large`, `mine_cart`, `ladder`, `fence_h`, `fence_v`,
`shipping_bin`, `farmhouse`, `barn`, `coop`, `well`.

### `map/`
`world_map.png` (256×256) — stylized regional overview for `MapOverlay`
(island = farm+town+forest, north island = mine, fields plotted, roads,
town cluster, lake).

### `ui/` icons (13) — `icon_<name>.png`
`heart`, `heart_empty`, `coin`, `bolt` (stamina), `clock` (time),
`bowl` (feed animals), `gift` (relationships), `bundle` (community goal),
`flag` (festival), `sun`/`rain` (weather), `fishing`, `journal`.

## Wiring notes for the Frontend session
- World scenes already call `ProceduralTileArt.build_isometric_tileset()`
  for their current flatten-color tiles. These `.png`s are offered as
  higher-fidelity **replacement floor tiles / deco sprites**; swapping is
  additive and does not require changing scene logic.
- Sprites are all bottom-center anchored by design; set `centered = false`
  and offset `(-width/2, -height)` for feet placement per the grid spec
  (the same convention `ProceduralCharacterArt` documents).
- No `.tscn`, `.gd`, `.res`, or `.tres` files were touched — Art-Squad lane
  only added static assets + docs, so nothing here conflicts with the
  backend/frontend build.

## Count check
```
tiles 13 · characters 14 · crops 7 · animals 5 · items 40 · props 16 · map 1 · ui 13
TOTAL 109 PNGs
```
(verified above with `find assets/pixelart -name '*.png' | wc -l` → 109)