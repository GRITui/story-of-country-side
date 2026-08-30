# Season × Year Content Audit — Late-Game & Winter Depth (Issue #182)

Source: Content lane, M7 (parent #179; Decision A open-ended + optional
year-3 evaluation). Every claim below is grounded in the registered
content tables in `scripts/` and the JRL art inventory in
`design/art/asset-manifest.md` — not in intent docs. Where the design
target (post-JRL pivot) and the data layer disagree, the **data layer
wins** and the disagreement is called out as a finding.

Calendar constants used throughout: `TimeManager` 4 seasons × **30 days**
(`DAYS_PER_SEASON`, `scripts/autoload/time_manager.gd:13`), day 06:00–24:00.
Year-3 evaluation fires **Year 3, Spring, day 1**
(`scripts/autoload/community_goal_manager.gd:167`).

Status legend: **Implemented** = works end-to-end today · **Stubbed** =
registered/scaffolded but non-functional or placeholder · **Absent** =
nothing registered.

---

## 0. Headline findings

1. **The JRL pivot is art-only so far.** Canonical crops (rice, daikon,
   nasu, edamame, sweet_potato, watermelon) have full sprite sets
   (`assets/16bit/crops/`, `assets/16bit/items/icon_*.png`) but **zero
   data registrations** — `FarmPlotManager._register_default_content()`
   (`scripts/autoload/farm_plot_manager.gd:68-81`) still registers the
   Western placeholder roster (parsnip…frost_kale) plus four
   transitional crops. PriceRegistry, ShopManager, CookingManager and
   CommunityGoalManager all reference the pre-pivot ids.
2. **Winter's real problem is distribution, not just volume.** Winter
   has the *most* festivals of any season (3) but all land on days
   21–28, leaving days 1–14 with no calendar content, one plantable
   crop (frost_kale), and zero winter-cookable recipes.
3. **Year 2+ adds nothing.** No content is year-gated anywhere; the
   only year-aware code in the repo is the one-shot evaluation at Y3
   Spring 1. After mid-Year-2 (bundles + automation done) the game is
   pure repetition.
4. **Two money multipliers are broken year-round**, not just in winter:
   2 of 3 artisan machines consume item ids (`fruit`, `vegetable`) that
   no system produces, and the skill XP pipe (`SkillManager.add_xp`)
   does not exist, so the #116 perk curve — including the Farming-5
   +10% sell hook in PriceRegistry — can never fire.
5. Acceptance criterion "no season with < 3 distinct money paths by end
   of year 1" **passes on paper (5 paths every season) but is hollow in
   winter**: the farming path is a single crop at ~57% of the summer
   gold/day ceiling, and the artisan path is 2/3 dead.

---

## 1. What is actually registered today (per system)

### 1.1 Crops — `scripts/autoload/farm_plot_manager.gd:70-81`

11 crops. G/day = `(base_sell − seed) / days_to_grow`, single-harvest,
normal quality, using `CropDefinition.seed_price`; regrowables amortized
over one 30-day season. Quality roll is 10% gold / 20% silver / 70%
normal (EV +10%, `farm_plot_manager.gd:21-27`).

| crop | seasons | days | regrow | sell | seed | xp | G/day | shop seed? |
|---|---|---|---|---|---|---|---|---|
| parsnip | Spring | 4 | — | 35 | 12 | 4 | 5.8 | yes (20G) |
| cauliflower | Spring | 6 | — | 80 | 28 | 8 | 8.7 | yes (40G) |
| turnip | Spring, Fall | 4 | — | 40 | 10 | 5 | 7.5 | **no** |
| radish | Spring, Summer | 5 | — | 55 | 14 | 6 | 8.2 | **no** |
| strawberry | Spring, Summer | 6 | 3 | 30 | 20 | 5 | 8.3 | **no** |
| tomato | Summer | 5 | 3 | 45 | 30 | 6 | 12.5 | yes (25G) |
| melon | Summer | 7 | — | 140 | 45 | 12 | 13.6 | yes (60G) |
| eggplant | Summer, Fall | 7 | — | 90 | 22 | 10 | 9.7 | **no** |
| pumpkin | Fall | 7 | — | 120 | 38 | 12 | 11.7 | yes (55G) |
| corn | Fall | 8 | 4 | 55 | 38 | 6 | 9.7 | yes (30G) |
| frost_kale | Winter | 6 | — | 70 | 24 | 7 | 7.7 | yes (35G) |

