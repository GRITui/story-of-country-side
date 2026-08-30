# Game-Tester S-Tier Audit — "Story of Country Side"
**Role:** Game Tester (auto-play loop) · **Date:** 2026-08-27
**Target:** make the game reach **S-Tier** game quality, benchmarked against the
roadmap laid out in `superuser/reports/sprint-003.md` (SCAMPER roadmap, phases P0-P4,
measurable S-tier bar) and genre leaders.

> This is a **live, hands-on audit performed today against the current working
> tree**, not a desk review. I actually ran the engine, booted the game, and drove
> the full new-player loop. Read-only on all game code; findings are advisory for
> the PM/Producer. Severity = P0–P4 per `SUPERUSER.md` / GRITui issue labels.

---

## 0. Verdict (TL;DR)

The game has a **complete, correct, and unusually deep systems core** — it plays
clean end-to-end (0 failures across the whole auto-play pass) and the economy is
now defensible (seeds cost, prices are real). But it is **not yet S-tier**: S-tier
in this genre is won on the **experience layer** (rhythm / feel / onboarding /
payoff / retention), and **nearly all of that layer is still missing or unprovable
in real play.** Mechanics: A–. Experience: C+. Rating: a strong **B-tier prototype**
with clear S-tier trajectory.

**Top 5 blockers, in priority order, that gate S-tier:**
1. **#101 + #100 — the player does not exist yet** (no movement/avatar/controls).
   You cannot *feel* a farm game with no one to control.
2. **#102 — the town is empty** (villagers are fully built in backend but never appear on any scene).
3. **#91-gap — no shop/buyer UI**, so seeds & tools can't actually be purchased → early economy is a closed loop.
4. **#108 — no day-one quest/onboarding** → first-time players idle aimlessly.
5. **# 111 equity silent marriage + #110 no birthdays** → relationship/season payoff unreachable & invisible.

Everything below is the full, itemized, actionable list with verification evidence.


## 1. What I actually ran (method + live results, 2026-08-27)

**Engine:** Godot `4.3.stable.official.77dcf97d8` (matches QA pin). **Tree:** current
working tree (on `frontend/ux-polish-94`; uncommitted docs pending). Ran the shipped
test battery, the retail-economy harness, and the full new-player auto-play driver.

| Step | Result |
| --- | --- |
| Headless editor import refresh | Clean |
| Full unit suite `tests/TestRunner.tscn` | **1078 checks PASS** (green upward trend: 904→959→962→1078) |
| Smoke boot (TitleScreen / Main.tscn) | Clean, exit 0, no runtime errors |
| Retail economy matrix (`RetailSimDriver --phase retail`) | **21/21 checks PASS** → #97 (sell-price stock-loss) is **FIXED**, two-gate purchases hold |
| Auto-play full new-player run (`AutoplayDriver --phase full`) | **failures=0**: plant→water×5→harvest (parsnip, normal), catch→ship→overnight payout (**gold 500→519**, silver-carp 15×1.25 math exact), travel Ranch/Mine/Forage/Farm, break_rock ok, ranch add/feed/brush ok, forage gather ok |

**Pacing facts (measured in the run):** 171 real-seconds / in-game day without
sleep; first parsnip ≈ 14.3 idle real-minutes if you never sleep. `#93` sleep/day-skip
is in the scene set (SleepZone) and is the intended fix — re-measure with sleep to
confirm the 15-min-first-payout bar is met.

**Rank/confidence:** The systems loop is verified *working today*. Every checklist
item below that is "missing" was **confirmed absent by grep in the current tree**
(see §5 evidence column), so this list is current, not stale sprint-report copy.

---

## 2. Genre benchmark — where S-tier actually lives

I compared against the farm/country-side life-sim leaders (same axis the roadmap
uses). The unifying lesson: **nobody earns S-tier on mechanics; they earn it on
feel, onboarding, seasonal rhythm, and retention.** Mechanics are this repo's proven
strength (five activity loops + ranching + artisan + festivals + a marriage backend
deeper than expected) — so spend almost all remaining effort on the experience layer.

