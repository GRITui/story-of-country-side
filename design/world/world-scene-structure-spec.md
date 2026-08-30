# World Scene Structure Spec — TileMap Layers, Collision, Prefab Hierarchies

**Status:** Normative blueprint (orch-006 save-integrity branch, Systems & Level Design seat).
Every number below was read out of shipped code at blueprint time — nothing is
invented. Where code disagrees with intent, the disagreement is listed in §8
instead of silently harmonized.

**Sources of truth consumed:** `design/art/isometric-grid-spec.md`,
`scripts/world/*.gd`, `scripts/npc/npc_roster.gd`, `scripts/story/main_controller.gd`,
`tests/test_runner.gd` frontend blocks, `project.godot`.

---

## 1. Purpose

This spec defines the canonical structure every world scene (current four +
planned ORCH-008 coast/mountain maps) must converge onto:

- one shared **TileMap layer stack** with agreed semantics per layer,
- one shared **collision/physics layer matrix** (`scripts/world/physics_layers.gd`
  is the machine-readable source of truth),
- one shared set of **prefab hierarchies** with signal contracts,
- explicit **persistence touchpoints** wired to the hardened SaveManager pipeline.

Consuming squads implement toward this document; structural reviews diff PRs
against it.

## 2. Global canvas conventions

| Property | Value | Verified at |
|---|---|---|
| Tile projection | Isometric dimetric, `TILE_SHAPE_ISOMETRIC`, `TILE_LAYOUT_DIAMOND_DOWN` | procedural_tile_art.gd:77–78 |
| Tile footprint | 64 × 32 px (2:1 diamond-down) | isometric-grid-spec.md, every world scene const |
| Logical grid key | `Vector2i` `(gx, gy)` per isometric-grid-spec §coordinate system | FarmPlotManager keys |
| Screen-space mapping | `tilemap.map_to_local(cell)` / `local_to_map(point)` exclusively | farm_scene._facing_tile |
| Facing-reach | `avatar.facing * TILE_HEIGHT` from avatar origin = adjacent tile center | farm_scene.gd:314 |
| Time/camera | World clock frozen never handled here; camera zoom 2× today | farm_scene Camera2D |

Rules that keep iso math sane:

1. Never convert coordinates with hand math outside the TileMap helpers.
2. Entities whose art reads "standing on a tile" must be positioned at
   `map_to_local(cell)`; bottom-anchored sprites (`centered=false`) sit
   naturally there because the diamond's top vertex is the anchor line.
3. Depth sorting happens ONLY inside Y-sort containers (see §3) — standalone
   `z_index` nudges are forbidden in world scenes.

## 3. Canonical node hierarchy (the layer stack)

```
WorldScene (Node2D, scene script — e.g. farm_scene.gd)
├─ GroundTileMap      : TileMap — terrain/dirt/grass; autotiles by season where content exists
├─ StateTileMap       : TileMap — THIS scene's gameplay-state overlay
│                        Farm   -> FarmPlotManager plot states (STATE_EMPTY/PLANTED/WATERED/READY/WITHERED)
│                        Ranch  -> pen states (STATE_EMPTY/UNFED/FED/READY)
│                        Mine   -> rock/floor/ladder lattice
│                        Forage-> available/gathered nodes
│                      One variant per state color today; replaced 1:1 by real art later
├─ DecorLayer         : Node2D — Kenney CC0 prop Sprite2Ds ONLY (ratio-mismatch rule:
│                        that pack's grounds are ~1.73–1.84:1 true-iso, locked 2:1
│                        floor tiles stay procedural — see assets ATTRIBUTION.md)
├─ DynamicLayer       : Node2D, y_sort_enabled = true  ← ALL mobile/interactive entities
│    ├─ PlayerAvatar  ┐
│    ├─ NPCController │ built today by scripts; see §6 prefab trees
│    └─ PropActors    ┘
├─ InteractablesRoot  : Node2D — non-sorted Area2D zones (SleepZone, TravelZone, bin trigger)
└─ Camera2D           : scene-anchored today; zoom (2,2) (see §8 CAMERA-FOLLOW)
```

