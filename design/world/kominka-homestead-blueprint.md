# Kominka Homestead — Starting Farm Layout (Level Design)

Player's starting property: an old family farmhouse (kominka) and grounds,
**cozy but slightly overgrown** — restoration is the early game. Mobile-first
16:9: the whole yard reads in ~2 screenfuls at default zoom; the engawa rest
spot is visible from the spawn door on frame 1.

Grid: 64×32 iso diamonds, coordinates in (col,row) tiles. Homestead bounds:
**(60,58)–(84,80)** on the world map (Zone A of `satoyama-map-topology.md`).

## 1. Blockout map (24×22 tiles; `.` grass)

```
        60        65        70        75        80        84
   58   . . . . . . . . . . . . . . . . . . . . . . . . .
   59   . . B B B B B B B B B . . . . . . T T T . . . .   B = bamboo fence
   60   . B K K K K K K K K B . . W W . . T T T . . . .   K = kominka walls
   61   . B K K K K K K K K B . . W W . . . . . . . . .   W = woodpile/weeds
   62   . B K K K K D K K K B . . . . . P . . . . . . .   D = door (shoji)
   63   . B E E E E E E E E B . . L . . . . . . . . . .   E = engawa veranda
   64   . B . . . . . . . . B . . . . . . . . . . . . .   L = stone lantern
   65   . B G . . . . . . . B B B B B B . . . . . . . .   G = bamboo gate (entry)
   66   . . . . p p p . . . . . . . . . . J . . . . . .   p = stone path
   67   . . F F . . . . . . . . . . . . . . . . . . . .   J = family Jizo shrine
   68   . . F F F F F . . . R R R R . . . . . . . . . .   F = dry crop field
   69   . . F F F F F . . . R R R R . . . . . . . . . .   R = rice paddy (tanbo)
   70   . . F F F F F . . . R R R R . . . ~ ~ . . . . .   ~ = canal water
   71   . . . . . . . . . . R R R R . . . ~ ~ . . . . .
   72   . . . . . . . . . . . . . . . . . ~ ~ . . . . .
   73   . . O . . . . . . . . . . . . . . ~ ~ . . . . .   O = old well pump
   74   . . . . . . . . . . . . . . . . . . . . . . . .
   75   . . . T T . . . . . . . . . . . . . . . . . . .   T = trees (Layer 3)
```

State at game start: dry field F is half `soil_dry_until`, half weeds;
paddy R is **drained & cracked** (restoration quest: re-flood via canal
gate at (75,70)); weeds W at (71–72,60–61); woodpile beside them.

## 2. Key placements

| Element | Tiles | Asset / note |
|---|---|---|
| Kominka house | (61–68, 60–62) | `farmhouse.png` + seasonal variants; kawara roof; Layer 2, YSort |
| Shoji door (entrance) | (65,62) | slide-open anim + step sound |
| Engawa veranda | (61–68,63) | `wood_floor` recolor; player can sit (`sit` anim row) |
| Bamboo gate | (61,65) | threshold prop, creaks |
| Dry crop field | (62–66,67–70) | Layer 1 soil tiles; 4-stage crops |
| Rice paddy (tanbo) | (71–74,68–71) | Layer 1 paddy state tiles; flooded = water + mud bed |
| Canal strip | (76–77,70–72) | Layer 0 animated water; feeds paddy via gate (75,70) |
| Old water well pump | (63,73) | hand-pump; `well.png` Japanese recolor |
| Woodpile | (71–72,61) | prop; winter fuel flavor |
| Stone lantern | (72,63) | dusk PointLight2D `#F0B860` |
| Family Jizo shrine | (73,66) | `jizo_shrine.png`, red bib, offering shelf |
| Trees (overgrown) | (78–80,59–60), (63–64,75) | Layer 3 canopy, alpha-dip rule |

## 3. Interaction triggers (Godot `Area2D` coordinates)

Anchors in world tiles; each Area2D = `CollisionShape2D` covering the rect,
`interact_type` consumed by the interaction manager.

| id | Rect (col,row)→(col,row) | Type | Effect |
|---|---|---|---|
| `home_door` | (65,62)→(65,62) | `door` | enter interior scene (fade) |
| `engawa_rest` | (62,63)→(67,63) | `rest` | sit anim + stamina regen ×2, time-lapse optional |
| `well_water` | (63,73)→(63,73) | `water_source` | refill bamboo watering can |
| `jizo_offering` | (73,66)→(73,66) | `offering` | offer item (dango/flower) → small friendship + luck buff |
| `canal_gate` | (75,70)→(75,70) | `toggle_water` | flood/drain paddy (quest-gated until repaired) |
| `field_dry` | (62,67)→(66,70) | `farm_zone` | till/plant/water/harvest routing |
| `paddy` | (71,68)→(74,71) | `paddy_zone` | rice planting loop (flooded only) |
| `woodpile` | (71,61)→(72,61) | `forage` | 1–2 firewood/day, winter warmth item |
| `gate_exit` | (61,65)→(61,65) | `travel` | path toward village center (Zone B) |

## 4. Restoration beats (first-week onboarding)

1. **Day 1:** clear weeds W (scythe tutorial), door + engawa usable.
2. **Day 2–3:** till 6 dry-field tiles, plant daikon (fast 3-day crop).
3. **Day 4:** Chiyo visits → unlocks canal_gate repair mini-quest
   (3 bamboo + 2 stone) → flood paddy → rice planting unlocked.
4. **Day 5+:** Jizo offering tutorial (any flower → next-day luck buff).
