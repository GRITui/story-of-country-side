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

> **2026-08-30 — JRL supersede notice (`feat/jrl-art-pack`).** The Western
> placeholder set below (animals, western characters/portraits, western crops,
> old item icons, barn/coop/mine props, old tile set, old UI icons — 122 PNGs)
> has been **removed** and replaced by the Japanese countryside pack in
> § "JRL pack" below. The old inventory is kept for reference of what game
> code still references (see GitHub issue "JRL art pack — rework list").

## JRL pack (current source of truth)

Style: "High-Bit Kominka Crisp", pastel Ghibli, sel-out `#4A3320`,
transparent backgrounds, deterministic Pillow generators
(`gen_jp_pack.py`, `gen_jp_characters.py`, plus earlier `gen_*_jrl_b.py`).

### `crops/` — unified sheet `crops_jp_sheet.png` (80×80, 16px cells)
Rows: rice, daikon, nasu, edamame, sweet_potato. Cols: growth stage 0–3 +
harvest icon. Rice stages sit on a flooded-paddy base; the rest on soil.
Per-crop files: `<name>_0..3.png` + `<name>.png` (64×16 strip);
harvest icons in `items/icon_{rice,daikon,nasu,edamame,sweet_potato}.png`.
Also present from the earlier batch: turnip, watermelon stages/strips.

### `items/` — `tools_jp_sheet.png` (80×16)
kuwa (hoe), kama (sickle), bamboo watering can, bug net, bamboo fishing
rod; also as individual `icon_*.png`.

### `ui/` — `ui_jp_sheet.png` (160×16)
washi_slot, hotbar_slot, hotbar_slot_sel, bento_full/half/empty
(stamina gauge), season indicators: sakura, ginkgo, momiji, snowflake.
`washi_panel.png` (48×48) = 9-patch inventory/dialog panel.

### `characters/`
- `player_jp.png` (384×256): 24×32 cells, 16 cols (Down/Up/Left/Right ×
  4 frames) × 8 rows: idle, walk, sit_engawa, hoe, plant, net, fish, bow.
  Bottom-center pivot identical across all frames (feet y=31, cx=11.5) —
  wire as `AnimatedSprite2D` region anim. `player_jp_winter.png` /
  `player_jp_yukata.png` are palette-swap variants (hanten+knit cap /
  festival yukata+obi with asanoha dots).
- `npc_chiyo.png` (384×64): rows idle/walk, same grid; grey bun, plum
  kimono, kappogi apron, bamboo broom on idle.
- `portrait_chiyo_<expr>.png` 128×128 (4× nearest upscale; 32×32 masters
  saved as `*_32.png` for the existing dialogue UI). Expressions:
  gentle_smile, chuckling, nostalgic, surprised, concerned.

### `props/`, `tiles/` (earlier JRL-B batch)
farmhouse + 4 seasonal variants, sakura + 4 seasonal variants, jizo_shrine,
hanna_store, smoke_0..2; grass seasonal variants, soil till/water states,
paddy canal_strip, tatami, animated water_0..3, palette_jrl_b reference.

### 2026-08-30 — Self-sufficiency items (issue #187, `design/187-self-sufficiency`)

`items/icon_{salt,miso,tofu,koji,soybean,seaweed,nigari}.png` (16×16) +
combined `items/self_sufficiency_sheet.png` (112×16, same order), generated
by `gen_jp_self_sufficiency.py` (deterministic, sel-out `#4A3320`). Backs the
salt/miso/tofu production loops in `design/systems/self-sufficiency-spec.md`.
Follow-up art (not yet present): `soy_milk` icon, `soybean` growth stages,
`seaweed` forage-node sprite, `salt_shed`/`tamaru`/`tofu_press` props.

## Directory / file inventory (109 PNGs) — SUPERSEDED, see notice above

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

## Polish pass — 2026-08-30 (fix/p0-avatar-input-restoration)

Deterministic re-generation on this branch, no new files (still 109 PNGs).
All outputs remain PIL-only procedural, CC0, `bottom-center` anchored, and
reproducible via the `python3 gen_*.py` sequence in `LICENSE.txt`.

- **Tiles** (`gen_tiles.py`): palette saturation + contrast pass — grass
  spring green (more Stardew-leaning), dirt/farmland richer chocolates with
  stronger furrow + pebble texture, watered tile darker with sheen, path
  pebble shadow/highlight, sand shell specks, water deeper with wave-shadow,
  mine rock highlight/shadow, snow blue ambient, wood grain highlight.
  Diamond light 0.24 / edge 0.52 for crisper tile definition.
- **Characters** (`gen_characters.py`): palettes re-saturated for cast
  read (player vivid green/denim, Colton grey-beard, Priya warm sari red
  vs Sana rancher red, etc.), stronger top-light (`shade_v` 1.14→0.88) +
  shirt highlight, eye glint.
- **Props** (`gen_props.py`): trees/pine/bush now layered shadow + highlight
  tufts, trunk vertical shading, fruit-tree apple highlights, rock/bush
  underside shadow — addresses "flat pawn / small props / no tree variety"
  without changing footprint or anchor.
- **Crops** (`gen_crops.py`): leaf/fruit contrast pass, fruit highlight +
  shadow chips for harvest-ready legibility.
- **Animals** (`gen_animals.py`): chicken eye glint + belly shadow, cow
  Holstein spots / leg highlight, sheep wool volume (highlight/shadow).
- **UI** (`gen_ui_icons.py`): heart fuller + extra fill pixels.
- **Map** (`gen_map.py`): fixed dead `_region` stub (was `speckle_on(Image)`).

Verified: `python3 assets/pixelart/generator/validate.py` → 109 PNGs clean,
`godot --headless --import` still produces 109 `.import` files, anchor spec
unchanged.

## Count check
```
tiles 13 · characters 14 · crops 7 · animals 5 · items 40 · props 16 · map 1 · ui 13
TOTAL 109 PNGs
```
(verified above with `find assets/pixelart -name '*.png' | wc -l` → 109)

## JRL pack — 2026-08-30 cozy activities icons (design/190-cozy-activities)

Issue #190. Generator: `assets/16bit/generator/gen_jp_cozy.py`
(deterministic; re-run reproduces byte-identical PNGs; `validate.py` → OK,
114 PNGs total). Sel-out `#4A3320`, transparent bg, pastel Ghibli.

### `items/` — cozy icons (16×16) + `cozy_sheet.png` (48×16)
| file | use |
|---|---|
| `icon_tea_set.png` | matcha chawan + bamboo chasen — Cozy Corner tea set (spec: `design/systems/cozy-activities-spec.md`) |
| `icon_ikebana.png` | celadon vase, 2 stems, 1 sakura blossom — ikebana vase |
| `icon_journal.png` | washi-bound book (red stab binding, title slip, hanko) + brush — writing desk |
| `cozy_sheet.png` | combined 48×16 strip, order: tea_set, ikebana, journal |