| Game | What makes them S-tier (borrow) | What NOT to copy |
| --- | --- | --- |
| **Stardew Valley** | Content breadth + *coherence*; every system visible & rewarding; mod moat; gentle onboarding; villager lives that feel alive | Don't need their sprite volume or 3-year scope |
| **Story of Seasons / Harvest Moon** | Seasonal rhythm cadence; **romance payoff is reachable & presented** (heart scenes, wedding) | BTN's 3-year eviction stress (contradicts Decision A) |
| **Fields of Mistria** | "Juice" — animation, sound, punchy feedback on every action | Don't chase their art budget 1:1 |
| **Roots of Pacha** | Co-op novelty | Co-op is DEFERRED (cost tier) |
| **Graveyard Keeper** | Theme coherence over feature count | Not our tone |
| **Littlewood** | **Friction-removal-as-feature** (fast days, easy all-in-one) | — |
| **Coral Island / My Time** | Modern QOL: map zones, weather forecast, shop UIs, quest log, journal, multi-slot saves | Heavy 3D + production chains not needed |

**S-tier definition used here** (from the roadmap's measurable bar): zero open P0/P1;
first payout ≈<15 real minutes via a starter chain; **no shipped system invisible on
screen**; a festival + a birthday every season; collection journal + skill perks live;
cozy-friction floor met (sleep-skip, rain relief, multi-slot saves).

---

## 3. Roadmap reference & S-tier bar — current status matrix

Source: `superuser/reports/sprint-003.md` addendum 4 (SCAMPER roadmap). My live
verification of where each phase stands on the current tree (gr=A grep-verified
present/absent; "= live-run verified).

| Phase | Theme | Key items | **Status today (2026-08-27)** |
| --- | --- | --- | --- |
| **P0 Trust** | #97 sell-guard, #90 festival reboot | #97 (#103), #104 | ✅ **MOSTLY CLOSED** — #97 fixed (21/21 retail), #90 festival re-derivation merged. Remaining: AudioManager leak, test hygiene |
| **P1 Feel** | #92 title, #93 sleep, #94 polish, **#100 avatar, #101 controls, #102 NPCs** | #92 title screen ✅, #93 sleep ✅ | ❌ **BLOCKER** — #100/#101/#102 (the whole embodiment layer) still absent |
| **P2 New-player arc** | #108 starter chain, **#91 shop UI**, #96 price registry, #98 sale log | #91 seed backend ✅, purchase UI ❌ | [partial] — economy model done, **buyer/shop UI + quest chain missing** |
| **P3 Season rhythm+payoff** | #110 birthdays/calendar, #111 marriage screens, #115 winter festival, #112 weather depth, #109 cooking | backend marriage ✅ | ❌ **mostly missing/missable** |
| **P4 Retention/longevity** | #105-107 world, #113 music, #116 perks, #117 journal, #118 multi-slot, #120 pass-out, #119 mod seam | #113 notes | ❌ **not started** (except art assets landed) |

### Measurable S-tier bar → current status
| Bar (from sprint-003) | Status |
| --- | --- |
| Zero open P0/P1 | ❌ — #100/#101/#102 and the shop-UI gap are open P1/P2 |
| First payout <≈15 real-min via starter chain | 🔶 — sleep exists but starter quest (#108) has **no quest UI/condition**, so unproven/not-quest-able |
| No shipped system invisible on screen | ❌ — villagers, marriage, festival event wire, mining ore sets, artisan all backend-invisible |
| Festival + birthday every season | 🔶 — 3 festivals exist (Bloomtide/Summer?, Feast/Hearthlight), **Winter has 0**; birthdays absent |
| Journal + perks live | ❌ — no journal, no live perks |
| Cozy-friction floor (sleep-skip, rain relief, multi-slot) | 🔶 — sleep ✅, `#112` weather (rain relief) absent, `#118` multi-slot absent |

---
---
## 4. THE CRIT - the gap list that gates S-tier (roadmap-mapped)

### 4.1 New findings from THIS auto-play run (not previously on the roadmap)
- **N1 [P1] `superuser/run_battery.sh` is broken as-shipped.** Its steps 5-7 call
  `RetailSimDriver --phase title|fest_save|fest_check`, but retail_sim_driver.gd only
  implements `--phase retail`, so those steps always exit "unknown phase". Anyone
  running the battery sees 3 fake failures. Verified: fest_check logged
  "unknown_phase_fest_check". Fix: add the probe phases to the driver or trim steps.
- **N2 [P2] Unit suite passes but prints 2 real SCRIPT/JSON errors.** `harvest_ready`
  on `Nil` (test_runner.gd:1529) and `watered_today` on `Nil` (test_runner.gd:3189).
  Green-but-noisy is a trust problem; fix the Nil node those tests deref.
- **N3 [P2] AudioManager one-shot SFX leak persists:** exit prints "ObjectDB leaked /
  1 resource still in use" on every run, including this auto-play pass. Known since
  PR #75; still open. Fix forward so it stops masking future leaks.
- **N4 [P1] No shop/buyer scene anywhere.** grep of scenes/ for shop/seed/tool is empty.
  The model consumes seeds (plant() -> has_item/remove_item, verified), but no scene
  lets a player buy more, so a broke player is permanently locked out of farming.

### 4.2 Roadmap content gap (phases P1->P4)

**P1 - Feel (the critical embodiment layer)**
- **#100 [P1] Player avatar.** Verified: no player/CharacterBody node in any world scene.
  A feel-based farm game with no one to control has no feel. Walk sheets exist; wire a
  placeholder avatar + 4-dir facing + tool-swing feedback. Effort: M.
- **#101 [P1] Input map + controls.** Verified: project.godot has NO [input] section;
  everything is raw click/button. Add WASD/arrows, interact, advance-dialog, hotbar 1-8.
  No combat inputs (Decision B). Land with #100. Effort: M.
- **#102 [P1, area:social] Villagers actually in the world.** Backend done, but
  NPCController appears in ZERO world scenes. A dead town reads as dead. Instantiate
  them via existing schedules. Effort: S-M.

**P2 - New-player arc & shopfront**
- **#96 [P2] Canonical price registry.** ShopManager exists but no get_sell_price;
  prices diverge across CropDef + quality multipliers + caller unit_price. Add a
  read-only EconomyRegistry. Effort: S.
- **#98 [P2] Nightly sale receipt.** Persist per-line detail and show a genre-standard
  "sold 2x parsnip +105g / shipped 3x melon" morning card. Effort: S.
- **#108 [P2] Starter quest chain.** All 10 quests are late-game; zero day-one
  guidance. Ship ship->earn->befriend->explore, payout ~15 min. One EARN_GOLD
  condition type. Effort: M.
- **#91-shop [P1] The shop scene itself** (a selling NPC/stall wired to ShopManager).
  Highest-impact new-player item. Effort: M-H.

**P3 - Season rhythm & payoff (the emotional layer)**
- **#111 [P1/P2, area:social] Reachable, PRESENTED marriage loop.** The backend is
  deeper than most S-tier games (pendant @8 hearts, proposal, wedding, children) but is
  UNREACHABLE and SILENT: mermaid_pendant has no source, and the ceremony fires as a
  state change with no presentation. Add a pendant source, heart-event cutscenes
  (reuse IntroSequence visuals), a propose button and wedding screen. Effort: H.
- **#110 [P2, area:social] Villager birthdays + calendar.** "birthday" appears nowhere.
  Add the gift multiplier + a simple calendar overlay so each season has a beat.
  Content-lane field on GiftPreferenceTable. Effort: S.
- **#115 [P3] Winter festival.** Verified: 3 festivals only (Bloomtide, Feast,
  Hearthlight); Winter holds ZERO. Add a snow festival + minigame. Effort: M.
- **#112 [P3] Weather depth.** Rain auto-waters (water docstring flags it absent),
  a harmless storm accent, tomorrow forecast in HUD. Effort: S-M.
- **#109 [P2] Cooking & eating.** StaminaManager.restore() has no gameplay caller;
  artisan goods need a second use; kitchen at House T2. Add recipes->restore with NO
  hunger meter (keep cozy). Effort: M.

**P4 - Retention / longevity / friction floor**
- **#113 [P3] Real seasonal music.** Replace the sine drone with season loops + a
  festival jingle (source under ATTRIBUTION.md norms). Effort: M / content.
- **#118 [P1] Multi-slot saves.** SaveManager writes a SINGLE user://savegame.json.
  With #92's New Game now live, one slot = reset-loss anxiety. Build the slot list the
  menu-spec already declares; gate before any wide release. Effort: M.
- **#117 [P3] Collection journal.** No journal. Log crops/fish/ore/forage "seen & collected" - the discovery hand+mid-game retention hook. Effort: M.
- **#116 [P3] Skill milestone perks.** SkillManager's level_changed hook is reserved
  but unused; skills overlay has no unlock UI. Add small perks. Effort: S-M.
- **#105/#107 [#106 epic] World variety (sea coast + mountains biomes).** Sea fish
  already exist against abstract location strings with no coast; multi-map extends by
  one dict entry; tile art is location-agnostic. Effort: H (epic).
- **#120 [decision] Pass-out penalty.** Tester lean: option `c` (reduced-stamina next day);
  decide after #109. Effort: S.
- **#119 [P4] Modding-lite content-pack seam.** Reserve the data seams (#96/#108/
  #110/#116 choose shapes now) for far-future packs. Effort: planning only.

## 5. Priority & suggested build order (most S-tier-per-effort first)
1. **Embodiment cluster (#100+101 then #102)** - unblocks every "feel" and lets every
   later feature be *perceived*. Without it nothing else reads as fun. [P1]
2. **Shop scene (#91-shop) + #96 registry** - makes the verified economy actually
   playable and closes the N4 soft-lock. [P0/P1]
3. **#108 starter quest + #98 sale receipt** - proves the first-payout bar, teaches
   shop+bin, removes first-hour aimlessness. [P2]
4. **Marriage (#111) + birthdays (#110)** - the emotional capstone and the seasonal
   rhythm beat; highest replayable-payoff per effort in P3. [P1/P2]
5. **Friction floor: #118 multi-slot, #112 rain relief** - cozy floor + trust. [P1/P3]
6. **#115 winter festival + #113 music** - seasons feel complete. [P3]
7. **#117 journal + #116 perks** - the mid-game retention loop. [P3]
8. **World (#105/#107/#106)** - ambition / longevity; last because it is biggest.
9. **Cleanup (N1 battery, N2 test Nil, N3 audio leak)** - do in parallel with any
   squad pass; they are ~trust hygiene and gate the "green build" aesthetic of S.

## 6. Non-goals (recorded so they don't silently re-open)
Do NOT chase: combat/enemy AI (Decision B), BTN-style 3-year eviction deadline
(Decision A), a sprite/art volume arms race, dynamic per-NPC shop pricing for v1,
quest-gated biome travel (contradicts openness), or co-op multiplayer (cost era).
Compete on systems correctness, coziness, and modern UX - that IS the S-tier lane
for this codebase.

## 7. How to use this report
- PM/Producer: triage items into the backlog as issues if not already filed; the
  roadmap (P0-P4) stands, this sharpens *what* and *why* per item with today's
  evidence. Re-run `superuser/run_battery.sh` after each batch (it will show N1-
  hygiene until the harness/driver are synced) and drive `AutoplayDriver --phase full`.
- Test evidences cited (assets backings): the retail + autoplay run logs from
  today's battery at `/tmp/battery-tester-*`; unit suite 1078 checks; code greps
  listed inline above are all against the current working tree.

---
*Game-Tester S-tier audit - run vs live working tree, 2026-08-27.*
