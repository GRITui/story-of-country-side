# Self-Sufficiency Spec — Salt / Miso / Tofu (Issue #187)

Source: issue #187 ([S] Substitute — Japanese self-sufficiency). Status:
**design-only** — no scripts/scenes touched on this branch; engineering
targets below reference the issue's acceptance criteria (`SaltShed.gd`,
`MisoKura.gd`, `FermentationProcess`) as follow-up work.

Design intent: making your own staples is about **convenience, gifts, and
immersion** — never a money printer. Selling crafted staples ships at
break-even or a loss vs. inputs; their value is realized by *using* them
(cooking, gifting, shrine offerings) or by avoiding Hanna's store markup.

## 1. New items

| id | kind | source | seasons | sell | store buy | art |
|---|---|---|---|---|---|---|
| `soybean` | crop (`CropDefinition`) | farm, 10 days, one-harvest | summer, autumn | 40 | seed 15 | icon ✅ · stages follow-up |
| `seaweed` | forage (`ForageableDefinition`) | river/coast kombu nodes, respawn 3d | spring–autumn | 15 | — | icon ✅ · node sprite follow-up |
| `salt` | artisan | salt shed (3-day evaporation) | — | 40 | 100 | ✅ |
| `koji` | artisan (intermediate) | kura koji-muro (2-day) | — | 15 | 60 | ✅ |
| `miso` | artisan (aged) | tamaru barrel, 28–63 day aging | — | 80 | 200 (young only) | ✅ |
| `nigari` | artisan (byproduct) | salt shed bittern | — | 20 | — | ✅ |
| `soy_milk` | artisan (intermediate) | tofu press, mid-chain | — | 25 | — | follow-up |
| `tofu` | artisan (fresh) | tofu press, same-day craft | — | 60 | 100 | ✅ |

Quality: `miso` uses the existing `PriceRegistry` quality multiplier
(normal 1.0 / silver 1.25 / gold 1.5 → 80/100/120) driven by harvest
timing (§3). Other items are quality-less, matching forage/artisan norms.
Price band placement vs. `scripts/economy/price_registry.gd`: forage 6–20,
crop 35–140, artisan 40–80 — all base prices land inside an existing band;
only *quality-aged* miso exceeds the artisan band, the same way gold melon
exceeds the crop band.

## 2. Salt — Salt Shed (塩小屋)

Building: `salt_shed` (craftable prop, follow-up art; issue AC:
`SaltShed.gd` autoload owns the timer). One batch at a time.

| step | action | duration |
|---|---|---|
| 1. Load | 5× `seaweed` + 2× `wood` (boil fuel) | instant, morning |
| 2. Boil-down | seaweed → concentrated brine | 2 in-game hours, same day |
| 3. Evaporate | brine on drying beds | **3 clear days** (base) |
| 4. Harvest | rake crystals + draw off bittern | instant |

Season/weather modifiers (issue AC: season-specific yield modifiers):

| condition | effect |
|---|---|
| summer sun | −1 day (min 2) |
| winter | +1 day (4) |
| rainy day | day doesn't count (progress pauses) |
| left unharvested | spoils 2 days after ready (summer: 1 day) → batch lost, recover 1× `nigari` |

Output: **3× `salt` + 1× `nigari`** (nigari = bittern drawn off after
crystallization — the tofu coagulant; this byproduct is what makes the
salt shed the root of both other chains).

Margin: inputs 5×15 + 2×4 = 83 g → outputs 3×40 + 20 = 140 g
(≈ +19 g/day uplift). Bounded by seaweed forage throughput
(respawn_days=3), not by player gold — see §5.

## 3. Miso — Kura (味噌蔵) + Tamaru barrel

Two chained processes. **The months-long aging is the design**: one barrel
is a season-scale commitment; stagger 2–3 barrels for steady supply.

### 3a. Koji (麹) — koji-muro (warm room)

| step | action | duration |
|---|---|---|
| 1. Steam | 4× `rice` + 1 koji-kin starter | 1 in-game hour |
| 2. Inoculate & incubate | tray into the muro | **2 days** (winter: 3) |

Output: **4× `koji`**. Starter sourcing: first koji-kin packet is **gifted
by Chiyo on her day-4 visit** (tutorializes the chain, ties into
`design/world/kominka-homestead-blueprint.md`); afterwards reserve 1 koji
as the next batch's starter, or buy ready `koji` at Hanna's for 60.

### 3b. Miso — tamaru barrel (樽)

| step | action | duration |
|---|---|---|
| 1. Steam & mash | 10× `soybean` | 1 in-game hour |
| 2. Pack | + 4× `koji` + 2× `salt`, pack barrel, seal | instant |
| 3. Age | `FermentationProcess(start_date, min_days=28, max_days=63)` | **28–63 days** |
| 4. Open | harvest window determines quality | instant |

Quality by harvest day (maps to existing quality multiplier):

| harvest day | quality | sell/each |
|---|---|---|
| 28–41 | normal (shiro/young) | 80 |
| 42–55 | silver | 100 |
| 56–63 | gold (aka/aged) | 120 |
| >63 | spoiled (summer-started batches: >49) | 0 |

Season modifiers: batches **started in winter** ferment slower
(min_days 28→35); **summer** cellars run hot — spoil window shortens
(63→49). `fermentation_complete` fires at `current_date >= start_date +
min_days` (issue AC).

