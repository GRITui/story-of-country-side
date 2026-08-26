# Super User Report — Sprint 003

- **Date:** 2026-08-26
- **Tested at:** base branch @ 78fa37e (parity first: **962/962** checks pass,
  clean smoke boot — so every finding below is new signal, not drift)
- **Method:** retailer-lens business-use-case simulation of the whole economy
  loop (sell side = shipping bin, buy side = gold sinks). New permanent
  harness `superuser/autoplay/RetailSimDriver.tscn`, public APIs only,
  same reach a player-facing shop UI has. Re-run:
  `godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase retail`
  → **21 checks, 19 pass, 2 fail** (both one bug class).

## What works end-to-end (verified)

Sell happy-path (stock → bin → overnight payout) with exact multi-line
math (350g + 48g + 30g = 428g settled once, exactly); oversell rejected
with ledger untouched; empty-item-id rejected; save/reload mid-day keeps
gold AND pending shipments byte-exact (phantom post-save lines correctly
cannot survive reload); failed tool purchases never consume ore first
(two-gate ordering held under short-gold); spend() rejects 0/negative.
Buy-side retail loop is in noticeably better contract shape than sell-side.

## Findings (filed as issues this sprint)

### #97 — P1 blocker: `sell_item()` silently destroys stock at price ≤ 0
`InventoryManager.sell_item("x", n, 0)` returns **true**, removes all n
units from inventory, and ships nothing — `ShippingBinManager.ship_item()`
silently no-ops on its own `unit_price <= 0` guard after the stock is
already gone. Cross-autoload guard mismatch; goods unrecoverable.
Latent today (no sell UI yet) but sits directly on #91's seed-shop path.
Repro + damage printout in the driver run log; fix is a one-line front
validation in `sell_item()` plus the missing zero-price test case.

### #96 — P2 feature: canonical price registry
" What does this sell for?" currently has three disconnected answers:
`CropDefinition.base_sell_price` (normal ids only), quality-multiplier
constants inside FarmPlotManager, or caller-supplied `unit_price` with no
table behind it. No public lookup for `"parsnip_silver"` exists; every
future vendor screen must re-invent multiplier math. Ask: read-only
`EconomyRegistry` lookup for sell/buy prices, data-first per SQUAD-SPLIT's
content lane; unblocks #91 buy prices too.

### #98 — P3 feature: nightly sale receipt/history
Payout emits aggregates only; per-line detail dies at settlement and is
never serialized. Foundation ask for a genre-standard morning sales
summary — cheap now, annoying after artisan/festival payouts also route
through the bin.

## Positive design notes
Pending-shipment persistence is exactly right (raw lines survive
save/reload and still pay exactly once — the festival #90 boot-gap does
NOT afflict the bin). Two-gate purchase ordering is consistently correct
across ToolManager and InfrastructureManager.

---

## Addendum (same day): embodiment triage — avatar / controls / NPCs

Follow-up tester pass asked "do we need main character, controls, other
NPCs?" Verified against HEAD before answering:

- `project.godot` has NO `[input]` section — zero registered actions;
  all interaction is raw mouse clicks + overlay buttons.
- No player representation anywhere (no CharacterBody2D/avatar/sprite).
- `NPCController` (with sprite, schedule consumption, name tint) is
  instantiated only by tests — never in any world scene. Schedules,
  relationships, gifts, festivals are all backend-done yet invisible.

Verdict: YES to all three; each is a missing core affordance, not polish.
Filed as issues this cycle:

- #100 P2 enhancement: player avatar in world scenes (minimal v1:
  placeholder sprite, facing, tool-swing feedback; no physics/anim sets)
- #101 P2 enhancement: control scheme + input map (named actions:
  move/interact/advance_dialog/hotbar keys; mouse-click stays primary;
  explicitly NO combat inputs per Decision B)
- #102 P2 enhancement [area:social]: instantiate NPCs in world scenes
  driven by existing schedules — zero new backend or art required

Sequencing recommendation: #101+#100 land together (embodiment layer),
then #102 reuses it. Anti-recommendation recorded for PM: do NOT add
combat controls/enemy AI scope when triaging these.

---

## Addendum 2 (same day): world expansion + game-design assessment

Asked to assess (a) multiple themed maps — country-side plus mountain
and sea, (b) overall game design, (c) bundling a simple starting quest
for new players. Findings, all verified at HEAD:

- World today = ONE biome wearing four name tags:
  LOCATION_SCENE_PATHS has 4 flat same-palette grids; MapOverlay
  self-documents as "four flat buttons, no zones".
- Multi-map feasibility is HIGH: scene-swap architecture extends by
  dictionary entry; procedural_tile_art.gd is location-agnostic
  (biome palettes are generation params); FishingManager already
  registers sea fish (tuna/sardine/squid/eel/sturgeon) against abstract
  location strings — sea content exists with no sea to stand on.
- Quest audit: QuestManager's condition engine is proven (10 signal-
  evaluated quests) but ALL TEN are late-game InfrastructureManager
  automation unlocks. Zero day-one guidance exists anywhere. Combined
  with #91 free planting, #93 171s days, no avatar (#100): the first
  hour is aimless idling.