Per-season counts: **Spring 5 · Summer 5 · Fall 4 · Winter 1.**

Findings:
- **F-1.1** Canonical JRL crops rice/daikon/edamame/sweet_potato/
  watermelon unregistered; `eggplant` registered under its pre-pivot id
  instead of `nasu`. Art ready (`asset-manifest.md` §JRL pack).
- **F-1.2** turnip/radish/eggplant/strawberry have **no shop seeds**
  (`scripts/autoload/shop_manager.gd:40-47` lists only the 7 originals),
  so 4 of 11 crops are unreachable through the shop UI.
- **F-1.3** Two parallel seed price tables disagree:
  `SeedDefinition.price` (shop, parsnip 20G) vs `CropDefinition.
  seed_price` (`FarmPlotManager.buy_seed`, parsnip 12G).

### 1.2 Forage — `scripts/autoload/foraging_manager.gd:52-62`

| season | items (sell, respawn days) | count |
|---|---|---|
| Spring | wild_berries 8/2, wild_flower 6/2, spring_onion 10/2 (+four_leaf_clover 30/5 all-season rare) | 3+1 |
| Summer | wild_berries 8/2, sweet_pea 9/2 (+clover) | 2+1 |
| Fall | mushroom 12/3, hazelnut 14/3 (+clover) | 2+1 |
| Winter | snow_truffle 20/4, winter_root 16/3 (+clover) | 2+1 |

Per-node G/day is flat across seasons (3–5.3); winter is at parity
here. No JP re-theme (no bamboo shoots / mitsuba / kaki).

### 1.3 Fish — `scripts/autoload/fishing_manager.gd:71-93`

| season | catchable | count | ceiling |
|---|---|---|---|
| Spring | carp, trout, bream, sardine | 4 | trout 40 |
| Summer | carp, tuna, bream, bass, eel (night) | 5 | tuna 100 |
| Fall | carp, trout, salmon, bass, sardine, eel, sturgeon | 7 | sturgeon 150 |
| Winter | carp, tuna, sardine, **squid** (night), **pike**, sturgeon | 6 | sturgeon 150 |

Winter fishing is the **strongest** fishing season by ceiling — the
winter gap is not here.

### 1.4 Ranching — `scripts/autoload/animal_manager.gd:84-88`

5 species, all-season, no seasonal variation: chicken egg 20/day, duck
duck_egg 45/2d, cow milk 30/day, goat goat_milk 55/2d, sheep wool 75/3d.
Winter-stable income; also the only artisan feedstock that works (§1.5).

### 1.5 Artisan & automation — `scripts/autoload/infrastructure_manager.gd:133-142`

| machine | cost | recipe | margin | status |
|---|---|---|---|---|
| keg | 300G + 20 wood | `fruit` → wine (3d) | 15→80 (5.3×) | **Stubbed — `fruit` has no producer** |
| preserves_jar | 250G + 15 stone | `vegetable` → pickle (2d) | 15→50 (3.3×) | **Stubbed — `vegetable` has no producer** |
| mayo_machine | 200G + 10 wood | egg → mayonnaise (1d) | 20→40 (2×) | Implemented |
| sprinkler_system | 2000G + 50 stone | auto-water | — | Implemented |
| auto_feeder | 1800G + 60 wood | auto-feed | — | Implemented |
| collection_hub | 2500G + 60 stone | auto-collect | — | Implemented |

- **F-1.5** `fruit`/`vegetable` are registered in PriceRegistry (15G
  each) but no crop, tree, or forageable yields them — 2/3 of the
  artisan track is dead content in **every** season.
- House tiers: T1 1000G+50 wood (gates cooking), T2 3000G+100 stone.
  Coop T1 800G+40 wood, T2 2000G+80 wood.

### 1.6 Cooking — `scripts/cooking/cooking_manager.gd` (the autoload)

