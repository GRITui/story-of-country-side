# Shrine Offerings & Community Prestige — System Spec (issue #189)

Design-only spec. No code/scene changes. Adapts the *Japanese Rural Life
Adventure* shrine-offering loop and the *Stardew Valley* community-center
shape to our satoyama village, on top of systems that already exist.

**Existing systems this spec references (verified in `scripts/`):**

| System | File | What we use |
|---|---|---|
| Seasons / day tick | `scripts/autoload/time_manager.gd` | `day_started(day, season, dow)`, 4×30-day seasons, `year` |
| Weather | `scripts/autoload/weather_manager.gd` | Sunny/Rainy/Snowy/Storm, 70/30 roll, per-date deterministic forecast |
| Festivals | `scripts/autoload/festival_manager.gd` | `hanami_picnic` (Spring 15), `hanabi_taikai` (Summer 20), `harvest_contest` (Fall 10), `winter_starlight` (Winter 24); `festival_started` signal |
| Crop quality | `scripts/autoload/farm_plot_manager.gd` | normal/silver/gold weights (silver 20 / gold 10) — prestige buff adds to these weights |
| Foraging | `scripts/autoload/foraging_manager.gd` | per-season forage table; `four_leaf_clover` is the all-season rare drop — prestige buff raises its reroll weight |
| Friendship | `scripts/autoload/relationship_manager.gd` | 0–10 hearts (250 pts/heart); matsuri doc's 0–10 scale maps 1:1 |
| Bundles (precedent) | `scripts/autoload/community_goal_manager.gd` + `scripts/goals/bundle_definition.gd` | `contribute_item()` clamp pattern = anti-dump precedent; Shrine of Gratitude sets reuse this shape |
| Inventory | `scripts/autoload/inventory_manager.gd` | generic item_id → count ledger; offerings pull from it, nothing invented |
| Existing UI | `scripts/ui/community_goal_overlay.gd` | live-read overlay precedent (never hardcode content lists) |

**Existing assets (verified in `assets/16bit/` + `design/art/asset-manifest.md`):**
`props/jizo_shrine.png`, `props/jizo_statue.png`, `props/smoke_0..2.png`,
`ui/washi_panel.png`, `ui/ui_washi_slot.png`, `characters/player_jp.png`
(bow = row 8 of the 8-row sheet), `characters/player_jp_yukata.png`.
Existing crops (JRL art): rice, daikon, nasu, edamame, sweet_potato,
turnip, watermelon.

**Locations:**
- Tier 1 — family Jizo shrine, homestead tile (73,66), `Area2D` id
  `jizo_offering`, already in `design/world/kominka-homestead-blueprint.md` §3.
