# JP World Design — Seasonal Palettes, Lighting Profiles, Ambient FX

Art direction for the Satoyama countryside re-skin. Complements
`seasonal-palette-spec.md` (procedural tint contract) with the illustrated
16-bit pass (`assets/16bit/`, JRL Option B "High-Bit Kominka Crisp",
sel-out `#4A3320`). All colors are hex RGB; Godot `Color` = hex/255 per channel.

Targets: PC + mobile. Nostalgic, peaceful, nature-first. Warm pixel art,
soft natural light, no harsh saturation spikes.

---

## 1. Seasonal Palettes

Each season lists: ground/grass, foliage accent, water, sky/overlay wash,
UI accent, and the "signature read" (the one color a screenshot should be
recognizable by).

### Spring — 春 (Sakura & mist)
| Slot | Hex | Notes |
|---|---|---|
| Grass base | `#7BC45A` | fresh young green |
| Grass shadow | `#5A9A3A` | |
| Foliage accent | `#F8C8D8` | sakura petal pink |
| Foliage deep | `#F0A0B8` | petal shade |
| Water | `#8AB8D9` | snowmelt, high clarity |
| Mist wash | `#E8E4F0` @ 12% | morning haze overlay |
| UI accent | `#E87898` | sakura center |
| **Signature** | **`#F8C8D8`** | petals over green |

### Summer — 夏 (Lush & golden hour)
| Slot | Hex | Notes |
|---|---|---|
| Grass base | `#5A9A3A` | saturated mid green |
| Grass shadow | `#3A6B2A` | deep shade under canopy |
| Sky wash | `#3A6EA5` → `#5A8EC5` | deep blue, high sun |
| Golden hour | `#F0B860` | 17:00–19:00 warm wash |
| Dusk accent | `#D9E878` | firefly glow (emissive points) |
| Water | `#3A6EA5` | deep river blue |
| UI accent | `#F0D860` | |
| **Signature** | **`#3A6B2A` + `#D9E878`** | lush dark + fireflies |

### Autumn — 秋 (Momiji & twilight)
| Slot | Hex | Notes |
|---|---|---|
| Grass base | `#9A8A4A` | drying gold-green |
| Momiji red | `#D95A3A` | maple |
| Momiji deep | `#B03828` | maple shade |
| Ginkgo gold | `#F0D860` | ginkgo fan |
| Twilight wash | `#7A5A8A` @ 15% | early dusk violet |
| Water | `#5A7A9A` | steel blue, low light |
| UI accent | `#D95A3A` | |
| **Signature** | **`#D95A3A` / `#F0D860`** | red maple + gold ginkgo |

### Winter — 冬 (Snow & kotatsu)
| Slot | Hex | Notes |
|---|---|---|
| Snow ground | `#E8F0F8` | soft white, never pure #FFF |
| Snow shadow | `#C0D0E8` | blue shadow |
| Slate sky | `#8A98A8` | muted overcast |
| Indoor warm | `#F0B860` | kotatsu / irori glow (point lights) |
| Bare branch | `#6B5A48` | |
| UI accent | `#C0D0E8` | |
| **Signature** | **`#E8F0F8` + `#F0B860`** | cold outside, warm inside |

---

## 2. Lighting Profiles (CanvasModulate, 4 daily checkpoints)

Drop-in colors for a Godot 4 `CanvasModulate` (or the existing
`DayNightOverlay` ColorRect in `scripts/world/day_night_overlay.gd` — keep
one system, CanvasModulate preferred so `Light2D` lanterns multiply correctly).
Lerp between checkpoints over in-game time; curve = smoothstep.

| Checkpoint | Time | Hex | Alpha/energy | Mood |
|---|---|---|---|---|
| **Dawn** | 05:30–07:00 | `#FFD9B0` | 1.0 | warm amber mist, long soft light from east, birdsong |
| **Noon** | 11:00–14:00 | `#FFFFFF` | 1.0 | neutral full sunlight, maximum saturation read |
| **Sunset** | 17:00–18:30 | `#FF9E64` | 1.0 | golden-vermilion, **long shadows** (see note) |
| **Night** | 20:00–04:30 | `#2A2E4A` | 1.0 | quiet indigo rural dark; no streetlights — only lantern/window `PointLight2D`s (`#F0B860`, energy 0.6, texture_scale 3) |

**Long-shadow note (Sunset):** true cast shadows are expensive on mobile.
Fake it: for props on Layer 2, stamp a 1:2-stretched, 50%-alpha, `#3A2A3A`
silhouette sprite skewed 60° west, drawn on the ground layer. Pre-bake per
prop; toggle visibility only during the Sunset window.

**Transitions:** dawn→noon 90 min, noon→sunset continuous, sunset→night
45 min (fastest — countryside dark falls quickly), night→dawn 60 min.

---

## 3. Atmospheric Effects (mobile-friendly)

All effects use **CPUParticles2D** (cheaper on mobile GPUs, deterministic),
max 40 particles each, one shared 16×16 white-dot/petal atlas; modulate per
effect. Toggle with season + weather; pause when off-screen
(`visibility_rect` culled).

### 3.1 Sakura petals (Spring, breezy days)
- amount 24, lifetime 6s, gravity (0, 6), velocity (12±6, 4±2)
- `petal` texture (2 frames: `#F8C8D8`, `#F0A0B8`), spin ±45°/s, sway via
  `damping 0.5` + horizontal sine (anim curve on x-offset, amp 8px)
- emission: top-of-screen band, follows camera

### 3.2 Summer dust motes / fireflies
- **Motes** (day, interiors/engawa): 12 particles, drift (−2,−4)/s,
  `#F0E0B0` @ 25% alpha, scale 1px, lifetime 8s
- **Fireflies** (dusk/night, near water Layer 0): 18 particles,
  `#D9E878`, blink via alpha curve (0→1→0, period ~1.4s, random phase),
  wander: orbit offset ±16px slow; emissive look = additive blend material

### 3.3 Autumn leaf drop
- 16 particles, textures: momiji `#D95A3A` + ginkgo `#F0D860` (2 frames)
- gravity (0, 10), initial velocity (6±4, 0), spin ±90°/s,
  horizontal sway amp 12px slower than sakura (heavier read)
- spawn only under canopy props (Layer 3 anchor points)

### 3.4 Gentle rainfall (all seasons, weather=rain)
- 40 particles, velocity (8, 220) px/s, scale 1×3 streak `#C0D0E8` @ 60%,
  lifetime 0.4s, emission rect = screen top edge
- + occasional ripple ring on water tiles (2-frame animated sprite, 30%)
- Winter variant: snow — velocity (±6, 22), spin gentle, flake `#E8F0F8`

### Budget rules
≤4 simultaneous emitters, ≤60 live particles total on screen, no
`trail` sub-emitters, no per-frame texture swaps beyond 2-frame flipbooks.
All emitters pause when `get_tree().paused` or off-screen >1.5 screens.