5 recipes, gated on house T1 via `is_cooking_unlocked()`. A dead
duplicate file exists at `scripts/autoload/cooking_manager.gd` (not
autoloaded; different recipe set — remove in a cleanup pass).

| recipe | inputs | season of fresh inputs |
|---|---|---|
| parsnip_soup | parsnip ×3 | Spring |
| cauliflower_stew | cauliflower + parsnip | Spring |
| tomato_soup | tomato ×2 | Summer |
| pumpkin_pie | pumpkin + egg | Fall (egg all-season) |
| fish_stew | trout + mushroom | **Fall only** (trout Sp/F × mushroom F) |

- **F-1.6** **Zero recipes are cookable from in-season winter inputs.**
  The kitchen is a Fall-flavored feature as registered.

### 1.7 Festivals & calendar — `scripts/autoload/festival_manager.gd:22-33`, `scripts/autoload/calendar_manager.gd:14-22`

| season | festivals (day) | birthdays |
|---|---|---|
| Spring | bloomtide_fair 13 (legacy), hanami_picnic 15 | Elena 5, Sana 22 (legacy roster) |
| Summer | sunfield_revel 15 (legacy), hanabi_taikai 20 | Colton 8, Marcus 12 (legacy) |
| Fall | harvest_contest 10, harvest_moon_festival 16 (legacy) | Priya 20 (legacy) |
| Winter | hearthlight_festival 21 (legacy), winter_starlight 24, starlight_veiling 28 (legacy) | Tobias 15 (legacy) |

- Festivals are **Stubbed**: `start_festival()` only freezes time and
  emits a signal; `FestivalMiniGameOverlay` is an explicit placeholder
  (choice screen → pass/fail → end). No festival-specific
  rewards/activities exist; `harvest_contest`'s flavor text promises
  crop-quality judging that nothing implements.
- **F-1.7a** JP and legacy festivals coexist (Winter ×3 in 8 days).
- **F-1.7b** Birthdays cover only the **legacy Western 6**. The
  canonical JP 7 (Toby/Hanna/Cliff/Nina/Cid/Kai/Leo,
  `scripts/constants/npc_constants.gd`) have **no birthdays, and
  Winter's only birthday belongs to a legacy NPC**.

### 1.8 Quests — `scripts/autoload/quest_manager.gd`