Layer-ordering rationale (top of file = drawn last = on top):

- Ground < State < Decor keeps painted floors beneath their decorations while
  staying BELOW all living things regardless of row depth.
- `DynamicLayer.y_sort_enabled=true` is already shipped and asserted in tests;
  every mobile actor MUST be a direct child (nesting breaks sorting order).
- Interactables are intentionally OUTSIDE y-sort: they are invisible
  rectangles anchored to world positions, not visual bunnies racing sprites.

Node-name contract: tests address layers by literal name (`"DynamicLayer"`),
so renames require simultaneous fixture updates — treat these names as API.

## 4. Project-wide physics layer matrix

Machine-readable constants live in `scripts/world/physics_layers.gd`
(1-based layer indices; `PhysicsLayers.mask([...])` composes bitmasks).
Nothing collides today (no bodies exist) — this matrix is the target the
first physics PR implements, so bit numbers are frozen NOW, not per-PR.

| # | Name | Used by | Collides with (mask) |
|---|------|---------|----------------------|
| 1 | TERRAIN_SOLID   | TileSet physics shapes on rock/border/floor-edge tiles | DYNAMIC_BODY |
| 2 | PROPS_SOLID     | Large solid props: shipping bin body, mine-cart props | DYNAMIC_BODY |
| 3 | INTERACTABLE    | Area2D prefabs: SleepZone, bin trigger zone | DYNAMIC_BODY |
| 4 | WATER_BLOCKER   | Water edge tiles + future coast pier railings | DYNAMIC_BODY |
| 5 | DYNAMIC_BODY    | PlayerAvatar + NPCController bodies (layer) | 1,2,3,4 (masks from left columns) |
| 6 | SCENE_TRANSITION| TravelZone Area2Ds bridging `main_controller.travel_to()` | DYNAMIC_BODY |

Invariants:

- `DYNAMIC_BODY` masks must never contain `DYNAMIC_BODY` itself in v1 —
  villager pass-through keeps schedules reliable without collision steering.
- Areas listen to bodies (`body_entered`), not to areas.
- Layer assignment is decided by PREFAB, never per-scene overrides.

## 5. Collision shape specifications

### 5.1 Tile solids (TileSet physics layer → TERRAIN_SOLID / WATER_BLOCKER)

Diamond footprint of one 64×32 tile — exact polygon for the TileSet's
`ConvexPolygonShape2D` local points:

```
        (0,-16)
       /       \
 (-32,0)       (32,0)
       \       /
        (0,16)
```

Applied at half-tile precision on Mine rock walls, scene border rings, and
water edges. Border ring tiles beyond playable grid must also carry this
shape so avatar physics can't leave the map even before walls exist.

### 5.2 PlayerAvatar body (when §8 PLAYER-AVATAR-PREFAB is resolved)

Numbers below are copied verbatim from the existing (currently orphaned)
`player_avatar.tscn`, chosen by whoever authored it for a 48px sprite over a
64px diamond:

| Node | Type | Shape / value | Why |
|---|---|---|---|
| root | CharacterBody2D | `motion_mode = MOTION_MODE_FLOATING` (top-down), layer `DYNAMIC_BODY`, mask = mask([TERRAIN_SOLID, PROPS_SOLID, WATER_BLOCKER]) | top-down iso walking treats slopes as flat |
| CollisionShape2D | CapsuleShape2D | radius 7, height 28, position `(0, -14)` | thin capsule inside a 64×32 diamond without poking into neighbor rows |

The capsule extends upward from the feet anchor because visuals are
bottom-anchored; keeping origin-at-feet preserves `map_to_local` positioning.

### 5.3 Zone rectangles (Area2D children under InteractablesRoot)

