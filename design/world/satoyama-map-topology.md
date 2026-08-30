# Satoyama Village — Map Topology & TileMap Layering

World structure for the rural Japanese village. Grid: 64×32 iso diamond
(`design/art/isometric-grid-spec.md`), coordinates below in tile units
(col,row), origin at village center plaza. World target size: 96×96 tiles.

Design intent: **Satoyama** — the lived-in border between village and
mountain. Narrow winding stone paths, water everywhere (paddies, canals,
river), and no straight road longer than 8 tiles.

---

## 1. Zonal Layout (blueprint)

```
                MOUNTAIN RIDGE (dense cedar backdrop, Layer 3)
   ┌──────────────────────────────────────────────────────────┐
   │  [E] RURAL STATION        [D] MOUNTAIN RIVER             │ N
   │   one-track platform       stream + wooden bridges       │
   │   (66,8)-(78,16)          (40,4)-(58,20)                 │
   │        │ canal                 │ waterfall pool (48,18)  │
   │        ▼                       ▼                         │
   │  [C] SHINTO SHRINE & SACRED GROVE      stone steps       │
   │   torii (30,26), honden (28,14), grove (20,10)-(36,30)   │
   │        │ sando path (lanterns)                           │
   │        ▼                                                 │
   │  [B] VILLAGE MAIN STREET  (20,36)-(48,52)                │
   │   ramen shop (24,38), corner store (34,42),              │
   │   2 vending machines (38,40), notice board, plaza (30,46)│
   │        │ winding stone path  ←——— Jizo statues every ~8t │
   │        ▼                                                 │
   │  [F] RICE PADDY TERRACES (tanbo) (8,56)-(44,78)          │
   │   3 terraced levels, canal strip along west edge         │
   │        │                                                 │
   │        ▼                                                 │
   │  [A] OLD KOMINKA FARMSTEAD (player home) (60,58)-(84,80) │
   │   see kominka-homestead-blueprint.md                     │
   └──────────────────────────────────────────────────────────┘
   S
```

| Zone | Bounds (col,row) | Character |
|---|---|---|
| A Kominka Farmstead | (60,58)–(84,80) | player home, engawa, fields, Jizo shrine |
| B Main Street | (20,36)–(48,52) | ramen shop, corner store, vending machines |
| C Shrine & Grove | (20,10)–(36,30) | torii, honden, sacred cedar ring, sando |
| D Mountain River | (40,4)–(58,20) | fishing spots, 2 wooden bridges, pool |
| E Station | (66,8)–(78,16) | one-line rural platform, timetable board |
| F Paddy Terraces | (8,56)–(44,78) | community paddies, 3 terrace steps |

## 2. Connective tissue

- **Stone paths** (`path`/`dirt` recolor, mossy edge speckle `#5A9A3A` @6%):
  max width 2 tiles, must bend at least every 6 tiles. No diagonal paving.
- **Canals**: animated `water_0/1` strips flanking paths between F→B→D;
  crossed by **wooden bridges** (2×1, `wood_floor` recolor + rail posts).
- **Stone walls** (mossy `rock` recolor): terrace retaining edges in F,
  property line around A, shrine boundary in C.
- **Bamboo fences** (`fence_h/v` recolor `#C9B896`/`#A89868`): field
  borders in A/F, path guides near shrine sando.
- **Scenic beats on the A→B walk** (the daily commute, ~35 tiles):
  home gate (66,72) → paddy overlook bench (52,68) → **Jizo statue w/ red
  bib** (44,62) → wooden bridge over canal (40,56) → **roadside vending
  machine + phone pole** (38,44) → plaza (30,46). Walking time ≈ 45 s.
- **Station approach**: gravel path from B, passes a small waiting-shed
  Jizo (58,20); train is a scheduled ambiance event (2×/day, audio + smoke
  `smoke_0..2`, no rideable content in v1).

## 3. Godot 4 TileMap layering spec

One `TileMap` per layer (or Godot 4 built-in layers on a single TileMap —
either; names below are the contract):

| Layer | Name | Content | Collision | Y-sort |
|---|---|---|---|---|
| 0 | `Ground` | dirt/grass/water base tiles, canals, river bed | water tiles have collision | no |
| 1 | `Soil` | tillable soil & rice paddies (state tiles: dry/tilled/watered/paddy-flooded) | none | no |
| 2 | `Structures` | kominka, shrine honden, shops, fences, stone walls, bridges, vending machines, Jizo | full body collision | **yes** (YSort with entities) |
| 3 | `Canopy` | overhanging tree crowns, cedar grove tops, torii top beam | none | no (always above) |

Notes:
- Layer 2 must live in the shared `DynamicLayer` YSort with player/NPCs
  (style-guide "Layer Stack") so walking behind the kominka reads correctly.
- Bridges: floor part on Layer 0 overlay, rails on Layer 2.
- Paddy water (Layer 1) is a *state tile*: flooded paddy = `water` +
  mud bed; drained = `soil_dry_until`. Swap via `set_cell`, no new layers.
- Canopy alpha dips to 60% when player is beneath (single shader-less
  modulate tween), so Layer 3 never hides gameplay.

## 4. Spatial flow rules (checklist for future edits)

1. Any path >8 tiles straight must bend or gain a prop beat (lantern,
   Jizo, bench, vending machine).
2. Water is never more than ~15 tiles away: canal, paddy, river, or well.
3. Every zone transition is gated by a *threshold prop*: torii (C),
   bridge (D/F), station stairs (E), bamboo gate (A).
4. Sightline rule: from the plaza you can see exactly one "far" landmark
   (shrine torii top above roofs) — everything else reveals around bends.
