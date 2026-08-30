# Cozy Activities — System Spec (issue #190)

**Status:** Design + art complete; engineering children ready to file.
**Area:** wellness · P3 · Stardew-vs-Harvest-Moon middle ground (see §2).

Three self-care rituals the player can perform at home: **matcha tea
ceremony**, **ikebana flower arranging**, **journaling**. Each grants a
small, clearly-capped benefit once per day. They cost in-game time and
nothing else — no ingredients, no fail states, no daily obligation.

Doc + icons only. **No code/scene changes on this branch.**

---

## 1. The activities

Animation constraint: `characters/player_jp.png` ships 8 rows — idle,
walk, sit_engawa, hoe, plant, net, fish, bow (`design/art/asset-manifest.md`).
All cozy activities **reuse `sit` (row 2) or `bow` (row 7) only; no new
animation rows are requested.** Prop icons below are 16×16, ready in
`assets/16bit/items/`.

| Activity | Prop (icon) | Unlock | Time cost | Animation | Benefit (plugs into real systems) | Cooldown |
|---|---|---|---|---|---|---|
| Matcha Tea Ceremony | tea set (`items/icon_tea_set.png`) | `matcha_day` — first morning notification, always granted | 30 in-game min | `sit` | `StaminaManager.max_stamina += 10` until sleep (→ 110 cap for the day; resets via `to_save_dict`/`from_save_dict` cycle on `day_started`) | 1/day |
| Ikebana | vase (`items/icon_ikebana.png`) | `first_flower` — first `wild_flower`-category item gathered | 60 in-game min | `sit` | +20 friendship points on **every gift given today** (one neutral-gift tick per `GiftPreferenceTable.point_delta_for`); expires at sleep. Not stackable with itself. | 1/day |
| Journaling | writing desk (`items/icon_journal.png`) | `day_3` — third morning notification | 45 in-game min | `sit` | +10 stamina restored on **wake tomorrow** (fires as `StaminaManager.restore(10)` after `restore_full()`, so it can exceed the 100 cap only while `cap_active`) | 1/day |

Detail rows:

- **Matcha, one detail:** if a marriageable NPC is within 6 tiles and has
  not talked today, also grant one free `RelationshipManager.talk_to`
  (20 pts) — the "shared bowl" moment. Otherwise solo.
- **Ikebana, one detail:** completing it re-rolls the displayed
  arrangement from the current season's flower set (purely cosmetic,
  persistent until replaced).
- **Journaling, one detail:** also writes a one-line auto-entry into
  `JournalManager` flavor log (day number + activity), reusing the
  existing `journal_entry.gd` Resource — no UI change required.

### Benefit philosophy — "nice" vs "nicer", never "failed"

There is no failure path. Performing an activity is always *nice*
(benefit granted, cozy overlay plays). A **"nicer"** flourish triggers
when a gentle condition is met (tea shared with an NPC present;
ikebana arranged with a just-gathered seasonal flower; journaling on a
festival day) and only adds flavor text — the numbers never change, so
players never feel they "did it wrong." Missing a day costs nothing:
no streak tracking, no decay, no guilt UI. The bento gauge
(`ui/ui_bento_full/half/empty.png`) reflects the +10 cap only while
it's active.

## 2. Middle-ground positioning (the issue's core tension)

*Stardew Valley* lets automation erase the daily loop; *Harvest Moon*
punishes you for touching the loop at all. This spec lands between:

| Pole | What we take | What we reject |
|---|---|---|
| Stardew automation | Optional convenience; cozy time-boxed (30–60 min of a ~14 h day) | Never required for farm viability; no "optimal cozy route" to solve |
| HM stamina punishment | Benefits are **nudges on top of** the existing 100-stamina budget (`scripts/autoload/stamina_manager.gd`), small enough to stay flavorful (+10 cap = 2–3 extra tool swings, not a second day) | No penalty for skipping; no fatigue multiplier on days without cozy activities |

Concretely: all three benefits expire at sleep or next wake; nothing
persists, accumulates, or gates progression. A player who never touches
the Cozy Corner loses zero efficiency they couldn't buy back with one
`parsnip_soup` (30 stamina, `scripts/cooking/cooking_manager.gd`).