Output: **8× `miso`** per barrel.

Margin (normal): inputs 10×40 + 4×15 + 2×40 = 540 g → 8×80 = 640 g
(≈ +3.6 g/day). Gold-aged: 960 g (≈ +7.5 g/day). Deliberately weaker than
field crops — miso's return is in cooking/gifts (§6), not the shipping bin.

## 4. Tofu — Tofu Press (豆腐型), daily craft

Tool-station: `tofu_press` (kitchen/processing prop, follow-up art).
Same-day loop — the "daily" counterpart to miso's "seasonal".

| step | action | duration |
|---|---|---|
| 1. Soak & grind | 3× `soybean` | 1 in-game hour |
| 2. Simmer & strain | → 1× `soy_milk` (inventory item, drinkable +10 stamina) | 1 hour |
| 3. Coagulate | + 1× `nigari` | instant |
| 4. Press | → collect | 2 hours |

Output: **2× `tofu`** (~4 in-game hours start to finish).

Margin: inputs 3×40 + 20 = 140 g → 2×60 = 120 g ship value (**−20 g**).
Buying the same 2 tofu costs 200 g. This is the spec's core principle in
miniature: *shipping tofu loses money; making tofu saves money*.

## 5. Economy — bands, margins, exploit risks

Prices sit in `PriceRegistry` bands (forage 6–20, crop 35–140,
artisan 40–80, cooked 50–130). Store prices follow a ≥2× convenience tax
over ship value so **buy → craft → ship loops are always negative**.

| chain | cycle | conversion uplift | effective cap |
|---|---|---|---|
| salt | 3 days | ≈ +19 g/day | seaweed nodes × respawn 3d |
| miso | 28–56 days | ≈ +3.6–7.5 g/day | barrel slots, season length |
| tofu | same day | −20 g/batch (ship) / +60 g (vs. store) | nigari supply (1/salt batch) |

Exploit risks designed around:

1. **Salt farming** — margin is bounded by forage throughput, not gold:
   seaweed nodes are finite with 3-day respawn. Do not add a seaweed seed.
2. **Intermediate flipping** — `koji` (15) and `soy_milk` (25) ship *below*
   input value so half-finished chains are never profitable.
3. **Idle-free batches** — salt consumes `wood` fuel; unharvested batches
   spoil. No free passive generation.
4. **Set-and-forget miso** — spoilage past `max_days` (and summer's
   shorter window) forces calendar engagement; gold tier is a reward for
   *timing*, not just waiting.
5. **Store arbitrage** — store buy ≥2× ship value on every staple;
   intermediates (`nigari`, `soy_milk`) are never sold in store.

## 6. Integration notes

- **Cooking** (`scripts/cooking/cooking_manager.gd`, `CookingRecipe`):
  new kitchen recipes, gated as usual on
  `InfrastructureManager.is_cooking_unlocked()` —
  `rice_ball`: 2× `rice` + 1× `salt` → 35 stamina ·
  `miso_soup`: 1× `miso` + 1× `tofu` + 1× `seaweed` → 50 stamina ·
  `tofu_stew`: 1× `tofu` + 1× `daikon` → 40 stamina.
  Per issue AC, new `ItemDefinition`s get `is_cooking_ingredient=true` and
  `cooking_quality_multiplier` so gold miso yields gold miso_soup.
- **Gifts** (`scripts/social/gift_preferences/*.tres`,
  `RelationshipManager.GIFT_PREFERENCE_PATHS`): Chiyo **loves** `miso`
  (her late husband brewed; she gifts the first koji-kin — closes the
  loop), likes `salt`; Elder Taro likes `salt`. `chiyo.tres` doesn't exist
  yet — follow-up with her NPC roster entry.
- **Shrine offerings** — hook note only: design/189 (parallel) is speccing
  offering sets; reserve set tag `shrine_offering:pantry_staples` =
  {`rice`, `salt`, `miso`}. **No dependency on 189** — this spec ships
  without it; 189 can consume the tag when it lands.
- **Engineering targets** (issue AC, not this branch): `SaltShed.gd` +
  `MisoKura.gd` autoloads owning timers/season modifiers,
  `FermentationProcess(start_date, min_days, max_days)` with
  `fermentation_complete`, `PriceRegistry` registration of the 8 ids.

## 7. Art assets (this branch)

`assets/16bit/items/icon_{salt,miso,tofu,koji,soybean,seaweed,nigari}.png`
+ combined `self_sufficiency_sheet.png` (112×16), generated by
`assets/16bit/generator/gen_jp_self_sufficiency.py` (deterministic Pillow,
sel-out `#4A3320`, transparent bg).

Follow-up art: `soy_milk` icon; `soybean` growth stages 0–3; `seaweed`
forage-node world sprite; building props (`salt_shed`, `tamaru` barrel /
kura façade, `tofu_press`).

## 8. Open questions

1. `PriceRegistry` still lists pre-reskin Western crops (parsnip…); the
   JRL crop migration (incl. a canonical `rice` price, assumed **50** in
   koji margin math) is tracked under the JRL rework list — confirm owner.
2. Barrel/shed slot counts (start with 1 shed, 2 tamaru?) — PO call.
3. Does Hanna's store stock `tofu`/`salt` from day 1, or only after the
   player crafts each once (discovery gate)?