- Tier 2 — Shrine of Gratitude: offering hall (haiden) in front of the
  honden at (28,14), Zone C `design/world/satoyama-map-topology.md`.
  New `Area2D` id `shrine_gratitude_offering` on the saisen-box tile in
  front of the honden (exact tile left to level design; must sit inside
  the torii threshold so crossing the torii reads as "entering sacred
  ground").

---

## 1. Two-tier offering model

### Tier 1 — Daily Jizo offering (homestead, personal)

Small, private, once-per-day ritual at the family Jizo. The homestead
blueprint already promises this loop (§3 `jizo_offering`, §4 day-5
tutorial "any flower → next-day luck buff"). This spec makes it concrete.

| Field | Rule |
|---|---|
| Frequency | Once per day (resets on `TimeManager.day_started`) |
| Accepted items | `category: "flower_or_forage"`: `wild_flower`, `sweet_pea`, `sakura_petal` (needs content), `momiji_sprig` (needs content), plus the cooked item `dango` (needs content) per the blueprint's "(dango/flower)" note |
| Effect | Next-day minor **Jizo's Blessing** luck buff |
| Prestige contribution | +1 point (counts toward the §2 meter) |
| Friendship | None directly — Jizo is family, not a villager. (Blueprint's "small friendship" is reinterpreted as prestige so the two systems don't double-dip; see §7 Open Questions) |

**Jizo's Blessing** (applies the whole next in-game day):

| Roll | Buff |
|---|---|
| Any accepted item | +2 Foraging XP per gather, +1% gold-quality weight (adds to `QUALITY_WEIGHT_GOLD`) |
| Season-appropriate item (e.g. `sakura_petal` in Spring) | above, plus rare-forage (`four_leaf_clover`) reroll weight ×1.5 |

Offering a rarer item never gives a bigger Jizo buff — the Jizo rewards
constancy, not value. Value belongs to the village shrine (Tier 2). This
keeps the daily habit cheap and the prestige economy legible.

> **Luck system does not exist yet** — no `LuckManager`/daily-luck roll is
> in `scripts/`. Jizo's Blessing is therefore spec'd as two narrow,
> concrete hooks (forage XP bonus, quality-weight bump) applied by the
> offering system itself, not a general luck framework. Flagged as
> engineering scope in §6, not invented here.

### Tier 2 — Shrine of Gratitude (village shrine, seasonal set)

One offering set per season, 4 items each, contributed at the village
shrine. Set completion is permanent per save (repeats every year — sets
reset each time the season comes around, so year-2 players can complete
again). Contributing any set item also feeds the §2 prestige meter.

| Season | Set id | Items (qty 1 each) | Status |
|---|---|---|---|
| Spring | `offering_set_spring` | `sakura_petal`, `turnip`, `bamboo_shoot`, `dango` | turnip ✅ (art); sakura_petal / bamboo_shoot / dango **need content** |
| Summer | `offering_set_summer` | `watermelon`, `sweet_pea`, `edamame`, `sweetfish_ayu` | watermelon ✅ (art); sweet_pea ✅ (forage); edamame ✅ (art); sweetfish_ayu **needs content** (river fish) |
| Fall | `offering_set_autumn` | `sweet_potato`, `mushroom`, `momiji_sprig`, `persimmon` | sweet_potato ✅ (art); mushroom ✅ (forage); momiji_sprig / persimmon **need content** |
| Winter | `offering_set_winter` | `rice`, `snow_truffle`, `mikan`, `yukimi_dango` | rice ✅ (art); snow_truffle ✅ (forage); mikan / yukimi_dango **need content** |

Rules:

- Item ids in **bold-flagged** rows above marked "needs content" do not
  exist yet (no art, no registration). They are *named gaps*, not new
  systems — each is a small item+icon content task (§6), sized to slot
  into the existing crop/forage/fish/cooking tables. The winter-set gaps
  are expected to be resolved by the #182 winter content audit; see §5.
- Every set always has ≥2 items obtainable today, so the feature is
  playable before the gaps land. A set containing an unregistered item id
  simply shows that slot greyed with "???" until content ships.
- Contribution UX mirrors `CommunityGoalManager.contribute_item()`:
  inventory-clamped, never takes more than the set still needs.
- Set completion reward: +10 prestige, `gratitude_token` ×3 (see note
  below), a festival-day blessing if completed before that season's
  festival (§2, T100 interacts), and a one-line village bark the next day.

> **Gratitude Tokens (from issue #189's loop sketch):** the issue proposed
> tokens as a spendable currency on community upgrades. This spec keeps
> tokens *flavor-only* (a keepsake item, sellable for a token 100G at the
> shrine) and routes the actual power through the prestige meter, because
> (a) a second shop currency duplicates `shop_manager.gd` scope, and (b)
> thresholds make prestige visible to the whole village, which is the
> issue's stated fantasy ("community-wide bonuses instead of individual
> rewards"). Token-spend upgrades are listed as a v2 open question (§7).

---

## 2. Community prestige track

Village-wide meter, **0–100**, one per save file (single-player; it models
the *village's* gratitude, earned through the player's offerings).

### Sources

| Action | Points | Cap |
|---|---|---|
| Daily Jizo offering (Tier 1) | +1 | 1/day |
| Gratitude set item contributed (Tier 2) | +3 per item | — |
| Seasonal set completed | +10 | 1/season/year |
| Festival-day offering (any offering on a festival day) | ×2 on that day's points | — |

### Decay

- **−2 per day**, applied at `day_started` before any offering is counted,
  floor 0. Decay is the pressure that makes prestige a *practice*, not a
  stockpile: a player who does one big donation and walks away drifts
  back down over ~2–3 weeks.
- Decay is suspended on festival days (the village is already out
  together; punishing that day feels wrong).

### Thresholds (exact buffs)

Threshold crossings fire once per crossing direction (up = unlock
announcement; decaying back below = quiet lapse, no penalty bark).

| Meter | Name | Community-wide buff | Duration / rule |
|---|---|---|---|
| **25** | *Noticed* | **+5% silver-quality weight** on all harvests (adds to `QUALITY_WEIGHT_SILVER` 20 → 25) | Active while meter ≥ 25 |
| **50** | *Welcomed* | Rare-forage rate up: `four_leaf_clover` reroll weight ×2, and all NPC friendship point gains +10% (rounds down, min +1 on any gain) | Active while meter ≥ 50 |
| **75** | *Honored* | **Festival weather guarantee**: the next festival day in the calendar is forced Sunny (no Storm), overriding the `WeatherManager` roll; also +5% gold-quality weight while ≥75 | Guarantee applies to every festival while meter ≥ 75; quality buff while ≥ 75 |
| **100** | *Beloved of the Village* | All lower buffs, plus: villagers use the player's `-san`/`-chan` honorific one tier warmer (cosmetic dialogue swap), and completing the current season's set at meter 100 lights the shrine lantern row at night (cosmetic PointLight2D chain, same `#F0B860` as the matsuri spec) | While meter = 100; meter hard-caps at 100 |

Design intent: 25/50 are *farm-feel* buffs, 75 is the *community fantasy*
buff (the village prays together and the sky listens), 100 is prestige
flavor, not power — the cap reward should feel like belonging, not a
stat stick.

### Anti-dump rules

1. **Daily prestige cap:** max **+8 prestige/day** from all sources
   (festival ×2 applies after the cap). One Jizo offering (1) + one set
   item (3) + festival doubling ≈ a good day; a stack of 30 turnips moves
   the meter the same as one.
2. **Duplicate diminishing returns:** per season, the same item id
   contributed to a set / the meter gives full points the 1st time,
   **half (round down)** the 2nd–3rd, and **+0** from the 4th onward.
   Sets still need only 1 of each item, so duplicates are pure
   meter-feeding and are explicitly devalued.
3. **Set clamp:** contributions clamp to what the set needs, same
   contract as `CommunityGoalManager.contribute_item()` — the shrine
   physically cannot accept a 99-stack.
4. **Jizo once-a-day** (§1) is itself the Tier-1 anti-dump rule.

Net effect: fastest possible prestige gain ≈ 8/day against −2/day decay →
reaching 100 takes ~2 weeks of *varied, seasonal* play. That's the
intended arc: prestige is a season-long relationship, not a shopping trip.

---

## 3. UX flow

### Interaction flow (both tiers)

```
walk into offering Area2D  →  interact prompt ("Offer" / washi_slot icon)
  → game pauses time (single-player; same freeze pattern as overlays)
  → ShrineOverlay opens (§ wireframe)
  → player picks an eligible item from inventory grid
     (ineligible items greyed with a one-line reason: "The Jizo prefers flowers.")
  → confirm
  → overlay closes, player plays `bow` anim (row 8 of player_jp.png,
     4 frames, ~0.9 s, facing the shrine)
  → incense: smoke_0→1→2 particle sequence rises from the shelf/saisen box
     (2 loops, ~1.6 s), soft wind-chime SFX
  → feedback text line floats above the shrine (§ lines) + HUD toast
     ("Prestige +3 — The village feels warmer.")
  → if tier 2 & set just completed: lantern-row flash + blessing bark
```

The Tier-1 Jizo flow skips the overlay's set tab — single "offer" confirm
straight from the prompt if exactly one eligible item is held; overlay
only when a choice exists.

### UI wireframe — `ShrineOverlay.tscn` (description only)

Reuse the `washi_panel.png` 9-patch style of every existing overlay
(see `scripts/ui/community_goal_overlay.gd` precedent: read content live,
never hardcode). Mobile-first 16:9, two tabs:

```
┌──────────────────────────────────────────────────────────┐
│  ⛩ Shrine of Gratitude          [Offerings] [Prestige]   │  ← washi_panel header
├──────────────────────────────────────────────────────────┤
│ Season tabs: [sakura][sun][momiji][snowflake]  (ui icons)│  ← ui_jp_sheet season indicators
│                                                          │
│  Spring Set            2 / 4 gathered                     │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐             │
│  │sakura  │ │ turnip │ │  ???   │ │ dango  │             │  ← ui_washi_slot frames;
│  │ petal ✓│ │   ✓    │ │(greyed)│ │        │             │    ✓ = contributed
│  └────────┘ └────────┘ └────────┘ └────────┘             │
│                                                          │
│  [ your inventory grid — eligible items highlighted ]    │
│                                                          │
│              [ Offer ]  (disabled if none selected)      │
├──────────────────────────────────────────────────────────┤
│ Prestige tab:                                            │
│   Gratitude of the Village   ████████░░░░░░  62 / 100    │  ← ProgressBar,
│   ▪ 25 Noticed ✓ — silver harvests bless the fields      │    washi-framed
│   ▪ 50 Welcomed ✓ — the village smiles (+10% friendship) │
│   ▪ 75 Honored — clear skies promised on festival days   │
│   ▪100 Beloved — lanterns burn for you                   │
│   "The kami notice constancy, not wealth."               │
└──────────────────────────────────────────────────────────┘
```

### Feedback text lines (matsuri voice, light honorifics)

6 sample lines, shown on offering success (picked by context):

1. (Jizo, any offering) "The Jizo's bib flutters, though there is no wind. ...Thank you, <name>-san."
2. (Jizo, season-matching item) "A spring flower for the road-watchers. They remember kindness like this, you know."
3. (Shrine, set item) "The offering box accepts your gift with a soft wooden clack. Somewhere, the village feels a little warmer."
4. (Shrine, set complete) "Chiyo-san will want to hear about this. The seasonal offering is complete — the kami are smiling, surely."
5. (Prestige threshold up) "Word travels fast in a small village, <name>-san. People have begun to speak your name at the shrine."
6. (Duplicate/diminished) "The kami have seen many of these lately... Perhaps something different would please them more."

---

## 4. Data schema (JSON)

Follows `design/narrative/summer-matsuri-questline.md` conventions
(`quest_id`-style ids, `required_items`, `relationship_delta`). Two blocks:
offering sets (content) and prestige thresholds (system tuning). Content
lives in `content/shrine/` as JSON loaded at boot, same "content reloads,
progress persists" split as `CommunityGoalManager`.

```json
{
  "offering_sets": [
    {
      "set_id": "offering_set_spring",
      "title": "Spring Offering — First Blossoms",
      "season": "Spring",
      "unlock": { "day_min": 1, "friendship_min": 0, "quest_after": null },
      "required_items": { "sakura_petal": 1, "turnip": 1, "bamboo_shoot": 1, "dango": 1 },
      "needs_content": ["sakura_petal", "bamboo_shoot", "dango"],
      "prestige_per_item": 3,
      "completion_bonus": { "prestige": 10, "gratitude_token": 3 },
      "relationship_delta": { "village": 1 },
      "feedback_line": "The kami of spring accept the season's first fruits."
    },
    {
      "set_id": "offering_set_summer",
      "title": "Summer Offering — River and Field",
      "season": "Summer",
      "required_items": { "watermelon": 1, "sweet_pea": 1, "edamame": 1, "sweetfish_ayu": 1 },
      "needs_content": ["sweetfish_ayu"],
      "prestige_per_item": 3,
      "completion_bonus": { "prestige": 10, "gratitude_token": 3 },
      "relationship_delta": { "village": 1 },
      "feedback_line": "Cool melon, bright beans — the river's gifts returned to the river."
    },
    {
      "set_id": "offering_set_autumn",
      "title": "Autumn Offering — Harvest Thanks",
      "season": "Fall",
      "required_items": { "sweet_potato": 1, "mushroom": 1, "momiji_sprig": 1, "persimmon": 1 },
      "needs_content": ["momiji_sprig", "persimmon"],
      "prestige_per_item": 3,
      "completion_bonus": { "prestige": 10, "gratitude_token": 3 },
      "relationship_delta": { "village": 1 },
      "feedback_line": "The storehouse of the mountain, opened in gratitude."
    },
    {
      "set_id": "offering_set_winter",
      "title": "Winter Offering — Warmth in the Cold",
      "season": "Winter",
      "required_items": { "rice": 1, "snow_truffle": 1, "mikan": 1, "yukimi_dango": 1 },
      "needs_content": ["mikan", "yukimi_dango"],
      "prestige_per_item": 3,
      "completion_bonus": { "prestige": 10, "gratitude_token": 3 },
      "relationship_delta": { "village": 1 },
      "feedback_line": "Even in the cold, the village table is full. The kami are warmed."
    }
  ],
  "jizo_daily": {
    "accepted_items": ["wild_flower", "sweet_pea", "sakura_petal", "momiji_sprig", "dango"],
    "needs_content": ["sakura_petal", "momiji_sprig", "dango"],
    "prestige": 1,
    "buff_next_day": { "foraging_xp_bonus": 2, "gold_quality_weight_bonus": 1 },
    "season_match_extra": { "rare_forage_weight_mult": 1.5 }
  },
  "prestige": {
    "max": 100,
    "decay_per_day": -2,
    "decay_suspended_on_festival_days": true,
    "daily_gain_cap": 8,
    "duplicate_returns": { "1st": 1.0, "2nd_3rd": 0.5, "4th_plus": 0.0 },
    "festival_day_multiplier": 2,
    "thresholds": [
      { "at": 25, "id": "prestige_noticed",
        "buff": { "type": "crop_quality_silver_weight", "magnitude": 5 } },
      { "at": 50, "id": "prestige_welcomed",
        "buff": { "type": "rare_forage_and_friendship", "rare_forage_mult": 2.0, "friendship_gain_mult": 1.1 } },
      { "at": 75, "id": "prestige_honored",
        "buff": { "type": "festival_weather_guarantee", "weather": "Sunny", "gold_quality_weight_bonus": 5 } },
      { "at": 100, "id": "prestige_beloved",
        "buff": { "type": "cosmetic", "honorific_tier_up": true, "shrine_lantern_row": true } }
    ]
  }
}
```

`relationship_delta: { "village": 1 }` is kept from the matsuri
convention as a *narrative* marker (village-wide bark unlock); mechanical
village friendship is expressed through the T50 friendship-gain buff, so
the two never double-count.

---

## 5. Edge cases & exploits

| Case | Rule |
|---|---|
| **Day-1 dump** (99 daikon) | Set clamp takes 1 per item id; daily prestige cap +8; duplicate table → 0 after the 3rd. A full inventory of one crop is worth ≤ 8 prestige and one set slot. Nothing else moves. |
| **Winter scarcity** | Winter set is 2/4 available today (`rice` is a Summer-grown crop a prepared player cellars; `snow_truffle` is a rare Winter forage). If `mikan`/`yukimi_dango` are still missing when this ships, winter set shows 2 greyed "???" slots and is *completable later* — decay −2/day is the only winter pressure, and T75's festival guarantee still works. **Hook note for #182:** the winter audit owns filling `mikan`/`yukimi_dango` (or swapping them); this spec does not depend on #182 shipping. If #182 changes winter forage, update `offering_set_winter` content only. |
| **Season lapses with incomplete set** | Nothing is lost: contributed items stay credited, the set re-opens next year same season. Decay still applies to the *meter*, so an abandoned season reads as "the village gently forgets," never as punishment (matches the matsuri doc's "the village never punishes" rule). No wither/reset of set progress. |
| **Festival-day doubling + cap** | Doubling applies to the source points first, then the 8/day cap clamps — festival day ceiling is 8, same as any day; the ×2 just makes it *easier* to reach the cap on a day with less play time. |
| **Decay crossing a threshold downward** | Buff lapses quietly (no bark, no penalty text). Re-crossing upward re-announces once. No hysteresis band needed at this scale. |
| **T75 weather guarantee vs. `WeatherManager`** | Guarantee is an override applied at festival-day `day_started`: if meter ≥ 75, force `Sunny` (and `is_storm=false`) for that date before `weather_changed` emits. It must not touch `get_weather_for_date()` forecasts for *other* dates; forecast for the festival date should agree with the override so the calendar never lies. |
| **Offering at 100/100** | Cap holds; extra points are discarded. The feedback line acknowledges ("The village could not think more warmly of you.") so the action never feels eaten. |
| **Unregistered item ids in a set** | Greyed "???" slot; excluded from completion check *only if* flagged `needs_content` — the set is "complete for now" at 2/4 until content ships, then retroactively requires the new items (year-boundary re-check, never mid-season). |

---

## 6. Effort estimate & child tasks

Overall: **~6–9 dev-days** (1 small art batch + 2 engineering tasks + 1
content task). No new systems-of-systems; everything hangs off existing
autoloads.

### Child issue A — Art: shrine offering assets (S, ~1–2 days)

```
Title: [Art] Shrine offering sprites — incense, momiji, sakura petal, 4 item icons
Body:
- New prop: incense burner + offering bowl for honden front (fits props/ style, bottom-center anchor)
- Item icons (16x16, items/icon_*.png convention): sakura_petal, bamboo_shoot,
  sweetfish_ayu, persimmon, mikan, yukimi_dango, gratitude_token
- momiji_sprig forage sprite (ForageNode overlay) + icon
- Reuse existing: jizo_shrine.png, smoke_0..2, washi_panel.png — no changes
Ref: design/systems/shrine-offerings-spec.md §1, §4. Blocks content task D icons.
```

### Child issue B — Engineering: ShrineManager autoload (M, ~2–3 days)

```
Title: [Eng] ShrineManager autoload — offerings, prestige meter, threshold buffs
Body:
- New autoload per design/systems/shrine-offerings-spec.md:
  - jizo daily offering (once/day, next-day buff: +2 Foraging XP, +1 gold quality weight)
  - 4 seasonal offering sets loaded from content/shrine/offering_sets.json
    (contribute_item() clamp contract copied from CommunityGoalManager)
  - prestige meter 0-100, decay -2/day (suspended on festival days),
    daily gain cap 8, duplicate diminishing returns, festival x2
  - threshold buffs at 25/50/75/100 wired into FarmPlotManager quality weights,
    ForagingManager reroll weights, RelationshipManager gain mult
  - T75 festival-weather override hook in WeatherManager day_started flow
  - to_save_dict/from_save_dict; signals: offering_made, prestige_changed,
    threshold_crossed, set_completed
Ref: design/systems/shrine-offerings-spec.md §1-2, §4-5.
```

### Child issue C — Engineering/UX: ShrineOverlay + interaction + animation (S–M, ~1–2 days)

```
Title: [UX/Eng] ShrineOverlay.tscn + offering interaction flow
Body:
- Overlay per wireframe in design/systems/shrine-offerings-spec.md §3
  (washi_panel 9-patch, season tabs via ui_jp_sheet indicators, live-read
  from ShrineManager — no hardcoded content)
- Wire jizo_offering Area2D (homestead 73,66) + new shrine_gratitude_offering
  Area2D at honden front (Zone C)
- Player bow anim (player_jp.png row 8) + smoke_0..2 particle on offer
- 6 feedback lines from spec §3 into content/dialogue/
Depends on: ShrineManager (child B).
```

### Child issue D — Content: offering sets + needs-content items (S, ~1 day, blocked partially by A)

```
Title: [Content] Shrine offering sets JSON + 7 missing items
Body:
- content/shrine/offering_sets.json per design/systems/shrine-offerings-spec.md §4
- Register needs-content items in the appropriate existing tables (no new systems):
  sakura_petal (spring forage), momiji_sprig (fall forage), bamboo_shoot (spring forage),
  sweetfish_ayu (river fish, summer), persimmon (fall crop or tree), mikan (winter),
  yukimi_dango (cooked), dango (cooked)
- mikan/yukimi_dango coordination with #182 winter audit (hook note, spec §5)
Depends on: Art icons (child A) for item registration with icons.
```

---

## 7. Risks / open questions for the PO

1. **Tokens vs. pure prestige.** Issue #189's sketch had spendable
   Gratitude Tokens buying upgrades (fountain repair, bridge restoration).
   This spec routes power through thresholds instead (§1 note). If the PO
   wants the token-shop fantasy, that's a v2 scope add: a shrine
   upgrade shop reusing `shop_manager.gd`, plus new world-state for
   fountain/bridge. Confirm direction before engineering starts.
2. **"Small friendship" at the Jizo.** The homestead blueprint says Jizo
   offerings give "small friendship + luck." We mapped friendship →
   prestige to avoid double-dipping the T50 friendship buff. If a named
   NPC should notice home offerings (e.g. Chiyo comments), that's a bark
   hook, not a points change.
3. **Multiplayer/co-op posture.** Prestige is per-save "village-wide." If
   co-op is ever on the roadmap, decide now whether the meter is shared
   (recommended) — retrofitting is painful.
4. **T75 weather override vs. storm-day content.** Forcing Sunny festivals
   is safe, but if any future festival *wants* rain (rainy hanami is
   atmospheric), the guarantee needs a per-festival opt-out flag.
5. **Winter completeness.** Winter set is 50% needs-content today (§5).
   If #182 slips, either ship with 2 "???" slots (current plan) or PO
   picks substitute items from existing tables (e.g. `winter_root`).