Only the 10 infrastructure DELIVER_ITEM quests auto-registered by
`InfrastructureManager` (`infrastructure_manager.gd:144-183`). **Zero
narrative/seasonal quests**: the starter chain (#108) was planned but
`scripts/quests/starter_content.gd` does not exist (its test
`scripts/quests/test_starter_quest.gd` expects quests nothing
registers), and the matsuri questline is a design doc only
(`design/narrative/summer-matsuri-questline.md`, no registrations).

### 1.9 Community goals — `scripts/autoload/community_goal_manager.gd:49-70`

10 bundles, all using pre-pivot item ids. Earliest completion pacing:
pantry/orchard/night_anglers → **Fall Y1** (summer+fall crops, eel);
forager/forager_reserve → **Winter Y1** (snow_truffle, winter_root);
vault → diamond ×3 (mine floor 5+, rare) → the de-facto Y2 grind.
After `all_bundles_completed()` there is **no further goal content**;
the Y3-Spring-1 evaluation is a single one-day beat.

### 1.10 Social — `scripts/autoload/relationship_manager.gd:77-134`, `marriage_manager.gd:55`, `social_manager.gd`

- Heart-event dialogue (levels 2/4/6/8/10): legacy 6 complete; canonical
  7 = Toby/Hanna/Cliff complete, **Nina 2–4 only, Cid/Kai/Leo level 2
  only** (stubbed).
- Two parallel marriage systems: `MarriageManager.MARRIAGEABLE_NPCS` =
  legacy 6 (stale, canonical 7 not marriageable there) vs
  `SocialManager` pendant-gated marriage with no roster. **F-1.10.**
- Tea-menu stub (`green_tea`/`dango`) lives oddly in
  `ShippingBinManager` — Nina's tea house has no scene content.

---

## 2. Activity matrix — season × year

Cell = content + status. Y2/Y3+ columns are short because **nothing is
year-gated**: the systems column repeats verbatim; only the player's
completion state changes. That repetition *is* the finding.

### Spring (30d)

| activity | Year 1 | Year 2 | Year 3+ |
|---|---|---|---|
| Growable crops | parsnip, cauliflower, turnip*, radish*, strawberry* — Implemented (*no shop seed) | identical | identical |
| Forage | wild_berries, wild_flower, spring_onion — Implemented | identical | identical |
| Fish | carp, trout, bream, sardine — Implemented | identical | identical |
| Festivals/events | bloomtide 13, hanami 15 — Stubbed (signal+placeholder overlay) | identical | **+ evaluation Spring 1 (one day, one-shot)** |
| Quests | 10 infra deliver-quests — Implemented; narrative — Absent | none left if done | none |
| Artisan | keg/preserves_jar Stubbed (dead inputs); mayo Implemented | identical | identical |
| Social | legacy 6 full arcs + birthdays; canonical 7 stubbed arcs, no birthdays | identical | identical |

### Summer (30d)

| activity | Year 1 | Year 2 | Year 3+ |
|---|---|---|---|
| Growable crops | tomato, melon, radish*, strawberry*, eggplant* — Implemented | identical | identical |
| Forage | wild_berries, sweet_pea — Implemented | identical | identical |
| Fish | carp, tuna, bream, bass, eel — Implemented | identical | identical |
| Festivals/events | sunfield 15, hanabi 20 — Stubbed | identical | identical |
| Quests | infra quests (if unfinished); matsuri chain design-doc only — Absent | none | none |
| Artisan | as Spring | identical | identical |
| Social | 2 legacy birthdays (Colton 8, Marcus 12) | identical | identical |

### Fall (30d)

| activity | Year 1 | Year 2 | Year 3+ |
|---|---|---|---|
| Growable crops | pumpkin, corn, turnip*, eggplant* — Implemented | identical | identical |
| Forage | mushroom, hazelnut — Implemented | identical | identical |
| Fish | 7 incl. salmon, sturgeon — Implemented (richest roster) | identical | identical |
| Festivals/events | harvest_contest 10, harvest_moon 16 — Stubbed (contest judging unimplemented) | identical | identical |
| Quests | infra quests (if unfinished) | none | none |
| Artisan | as Spring; kitchen peak season (4/5 recipes cookable) | identical | identical |
| Social | 1 legacy birthday (Priya 20) | identical | identical |

### Winter (30d)

| activity | Year 1 | Year 2 | Year 3+ |
|---|---|---|---|
| Growable crops | **frost_kale only** — Implemented | identical | identical |
| Forage | snow_truffle, winter_root (+clover) — Implemented | identical | identical |
| Fish | 6 incl. squid, pike exclusives + sturgeon — Implemented (**best ceiling**) | identical | identical |
| Festivals/events | hearthlight 21, winter_starlight 24, starlight_veiling 28 — Stubbed, **all back-loaded** | identical | identical |
| Quests | none seasonal — Absent | none | none |
| Artisan | as Spring (2/3 dead); **0 winter inputs to any machine** | identical | identical |
| Cooking | **0 recipes cookable from in-season inputs** | identical | identical |
| Social | 1 legacy birthday (Tobias 15); canonical 7 nothing | identical | identical |

---

## 3. Dead-week analysis

Weeks = days 1–7 / 8–14 / 15–21 / 22–28 / 29–30. "Dead" = no festival,
no birthday, no quest beat; the only verbs are water/harvest/feed.

### Year 1

| span | status | why |
|---|---|---|
| Spring 1–12 | OK | onboarding: 8 free parsnip seeds, first harvest ~d5, Elena bday d5 |
| Spring 13–30 | OK | bloomtide 13, hanami 15, Sana bday 22 |
| Summer 1–7 | thin | replant beat only, no calendar content |
| Summer 8–21 | OK | Colton 8, sunfield 15, hanabi 20 |
| **Summer 22–30** | **dead** | 9 days, no events; regrow-harvest loop only |
| Fall 1–21 | OK | harvest_contest 10, harvest_moon 16, Priya 20 |
| **Fall 22–30** | **dead** | 9 days, corn-regrow + forage only |
| **Winter 1–14** | **worst dead fortnight in the game** | 14 days, zero calendar content, one plantable crop, no cookable recipes; only ranching/fishing/mining dailies |
| Winter 15–28 | OK | Tobias 15 (legacy NPC), hearthlight 21, winter_starlight 24, starlight_veiling 28 |
| Winter 29–30 | thin | season-end wrap |

### Year 2

The calendar repeats identically; with bundles/automation plausibly
finished, **every week is content-dead except the 9 festival days** —
the vault diamond grind and diamond tool tiers are the only pulls.

### Year 3+

Evaluation fires Spring 1 (one day). The remaining **119 days of Year 3
and all of Year 4+ have zero unique content** — the largest dead span
by far, and the late-game half of this issue.

---

## 4. Balance notes — PriceRegistry bands & the skill curve

- **B-1. PriceRegistry is canonical in name only.** Nothing outside
  `scripts/economy/price_registry.gd` calls it — shipping goes through
  `InventoryManager.sell_item(item_id, qty, unit_price)` with the price
  supplied by the caller (`inventory_manager.gd:72-80`); UI reads
  per-manager `get_sell_price()` (e.g. `scripts/ui/journal_overlay.gd:
  120-141`). Meanwhile the registry's mirrored values have **drifted**
  from the owning managers: salmon 80 vs 60 (`fishing_manager.gd:76`),
  tuna 120 vs 100 (`:78`), wool 40 vs 75 (`animal_manager.gd:88`).
- **B-2. 18 sellable items are missing from the registry**: crops
  turnip/radish/eggplant/strawberry; animal duck_egg/goat_milk; fish
  bream/bass/sardine/squid/pike/eel/sturgeon; forage spring_onion/
  sweet_pea/hazelnut/winter_root/four_leaf_clover. Any future caller
  that *does* delegate to PriceRegistry will price these at 0.
- **B-3. Skill curve is unreachable.** Every activity manager calls
  `SkillManager.add_xp(...)` (`farm_plot_manager.gd:397`,
  `fishing_manager.gd:157`, `foraging_manager.gd:123`,
  `animal_manager.gd:175`, `mining_manager.gd:170`) but SkillManager
  only defines `add_experience()` (`skill_manager.gd:29`) — and that is
  itself placeholder (`level += raw XP`). FarmPlotManager guards the
  call (`has_method`, XP silently lost); the other four call it
  unguarded. Result: the #116 milestones at levels 5/10 can never fire,
  and PriceRegistry's Farming-5 +10% sell bonus
  (`price_registry.gd:121-130`) calls `get_sell_price_multiplier()`,
  which also does not exist. The entire perk/bonus layer is dead
  plumbing today; no content audit of money paths can rely on it.
- **B-4. Winter farming ceiling ≈ 57% of summer.** frost_kale 7.7
  G/day/plot vs melon 13.6, pumpkin 11.7, corn 9.7 (§1.1). With one
  crop there is also no rotation choice — plant day 1–2 or miss the
  season's only farming cycle.
- **B-5. Artisan margins invert availability.** The one working machine
  (mayo, 2×) has the *lowest* multiplier; the 3.3×/5.3× machines have
  unobtainable inputs. Fixing inputs is a bigger economy lever than any
  price retune: e.g. daikon at ~70G base → takuan at ~3× would give
  winter a real processing story.
- **B-6. Bundle pacing ends at the vault.** 9/10 bundles are
  season-paced to Fall–Winter Y1 (§1.9); only `vault_bundle` (3×
  diamond, floor-5+ rare drop) survives into Y2, and nothing survives
  past it. The year-2/3 progression target the issue asks for does not
  exist in any table.
- **B-7. Cooking gate vs content.** Kitchen unlock (house T1: ship 10
  wood + 1000G + 50 wood) is reachable ~mid-Spring Y1, but 4/5 recipes
  want Spring/Summer/Fall produce; a player who unlocks the kitchen in
  Winter finds **nothing cookable** (§1.6).

---

## 5. The winter depth problem, quantified

Winter vs best-other-season, from the §2 matrix:

| axis | Spring | Summer | Fall | Winter | winter vs best |
|---|---|---|---|---|---|
| Growable crops | 5 | 5 | 4 | **1** | 20–25% |
| Crop G/day ceiling | 8.7 | 13.6 | 11.7 | **7.7** | 57% |
| Forage items (excl. clover) | 3 | 2 | 2 | 2 | parity |
| Fish count | 4 | 5 | 7 | 6 | good; best ceiling shared with Fall |
| Festivals | 2 | 2 | 2 | **3** | most — but days 21/24/28 only |
| Event-free opening days | 0 | 7 | 7 | **14** | 2× worst |
| Birthdays (any roster) | 2 | 2 | 1 | 1 (legacy NPC) | thin + off-theme |
| Seasonal quests | 0 | 0 | 0 | 0 | absent everywhere |
| Artisan use-cases | 1/3 | 1/3 | 1/3 | 1/3 | dead everywhere |
| Cookable recipes (in-season inputs) | 2 | 1 | 4 | **0** | 0% |
| Canonical-7 social content | stub | stub | stub | stub | stubbed everywhere |

**Read:** winter's deficit is concentrated, not uniform. Fishing is
fine; foraging is at parity. The hole is exactly four cells: **farming
depth (1 crop), cookable food (0), artisan relevance (0 winter-specific
chains), and event distribution (nothing before day 15)** — plus the
roster-wide problem that none of the JP-canon villagers have birthdays
or finished arcs. Fix those four cells and winter reaches parity
without touching fishing or foraging at all.

---

## 6. Child-content proposals (ready-to-file issue bodies)

Ordered by leverage. Each assumes one PR per issue per #182's scope
note. Effort: S < 1 dev-day, M ≈ 1–3, L > 3.

### Proposal 1 — Register the canonical JRL crop roster

```markdown
Title: [M7][P1] Register JRL canonical crops (rice/daikon/nasu/edamame/sweet_potato/watermelon) in data layer

## Context
The JRL art pack (`design/art/asset-manifest.md` §JRL pack) shipped full
growth-stage sets + harvest icons for rice, daikon, nasu, edamame,
sweet_potato (earlier batch: turnip, watermelon), but
`FarmPlotManager._register_default_content()` still registers the
Western placeholder roster. Content audit: `design/content/season-year-content-audit.md` F-1.1.

## Scope
- Register the canonical 7 in `scripts/autoload/farm_plot_manager.gd` with
  seasons/days/prices per the audit's G/day bands (target: no season below
  Spring's ~8.7 G/day ceiling; daikon = Fall+Winter to close the winter
  single-crop gap).
- Retire or alias Western ids (parsnip/cauliflower/tomato/melon/pumpkin/corn/
  frost_kale); decide `eggplant` → `nasu` migration (gift prefs and bundles
  reference `eggplant`).
- Add shop seeds for ALL registered crops (fixes the 4 missing today, F-1.2)
  and collapse the dual seed-price tables (F-1.3) to one source.
- Sync PriceRegistry + CommunityGoalManager bundle ids to canonical crops.

## Art needs
None — sprites/icons exist (`assets/16bit/crops/crops_jp_sheet.png`,
`assets/16bit/items/icon_*.png`).

## Acceptance criteria
- [ ] All 7 canonical crops plantable, buyable, shippable, priced.
- [ ] Winter has ≥ 2 plantable crops (daikon + one more).
- [ ] Shop catalog covers every registered crop; single seed-price source.
- [ ] Tests updated for new ids.

Effort: M. Dependencies: none (blocks Proposals 2–4).
```

### Proposal 2 — Winter artisan chain: takuan & hoshigaki

```markdown
Title: [M7][P2] Winter artisan chain — takuan (daikon pickles) + hoshigaki (dried persimmon)

## Context
keg/preserves_jar consume `fruit`/`vegetable`, ids nothing produces
(audit F-1.5); winter has zero artisan use-cases (audit §5). Real
machines need real per-item recipes.

## Scope
- Generalize ArtisanMachineRecipe to named-input recipes.
- preserves_jar: daikon → takuan (3d, ~3× base, winter's headline chain).
- New "hoshigaki rack" (or preserves_jar variant): kaki (persimmon) →
  hoshigaki (5d, ~3.5×). Kaki added as a Fall forageable (fills Fall's
  forage count to 3, matching Spring).
- Remove the unobtainable `fruit`/`vegetable` placeholder recipes (or map
  them to real generic categories if code wants a wildcard).

## Art needs
3 item icons: takuan, hoshigaki, kaki (new; not in JRL pack). Optional
hoshigaki-rack prop (string of drying persimmons — high charm, low cost).

## Acceptance criteria
- [ ] All 3+ artisan machines have at least one obtainable input per season.
- [ ] Winter has ≥ 1 artisan chain with ≥ 2.5× multiplier.
- [ ] PriceRegistry entries for takuan/hoshigaki/kaki.

Effort: M. Dependencies: Proposal 1 (daikon). Art: 3 new icons.
```

### Proposal 3 — Winter kitchen: nabe & yaki-imo

```markdown
Title: [M7][P2] Winter cooking recipes — nabe hotpot, zosui, yaki-imo

## Context
0/5 registered recipes are cookable from in-season winter inputs
(audit F-1.6); a Winter kitchen unlock finds nothing to make.

## Scope
- Add 4 recipes to `scripts/cooking/cooking_manager.gd`:
  - nabe_hotpot: daikon + any fish → high stamina (winter signature dish)
  - zosui (rice porridge): rice + egg
  - yaki_imo (roasted sweet potato): sweet_potato ×1 → cheap stamina snack
  - oden (stretch): daikon + egg + fish cake surrogate (squid)
- Delete the dead duplicate `scripts/autoload/cooking_manager.gd`.

## Art needs
None required (cook path is instant; KitchenOverlay exists). Optional:
4 dish icons for inventory display.

## Acceptance criteria
- [ ] ≥ 3 recipes cookable from in-season winter inputs.
- [ ] Every season has ≥ 2 cookable-from-season recipes.

Effort: S. Dependencies: Proposal 1 (rice/daikon/sweet_potato data).
```

### Proposal 4 — Mochitsuki: New Year mochi-pounding + winter event spread

```markdown
Title: [M7][P2] Mochitsuki New Year event + winter calendar redistribution

## Context
Winter's 3 festivals all land days 21–28, leaving days 1–14 content-free
(audit §3, F-1.7a); festivals are signal-only stubs with a placeholder
overlay.

## Scope
- Move winter_starlight 24 → 10 (breaks the dead fortnight; lanterns in
  early-winter dark fits `design/art/jp-world-palette-lighting.md`).
- Add mochitsuki (mochi-pounding) on Winter 28, replacing legacy
  starlight_veiling: first real festival activity — timed pestle
  call-and-response (reuse FestivalMiniGameOverlay's choice/timing frame),
  reward mochi (stamina food) + kagami_mochi home décor.
- Retire the remaining legacy duplicates (bloomtide/sunfield/hearthlight)
  once JP equivalents cover all four seasons (hanami/hanabi/harvest_contest
  already do).

## Art needs
mochi + kagami_mochi icons (new). Reuses player_jp_winter.png,
jizo_shrine, festival lighting spec. No new characters.

## Acceptance criteria
- [ ] No 14-day event-free span in any season.
- [ ] Winter 28 is a JP-canon event with one interactive beat and one
      tangible reward.
- [ ] One festival per season minimum, no legacy/JP duplicates.

Effort: M–L (first non-stub festival logic). Dependencies: none hard;
synergizes with Proposal 1 (rice → mochi).
```

### Proposal 5 — Year-3+ goal structure: "Satoyama Steward"

```markdown
Title: [M7][P2] Post-evaluation goal structure — Satoyama Steward program

## Context
The Y3-Spring-1 evaluation is a one-day beat; after bundles + automation
there are zero year-2/3 progression targets (audit B-6, §3).

## Scope
- After the evaluation (win or open-ended), Toby offers the Satoyama
  Steward program: repeatable seasonal commissions in
  CommunityGoalManager — e.g. "ship 10 gold-quality winter fish",
  "donate 5 takuan to the shrine", "complete 2 festivals with full
  participation". 2–3 commissions per season, small gold + relationship
  rewards, rerolled each season.
- Journal (#117) completion tiers as the long-tail collector track
  (per-category milestones at 50%/100%).
- Challenge-mode only: failed evaluations re-offer yearly instead of
  terminal game-over (keeps Decision A's open-ended tone).

## Art needs
None (reuses CommunityGoalOverlay, journal UI, existing NPCs).

## Acceptance criteria
- [ ] Year 3+ has ≥ 2 new goal beats per season, indefinitely.
- [ ] No new one-shot-only content after Y3 Spring 1.

Effort: M. Dependencies: none; benefits from Proposals 1–3 (more item
variety for commission pools).
```

### Proposal 6 — Canonical-7 social parity

```markdown
Title: [M7][P2] Canonical JP roster social parity — birthdays, heart arcs, marriage roster

## Context
Birthdays exist only for the legacy Western 6 (CalendarManager);
Nina/Cid/Kai/Leo heart arcs stop at level 2–4; MarriageManager's roster
is the legacy 6 while the live roster is the canonical 7 (audit F-1.7b,
F-1.10).

## Scope
- Add birthdays for Toby/Hanna/Cliff/Nina/Cid/Kai/Leo, spread so every
  season has ≥ 2 and **Winter gets a canonical-7 birthday in days 1–14**
  (pairs with Proposal 4's redistribution).
- Write heart-event lines 4/6/8/10 for Nina, 4/6/8/10 for Cid/Kai/Leo
  (Toby/Hanna/Cliff already complete; voice per
  `design/narrative/summer-matsuri-questline.md` honorific rules).
- Unify marriage: one system, canonical-7 roster (recommend keeping
  SocialManager's pendant flow, retiring MarriageManager's stale list).

## Art needs
Portraits for the canonical 7 (only chiyo has portrait art in the JRL
pack today) — needed for dialogue/relationship UI; can ship text-first
with portrait fallback (per #159's fallback path).

## Acceptance criteria
- [ ] Every canonical NPC has a birthday, full 2→10 heart arc, and is
      marriageable in exactly one system.
- [ ] Winter days 1–14 contain ≥ 1 canonical-7 social beat.

Effort: S. Dependencies: none. Art: 7 portrait sets (can defer).
```

---

## 7. Acceptance-criterion check (#182)

> "no season with < 3 distinct money paths by end of year 1"

| season | paths (farming / forage / fish / ranching / mining) | paths ≥ 3? |
|---|---|---|
| Spring | 5 | yes |
| Summer | 5 | yes |
| Fall | 5 | yes |
| Winter | 5 nominal — farming is 1 crop at 57% ceiling | **yes, nominally** |

The criterion **passes as written** today — but it measures breadth,
not depth. Recommend amending the bar when filing Proposal 1–2: "no
season with < 3 money paths **whose ceiling is within 70% of the year's
best season, and ≥ 2 plantable crops**." As written, the current winter
already complies; as experienced, it does not.

## Traceability

- `scripts/autoload/farm_plot_manager.gd:68-81` — crop roster, prices, seeds
- `scripts/autoload/shop_manager.gd:40-47` — shop seed catalog gap
- `scripts/autoload/fishing_manager.gd:71-93` — fish pools
- `scripts/autoload/foraging_manager.gd:52-62` — forage roster
- `scripts/autoload/animal_manager.gd:84-88` — species/products
- `scripts/autoload/infrastructure_manager.gd:126-183` — artisan machines, automation, infra quests
- `scripts/cooking/cooking_manager.gd` — live recipes (autoload); `scripts/autoload/cooking_manager.gd` — dead duplicate
- `scripts/autoload/festival_manager.gd:22-33` — festival calendar
- `scripts/autoload/calendar_manager.gd:14-22` — birthdays (legacy roster)
- `scripts/autoload/community_goal_manager.gd:49-70,164-183` — bundles, Y3 evaluation
- `scripts/autoload/quest_manager.gd` + `scripts/quests/` — quest engine, missing starter content
- `scripts/autoload/skill_manager.gd:11-40` — milestones, broken XP pipe
- `scripts/economy/price_registry.gd:36-91` — registry drift + missing items
- `scripts/autoload/relationship_manager.gd:77-134`, `marriage_manager.gd:55`, `social_manager.gd` — social coverage
- `design/art/asset-manifest.md` §JRL pack — available art for proposals