| Prefab | Shape | Anchor rule | Behavior contract |
|---|---|---|---|
| SleepZone    | RectangleShape2D 128 × 64 covering bed/door tiles | center = door tile's `map_to_local` | sets `is_player_in_zone`; `interact` while inside emits `sleep_initiated` (script exists today) |
| TravelZone   | RectangleShape2D 96 × 48 | straddles an exit edge, fully outside spawn cell | emits location token consumed via main_controller.travel_to registry path |
| BinTrigger   | CircleShape2D r=20 | in front of shipping-bin prop | fires signal `bin_interacted`; UI decision belongs to frontend lane |

Zones get `collision_layer = SCENE_TRANSITION or INTERACTABLE`,
`collision_mask = DYNAMIC_BODY` only, monitoring ON with `monitorable=false`.

## 6. Prefab hierarchies and contracts

```
PlayerAvatar (target tree — consolidation path governed by §8 PLAYER-AVATAR-PREFAB)
├─ Sprite2D           : ProceduralCharacterArt.build_silhouette_texture(PLAYER_COLOR, 48),
│                       centered=false (feet anchor) — current script-built contract kept
├─ Camera2D           : follow enabled, zoom (2,2)  [governed by §8 CAMERA-FOLLOW]
└─ CollisionShape2D   : §5.2 capsule exactly

NPCController
  today: pure Node2D built in code (render-only v1 — deliberate scope cut).
  stays on DynamicLayer; gains body/layer only when §4 wiring begins.
  └─ Sprite2D          : name-hashed tint silhouette (never matches PLAYER_COLOR band)

SleepZone.tscn        : root Node2D + sleep_zone.gd (exists)
├─ Area2D             : §5.3 layer/mask  ← MISSING today (§8 SLEEPZONE-WIRING)
│  └─ CollisionShape2D: 128 × 64 rect; hooks _on_body_entered/exited already in script

TravelZone.tscn       : NEW prefab proposed by this spec
├─ Area2D             : SCENE_TRANSITION
│  └─ CollisionShape2D: 96 × 48 rect
└─ @export var destination_location: String  ← main_controller.LOCATION_SCENE_PATHS key

ShippingBinProp       : NEW; FarmScene first (Ranch staging is future content)
├─ StaticBody2D       : PROPS_SOLID circle r≈14 walk-around blocker
│  └─ CollisionShape2D
├─ Sprite2D           : Kenney farm prop (CC0-verified pack lives in assets/)
└─ InteractionArea    : Area2D circle r=20 emitting `bin_interacted`

ForageNode instance   : root Node2D registered with ForagingManager; renders its state
                        color reactively like FarmScene does plots — no polling.
```

Signal-contract rules (existing repo conventions, now normative):

1. UI opened BY world interactions loads via
   `load("res://scenes/ui/<X>.tscn").instantiate()`, joins as a named child,
   exits through its own `closed` signal (ShopOverlay precedent; free-not-
   queue_free when same-frame re-toggle matters).
2. Cross-scene navigation never instantiates world scenes directly from world
   code — only `main_controller.travel_to(location)` performs the free/add
   swap (it also owns camera-position cache + SleepZone lifecycle).
3. Actors report via signals; scenes mutate game state exclusively through
   manager public methods (`plant/water/harvest/gather...`).

## 7. Per-scene instantiation sheets

All four scenes share §3's stack; tables list only deltas. Verified facts
first (const names cited), proposals marked **[P]**.

| Scene | Playable grid | State vocabulary | Roster (NPCRoster home scene) | Avatar spawn |
|---|---|---|---|---|
| FarmScene   | 8 × 8 | EMPTY/PLANTED/WATERED/READY/WITHERED colors | villager set for "Farm" | center cell (GRID_WIDTH/2, GRID_HEIGHT/2) |
| RanchScene  | 5 × 4 pens | EMPTY/UNFED/FED/READY | Sana ("Ranch") | same-center rule |
| ForageScene | 8 × 8 | available/cooldown states via ForagingManager | Marcus ("Forage") | same-center rule |
| MineScene   | rock/floor lattice + LADDER exit | ROCK/FLOOR/LADDER | Colton, Tobias ("Mine") | floor cell near ladder |

Per-scene planned additions (**[P]** unless noted):