## 3. Cozy Corner placement spec

Interior scene (per `design/world/kominka-homestead-blueprint.md` §1–3:
kominka walls occupy (61–68, 60–62), shoji door at (65,62), engawa
veranda row (61–68,63) with existing `engawa_rest` Area2D).

- **Cozy Corner slot:** interior tile **(63, 60)** — the tokonoma alcove
  on the interior back wall, opposite the door. One decoration slot,
  `Area2D` rect (63,60)→(63,60), `interact_type = "cozy_swap"`.
- **Swap interaction:** interacting opens a 3-item radial (tea set /
  ikebana vase / writing desk), same UI pattern as the hotbar washi
  slots. The placed prop renders as a `Sprite2D` (16×16 icon upscaled
  2×, bottom-center anchored per `asset-manifest.md` wiring notes) on
  the alcove tile. A second `Area2D` on the placed prop,
  `interact_type = "cozy_use"`, starts the activity.
- **Seasonal variant — winter kotatsu:** in Winter the alcove prop is
  replaced by a **kotatsu** (table + blanket sprite swap). During the
  Night lighting checkpoint (`jp-world-palette-lighting.md` §2,
  CanvasModulate `#2A2E4A`) the kotatsu adds a PointLight2D, color
  `#F0B860`, energy 0.6, texture_scale 3 — the same "indoor warm"
  kotatsu/irori glow defined in the Winter palette row (signature
  `#E8F0F8` + `#F0B860`: cold outside, warm inside). Cozy benefits are
  unchanged; winter is a pure visual/ambient variant.
- **Why here and not the engawa:** `engawa_rest` stays a free,
  always-available stamina regen spot; the Cozy Corner is the *chosen
  ritual* inside the house. Keeping them separate preserves the
  blueprint's first-minute read ("engawa visible from spawn door")
  while giving the interior a destination.

## 4. Sample UI / feedback text

Voice per `design/narrative/summer-matsuri-questline.md` — warm,
low-pressure, second-person, no exclamation-mark hype. Floating-text
lines on completion; the last two are "nicer" flourishes.

1. `The water settles. The matcha froths. You feel ready. (+10 stamina until sleep)`
2. `Two stems, one blossom. The room breathes easier. (Gifts today +20)`
3. `The page fills slowly. Tomorrow's shoulders feel lighter. (+10 stamina on wake)`
4. `Tea for two — <npc>-san smiles into the bowl. (+1 talk today)`
5. `A <seasonal_flower> still cool from the morning field. The arrangement glows.`
6. `Festival ink dries slowly. This entry will be a good one to reread.`

## 5. Data schema (per activity)

Mirrors the quest schema conventions in
`design/narrative/summer-matsuri-questline.md` §1 (`id`, `unlock`
block, flat step-adjacent fields, snake_case keys):

```json
{
  "activity_id": "matcha_ceremony",
  "title": "Matcha Tea Ceremony",
  "cozy_slot": "tokonoma",
  "unlock": { "trigger": "matcha_day", "day_min": 1, "quest_after": null },
  "duration_min": 30,
  "animation_row": "sit",
  "benefit": {
    "type": "stamina_cap",
    "amount": 10,
    "expires": "sleep",
    "shared_tea_npc_radius_tiles": 6
  },
  "cooldown": { "uses_per_day": 1 },
  "item": { "id": "tea_set", "icon": "items/icon_tea_set.png",
            "is_consumable": false, "is_infinite": true },
  "seasonal_variant": { "winter": "kotatsu_lighting" }
}
```

```json
{
  "activity_id": "ikebana",
  "title": "Ikebana Flower Arranging",
  "cozy_slot": "tokonoma",
  "unlock": { "trigger": "first_flower", "day_min": 1, "quest_after": null },
  "duration_min": 60,
  "animation_row": "sit",
  "benefit": {
    "type": "gift_friendship_bonus",
    "amount_points": 20,
    "applies_to": "gifts_today",
    "expires": "sleep"
  },
  "cooldown": { "uses_per_day": 1 },
  "item": { "id": "ikebana_vase", "icon": "items/icon_ikebana.png",
            "is_consumable": false, "is_infinite": true },
  "seasonal_variant": { "winter": "kotatsu_lighting" }
}
```