Filed this cycle:
- #106 [epic] three-biome world expansion (valley/mountain/sea)
- #105 [P2] Sea coast map + pier fishing (ocean pools get a home)
- #107 [P2] Mountain region map (mine entrance gets a mountainside)
- #108 [P2 area:economy] Starter quest chain ship→earn→befriend→explore;
  steps 1-3 buildable TODAY against shipped systems; only backend ask is
  one small EARN_GOLD condition type (~10 lines, existing pattern);
  deliberately no seed step until #91 lands.

Design-health snapshot for PM: systems layer complete and verified;
experience-layer gaps now fully ticketed and ranked — embodiment
(#100-102), economy input cost (#91), new-player onboarding (#108),
world variety (#105-107). No untriaged design gaps known to this seat.

---

## Addendum 3 (same day): BTN competitive gap analysis

Asked to assess competing with retro farm-sims (Harvest Moon: Back to
Nature) and file the worth-building gaps. Full audit against HEAD:

ALREADY CREDIBLE (verified, do not rebuild): all five activity loops,
5-species ranching, artisan machines, tool tiers, festivals+minigame,
community goals, and a backend marriage system deeper than expected
(mermaid_pendant proposal @8 hearts, 3-day engagement, children,
spousal bonus). Structural advantages over retro originals: every
economy path test-covered (962 checks) and deliberately open-ended
cozy pacing (Decision A; challenge_mode exists for the deadline crowd).

BIGGEST SURPRISE: the romance endgame is unreachable — mermaid_pendant
has no source anywhere in the game; proposal/wedding fire as silent
state changes with zero presentation.

Filed this cycle (the missing emotional-payoff layer):
- #109 [P2 area:economy] Cooking & eating — recipes -> StaminaManager
  restore(); kitchen gated on House Tier 2; artisan goods gain a
  second use. No hunger system.
- #110 [P2 area:social] Villager birthdays + calendar overlay —
  "birthday" appeared nowhere in scripts/; fields go into existing
  GiftPreferenceTable resources (Content lane); gift multiplier small.
- #111 [P2 area:social] Present the marriage loop — obtainable pendant
  source, heart-event cutscenes via IntroSequence pattern, propose
  button + wedding moment.
- #112 [P3 area:agriculture] Weather depth — rain auto-waters (docstring
  flags it absent), rare storm default-harmless, tomorrow forecast in HUD.
- #113 [P3] Real seasonal music — replace sine drone; sourcing under
  ATTRIBUTION.md norms; festival jingle folded in from Audio-Squad thread.
- #114 [P4 idea] Pet companion — pure charm, only after avatar lands.

ANTI-RECOMMENDATION on record for PM: do NOT chase BTN's sprite/art
volume or its 3-year eviction stress mechanic (contradicts Decision A);
compete on systems correctness, coziness, and modern UX instead.

Sequencing suggestion: embodiment cluster first (#100/#101/#102), then
#111 + #110 (social payoff), with #109/#112/#113 as texture passes.

---

## Addendum 4 (same day): genre benchmark + SCAMPER roadmap decision

Benchmarked against genre leaders (SDV = content depth + modding moat;
Fields of Mistria = juice over features; SoS = seasonal rhythm; Roots of
Pacha = co-op niche DEFERRED; Graveyard Keeper = theme coherence, not
our path; Littlewood = friction-removal-as-feature). Conclusion: S-tier
wins on rhythm/feel/retention, not mechanics — and mechanics are this
repo's proven strength. Spend almost entirely on the experience layer.

SCAMPER outputs filed:
- #116 [P3] skill milestone perks (Combine; idle level_changed hook)
- #115 [P3 area:social] Winter festival + minigame variety (Magnify;
  verified Winter has zero festivals)
- #117 [P3] collection journal (Put-to-other-use of discovery data)
- #118 [P3] multi-slot saves (Eliminate single-save anxiety; REQUIRED
  before shipping #92's destructive New Game)
- #120 [needs-decision] soften pass-out gold penalty (Eliminate; tester
  lean option c — reduced stamina next day, evaluated after #109)
- #119 [P4 idea] modding-lite content packs (Adapt SDV moat; file now
  because #96/#108/#110/#116 are choosing data shapes NOW — reserve the
  seam free, build far-future)

Rejected by SCAMPER for v1 (recorded so they don't resurface silently):
dynamic NPC shop pricing (enabled later by #96 anyway), quest-gated
biome travel (contradicts openness), co-op multiplayer (different era of
cost), combat anything (Decision B).

ROADMAP DECISION (phases, exit criteria in superuser report):
P0 Trust: #97 + parity green. P1 Feel: #92/#93/#94/#100/#101/#102.
P2 New-player arc: #108/#91/#96/#98. P3 Season rhythm+payoff:
#110/#111/#115/#112/#109. P4 Retention/longevity: #105-107 world,
#113/#116/#117/#118; decide #120; reserve #119 seams.
S-TIER BAR (measurable): zero open P0/P1; first-payout inside ~15 real
minutes via starter chain; no shipped system invisible on screen;
festival+birthday present every season; journal+perks live; cozy
friction floor met (sleep-skip, rain relief, multi-slot).