- Farm: ShippingBinProp near grid south edge; SleepZone at farmhouse corner;
  TravelZone east edge → town token when ORCH-008 defines it.
- Ranch: pen props already render; add TravelZone west edge; feeder interact
  stays click-driven.
- Mine: ladder cell doubles as `TravelZone -> "Farm"`-class exit; tile solids
  on every ROCK ring first physics consumer of §5.1.
- Forage: border trees as DecorLayer sprites; no solid shapes v1.

New-map checklists for ORCH-008 SeaCoast/Mountain: same stack, WATER_BLOCKER
shapes on all coast water rows, TravelZones registered in LOCATION_SCENE_PATHS
in the same PR that adds the .tscn (registry is the single travel authority).

## 8. Defect register / integration debts found while auditing

| ID | Finding | Evidence | Owner lane |
|---|---|---|---|
| PLAYER-AVATAR-PREFAB | player_avatar.tscn declares CharacterBody2D root but its script extends Node2D → incompatible pair AND scene never instantiated anywhere (all scenes do PlayerAvatar.new()) while merged tests assert CharacterBody2D children exist → 7 failing checks at base commit | tscn vs scripts/world/*.gd `_add_player_avatar()`; test_runner avatar block | frontend |
| CAMERA-FOLLOW | Tests expect Camera2D reparented under avatar; implementation anchors camera to scene root and main_controller caches scene-level positions across travel — behavior contract must be settled before reparenting breaks that cache | main_controller._save_scene_position/_restore_scene_position | frontend+SE |
| SEED-GRANT-DRIFT | Base-commit fails: starter grant counted 23 instead of expected quantity and restore-vs-regrant ledger mismatch (got 9) — smells like double-grant from overlapping merge duplicates in InventoryManager/FarmPlotManager grant paths | failing checks in runner seed block | backend |
| SLEEPZONE-WIRING | SleepZone.tscn carries no Area2D child though its script exposes body hooks; tests toggle `is_player_in_zone` directly | sleep_zone.gd | frontend |
| AUDIO-MISSING-SFX | AudioManager references assets/kenney/interface-sounds/does_not_exist.wav in a negative-path test — fine as intentional failure probe but name it so it stops reading like a broken asset reference | suite stderr | audio lane |
| T0-PARSE-BREAKAGE | Base 5477b79 did not headlessly compile (duplicate get_all_crop_ids, orphaned intro fragments). Fixed byte-exact inside this branch pending PO re-reconcile | import logs this branch | SE (done here) |

## 9. Persistence touchpoints (ties to save-hardening layer)

- Autoload boot order guarantees managers restore BEFORE any world scene
  instantiates (`project.godot [autoload]`; TitleScreen/main_controller call
  load_game() before first travel_to()) — scenes therefore never observe
  half-restored dictionaries by construction.
- Every world scene renders from manager getters reactively after load;
  scenes carry NO serializable state of their own. Any future exception must
  either live behind a manager's to_save_dict()/from_save_dict() or be added
  as a new key inside SaveFile.state with a migration step appended in
  scripts/save/save_migrations.gd — never a parallel storage file.
- main_controller's per-location camera-position cache is currently
  session-memory only. If it ever persists, it becomes one new dictionary
  entry under state (version bump 2→3 with pass-through migration).
- Version discipline for consuming squads: bump CURRENT_SAVE_VERSION,
  append ONE step, extend the migration proof test — payload-rejection
  semantics (future versions refuse cleanly) are already enforced and tested.

## 10. Headless QA hooks for structural PRs

Reuse the established fixture style (`_make_farm_scene()`, queue_free teardown):

1. Layer presence & ordering: named TileMaps/Nodes exist in §3 order.
2. DynamicLayer y_sort flag true; every mobile actor direct child.
3. Camera `is_current()` uniqueness across concurrent scenes.
4. Zone overlap sanity: no Interactable rect covers a spawn cell.
5. Save/load round trip AFTER structural mutation (scene rebuild reads the
   same manager payloads used by hardened pipeline).
6. Boot smoke: full suite + clean headless load of every changed .tscn.