```json
{
  "activity_id": "journaling",
  "title": "Evening Journaling",
  "cozy_slot": "tokonoma",
  "unlock": { "trigger": "day_3", "day_min": 3, "quest_after": null },
  "duration_min": 45,
  "animation_row": "sit",
  "benefit": {
    "type": "wake_stamina_restore",
    "amount": 10,
    "applies_to": "next_morning",
    "expires": "on_apply"
  },
  "cooldown": { "uses_per_day": 1 },
  "item": { "id": "writing_desk", "icon": "items/icon_journal.png",
            "is_consumable": false, "is_infinite": true },
  "seasonal_variant": { "winter": "kotatsu_lighting" }
}
```

System touchpoints (existing, verified): `StaminaManager.max_stamina` /
`restore()` (`scripts/autoload/stamina_manager.gd`), `TimeManager`
(`MINUTES_PER_REAL_SECOND = 1`, `day_started` signal for cooldown +
expiry resets, `scripts/autoload/time_manager.gd`),
`RelationshipManager.give_gift` / `TALK_POINTS` / neutral 20-pt gift
delta (`scripts/autoload/relationship_manager.gd`,
`scripts/social/gift_preference_table.gd`), `JournalManager` +
`journal_entry.gd` (`scripts/journal/`).

## 6. Effort estimate & child tasks

**Total: ~5–8 dev-days** across three lanes. Ready-to-file issue
snippets (parent: #190):

### ART — `cozy-corner prop sprites + kotatsu variant` (1–1.5 d)
```
Add tokonoma alcove prop + 3 placed-item sprites (tea set, ikebana,
desk) at tile scale, plus winter kotatsu sprite. Extend
assets/16bit/generator/gen_jp_cozy.py with a props section; sel-out
#4A3320, validate.py must stay OK. Icons (16x16) already shipped in
items/cozy_sheet.png.
```
### ENGINEERING — `CozyManager autoload + tokonoma interaction` (2.5–4 d)
```
New scripts/autoload/cozy_manager.gd: load activity JSON (schema in
design/systems/cozy-activities-spec.md §5), enforce 1/day cooldown via
TimeManager.day_started, apply benefits:
- stamina_cap: StaminaManager.max_stamina += 10 (restore on day_started)
- gift_friendship_bonus: wrap RelationshipManager.give_gift for today
- wake_stamina_restore: StaminaManager.restore(10) after day_started
Kominka interior scene: Area2D at (63,60) interact_type "cozy_swap",
radial swap UI, sit-row anim + 30/60/45-min TimeManager advance,
CozyOverlay floating text (AnimationPlayer fade).
```
### CONTENT — `cozy text pack + morning notifications` (1–1.5 d)
```
6 floating-text lines (spec §4) into content/dialogue/, 3 morning
notification unlock barks (matcha_day, first_flower, day_3) via
scripts/ui/morning_notification.gd, winter kotatsu flavor line.
Voice per summer-matsuri-questline.md.
```
### QA — `cozy regression` (0.5 d)
```
Headless: cooldown reset on day_started, cap revert on sleep, gift
bonus expiry, no-streak/no-decay invariant (skip 5 days → no penalty
state), save/load round-trip of pending wake bonus.
```

---

## Appendix — files referenced

- Blueprint & triggers: `design/world/kominka-homestead-blueprint.md`
- Palettes / winter kotatsu light: `design/art/jp-world-palette-lighting.md` §1 (Winter), §2 (Night)
- Voice: `design/narrative/summer-matsuri-questline.md`
- Player sheet rows: `design/art/asset-manifest.md` (JRL pack §characters)
- New icons: `assets/16bit/items/icon_tea_set.png`, `icon_ikebana.png`,
  `icon_journal.png`, strip `items/cozy_sheet.png` (48×16)
- Generator: `assets/16bit/generator/gen_jp_cozy.py`
