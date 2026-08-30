# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IN_PROGRESS</current_status>
  <active_task_id>PO-16BIT-CORE-1</active_task_id>
  <sprint_completion_percentage>70</sprint_completion_percentage>
</squad_metadata>

## Current Focus — PO-16BIT-CORE-1 (AGENT 1: CORE) Sprint 1-2

Claimed PO-16BIT-CORE-1 on feat/16bit-redesign. Delivering deterministic 16x16 farming sim:

- SoilState 8-state enum (dry_grass, tilled_dry, tilled_watered, planted, harvestable, withered, blocked_rock, blocked_wood) in FarmPlotManager.SoilState + per-tile metadata get_tile_metadata() {soilState,cropType,growthStage,daysWatered,daysWithoutWater}. Daily tick at midnight: watered→dry, crop advances only if watered prior day, withers if >2 days dry. Backward compat: get_plot/plant/water/harvest signatures unchanged, existing 7 crops + 4 new keep old saves valid.
- New crops Turnip 4d, Radish 5d, Eggplant 7d, Strawberry multi-harvest (6d + 3d regrow) added alongside existing roster.
- Tools: Hoe till() dry_grass→tilled_dry, Watering Can water()/water_area() 1x1/1x3, Sickle use_sickle() on withered, Axe/Hammer clear_blocked() for wood/rock, Seed Bags via buy_seed()/plant(). All tool paths call StaminaManager.spend() (2/1/2/4 stamina).
- Stamina 100 max: stamina_changed, collapsed/passed_out, get_movement_speed_multiplier() 0→0.5x, restore_full() on TimeManager.day_started.
- Time 4x30d seasons, 1 real sec=1 min, 06:00-24:00 (midnight rollover to 06:00), ShippingBin payout at 06:00 via day_started hook.

Files touched this sprint: scripts/farming/farm_plot.gd (soil_state sync + save compat), scripts/autoload/farm_plot_manager.gd (enum, till/water_area/sickle/axe, new crops, wither+watered→dry tick), scripts/autoload/stamina_manager.gd (speed multiplier, collapse, daily restore, persistence), scripts/autoload/time_manager.gd (30d, 1.0 min/sec, midnight end), scripts/autoload/shipping_bin_manager.gd (unit_price, payout on day_started, persistence). Verified godot --headless --import parses (farm_plot_manager clean; pre-existing festival_manager warnings unchanged, not introduced here). No existing get_plot/plant/water/harvest contract broken.

## DONE — Sprint 4 S4-B1 (issue #97)
sell_item() silently destroyed stock when unit_price <= 0 (bin drops the
shipment after inventory already removed it). Fixed in
scripts/autoload/inventory_manager.gd: reject up front, return false, no
signal/state change, matching remove_item's failure pattern. No registry or
clamping (#96 untouched). +3 tests; suite ALL PASSED (983 checks), Godot 4.3
headless. PR gritui/story-of-country-side#103 squash-merged as 0e6d109.

## Epoch 32 update (Producer session)
Step 0: no new GitHub issues (#52/#53/#1 unchanged), no open PRs.
squad-handshake-content.md/-frontend.md/-qa.md all read fresh -- nothing
new to react to there. Picked up a real gap Writer/Dialogue Designer's
PR #78 (issue #53) had flagged but correctly declined to build around:
RelationshipManager.heart_event_triggered fires with no dialogue table
behind it, and FestivalDefinition has no flavor-text field -- both are
Resource-schema/logic changes, not Content lane's value/string-only
scope. Shipped just the plumbing (register_heart_event_dialogue()/
get_heart_event_dialogue(), FestivalDefinition.flavor_text), no
narrative content written. PR: gritui/story-of-country-side#82
(squash-merged). 929/929 tests pass (8 new), verbose run confirms zero
leak warnings, clean smoke boot. See backlog-inbox.md's Epoch 32 entry
for the full trail. Content/Writer-Squad can now write real dialogue/
flavor text against this whenever they pick it up next.

## Epoch 31 update (Producer session)
Step 0: no new GitHub issues (#52/#53/#1 unchanged), no open PRs. Picked
up QA-Tester's epoch 3 fix-forward finding: a residual AudioManager SFX
leak (narrower than the one this session already fixed in epoch 30).
Shipped PR #80 (squash-merged): natural-completion release via a
token-guarded SceneTreeTimer, plus a new public `stop_sfx()` API the
tests now use for deterministic cleanup. 921/921 tests pass, verbose run
confirms zero ObjectDB leak warnings, clean smoke boot. See
backlog-inbox.md's Epoch 31 entry and squad-handshake-audio.md for the
full trail.

## Epoch 30 update (Producer session)
Step 0: no new GitHub issues (#52/#53/#1 unchanged). Found two open,
tested-but-unmerged PRs whose originating sessions had both hit their
5-hour rate limit right after opening them: PR #74 (Frontend, Community
Goal contribution UI) and PR #75 (new Audio-Squad, AudioManager
autoload). Downloaded Godot 4.3-stable headless into this session's
scratchpad (not preinstalled in this environment) to verify both for
real rather than trust the PR descriptions.

PR #74: verified clean, 848/848 tests pass, squash-merged.

PR #75: verified 850/850 tests pass, but `--verbose` surfaced a real
leaked `AudioStreamGeneratorPlayback` -- `_start_music_loop()`/
`_start_one_shot_tone()` reassign the player's stream and call `play()`
again without stopping any still-playing prior stream first. Fixed
directly (small, well-scoped, this session's own standing Backend/
Engineer authorization), re-verified clean, resolved one real
`tests/test_runner.gd` merge conflict against the moving base (pure
append, kept both sides), squash-merged. See backlog-inbox.md's Epoch 30
entries and squad-handshake-audio.md for the full trail.

Final combined base-branch state re-verified once more after both
merges: 874/874 tests pass, clean smoke boot.

## Epoch 29 sync (Producer session)
Confirmed the epoch 28 nudge worked: Frontend-Squad's session recovered
from its failed state, shipped PR #73 (Infrastructure cost display +
automation devices UI, 824/824 tests, closes both epoch-26 Cross-Squad
Requests), and is now actively building the Community Goal contribution
UI on branch frontend/community-goal-overlay (session confirmed RUNNING,
not idle). Step 0: still just #52/#53/#1 open, nothing new. No genuine
unblocked Backend/Engineer task this cycle either -- nothing further for
this session to do beyond confirming the nudge landed and posting the
standup (STANDUP.md).

## Epoch 28 update (Producer session)
Step 0 found no new open GitHub issues (#52/#53/#1, unchanged). No open
PRs. No genuine unblocked Backend/Engineer task this epoch -- both
Cross-Squad Requests from epoch 26 are already closed via PR #72. Spent
this epoch on pure Producer/sequencing duty: see backlog-inbox.md's
Epoch 28 note and squad-handshake-frontend.md's Epoch 28 note for the
Frontend-Squad nudge (its session had genuinely failed mid-response, not
just idle between epochs).

## Epoch 26 update
Shipped PR #72 (squash-merged): closed two Cross-Squad Requests
Frontend-Squad flagged in its own epoch 24 notes -- InfrastructureManager
getters (get_house_tier_definition/get_coop_tier_definition/
get_machine_recipe/get_automation_device_definition) so
InfrastructureOverlay can show real cost numbers instead of only
yes/no gating, and CommunityGoalManager.list_bundle_ids()/
get_bundle_definition() so a Community Goal contribution UI can read
live bundle content instead of risking a stale hardcoded copy. All
read-only getters, no logic changes. 815/815 tests pass, clean smoke
boot. Commented on #52 confirming both requests closed -- this is the
second consecutive epoch of picking up genuinely useful Backend-scoped
work surfaced by another squad rather than the leaf-task backlog itself
(which has been empty since epoch 23's WeatherManager).

## Epoch 25 update
Shipped PR #71 (squash-merged): three Infrastructure automation devices
(sprinkler_system/auto_feeder/collection_hub) closing a real gap
QA-Tester's epoch 2 review found -- Decision C (#4)'s resolution named
these explicitly as Infrastructure Upgrades' scope, but PR #50 shipped
none of them. Gated same as house/coop/artisan (quest-unlock +
material/gold), wired to actually run daily via TimeManager.day_started.
Added two small Backend-to-Backend public getters
(FarmPlotManager.get_all_positions(), AnimalManager.get_all_animal_ids())
rather than reaching into private state. 802/802 tests pass, clean smoke
boot. Commented on PR #50 and issue #4 confirming the gap is closed.

## Epoch 23 update
Shipped WeatherManager via PR #62 (squash-merged) -- a genuine Backend
task, not Content or Frontend: NPCScheduleEntry.weather has been dead
scaffolding since #18, and issue #52 itself flags "no WeatherManager
exists yet" as a gap. Daily Sunny/Rainy roll (Snowy replaces Rainy in
Winter) on TimeManager.day_started, public getter/signal, save-persisted
(unlike FestivalManager, weather is genuinely mid-day state, not fully
date-derivable). Wired npc_controller.gd to pass real weather into
NPCSchedule.get_target_for() instead of the implicit "Any" default.
671/671 tests pass (new weather + NPCScheduleEntry.matches() weather-
gating tests, previously untested), clean smoke boot. This unblocks a
future HUD weather icon (Frontend scope, not built here) and makes any
weather-gated schedule content actually functional for the first time.

## Epoch 21 note (this session, PM/Backend)
Repo owner asked to let the dedicated Content-Squad work Content, rather
than this session (Backend/PM) picking up Content-lane sub-scopes as it
did in epochs 17/20 (Marriage roster PR #55, Community Goal bundles
PR #60). Released the remaining Festival/Infrastructure sub-scope claim
on issue #53 back to Content-Squad. This session goes back to pure
Backend/PM duties: Step 0 discovery, sequencing, unblocking, and any
genuinely Backend/logic work (like PR #59's gift-preference lookup below)
— not Content-lane value/string work, even when the backend leaf-task
backlog is empty.

## Epoch 19 update
Shipped a small, surgical Backend task via PR #59 (squash-merged):
`RelationshipManager.give_gift_by_npc_name(npc_name, item_id) -> bool`
looks up each NPC's real GiftPreferenceTable from PR #58's six .tres
files, closing that PR's flagged wiring gap. Backward-compatible —
existing give_gift() signature untouched. Verified independently:
514/514 checks pass, clean smoke boot.

## Current Focus
Epoch 14 (this session): ENG-24 (Infrastructure Upgrades, PR #50), ENG-20
(Marriage & Family, PR #49), ENG-21 (Festivals, PR #48) all shipped by
three parallel Backend subagents — the mid-epoch dispatch hit an
infra-level API session-limit error partway through (unrelated to the
code; reset at 4am UTC) and was cleanly re-dispatched fresh after the
reset with no work lost (nothing had been pushed). Verified each merge
independently against the real engine, resolving three rounds of
expected shared-file conflicts (project.godot/save_manager.gd/
test_runner.gd, per SQUAD-SPLIT.md's pattern).

Epoch 15 (concurrent session): ENG-27 (Ultimate-goal structure) shipped
as PR #51 — CommunityGoalManager (Community-Center-style bundle/
collection goal pulling real item_ids from every activity system) + a
year-3 evaluation that's non-terminal by default and pass/fail-with-
game_over only under challenge_mode, per Decision A. 438/438 tests
passed on their end post-merge.

**Backend leaf-task backlog is now fully DONE**: ENG-13/14/15/16/17 (five
activity systems), ENG-18/19 (NPC routines/relationships), ENG-20
(Marriage), ENG-21 (Festivals), ENG-22 (Shipping bin), ENG-23 (Tool
upgrades), ENG-24 (Infrastructure), ENG-25 (Skills), ENG-26 (Opening
hook), ENG-27 (Ultimate goal), ENG-31 (Quests). A QA-Tester squad from
the concurrent session has also become active (see squad-handshake-qa.md
— retroactive review of merged PRs). Next epoch: run Step 0 issue
discovery against GitHub for anything not yet represented here before
assuming the backend backlog is empty.

## Prior epoch (12/13, settled): ENG-14 (Ranching, PR #43), ENG-17 (Foraging,
PR #44), and ENG-15 (Fishing, PR #45 — this session/"Session B") all
shipped. ENG-14 had a same-issue claim collision with a concurrent
session (see backlog-inbox.md's Epoch 12 coordination note) — claim
comments reduce but don't eliminate the race window, the real backstop is
the pre-PR fetch/merge/re-test step. ENG-15 avoided any collision by
checking for other claims immediately before dispatch, not just at epoch
start. A parallel Frontend/Squad B subagent was also building the first
real HUD scene against design/ui-flows/menu-hud-flow-spec.md — logged in
squad-handshake-frontend.md, not this file; not this squad's concern to
track further. Idle between epochs — next pull should be one of the
now-unblocked tasks below.

## Prior epoch (11)
ENG-13 (Agriculture) and ENG-26 (Opening hook) both shipped —
PR #42 and PR #41, 208/208 tests pass (independently re-verified against
the real merged base branch). InventoryManager now exists
(scripts/autoload/inventory_manager.gd) as a general item_id->quantity
ledger — Ranching/Fishing/Mining/Foraging should consume it directly
rather than invent their own. SaveManager gained real disk persistence
(user://savegame.json) via ENG-26. Both PRs touched save_manager.gd and
test_runner.gd concurrently (expected, additive — SaveManager growing two
independent extensions); resolved as a real merge conflict, see
backlog-inbox.md's Epoch 11 coordination note for how that was
reconciled with a concurrent session that merged PR #42 mid-resolution.
Idle between epochs — next pull should be one of the now-unblocked tasks
below.

## Recent Commits / PRs
* PR #51 (merged, this session): ENG-27 — CommunityGoalManager/
  BundleDefinition: Community-Center-style bundle/collection goal reusing
  real item_ids from every activity system, contribute_item() pulling
  from InventoryManager with clamping, and a year-3 evaluation
  (non-terminal by default, pass/fail + game_over under challenge_mode).
* PR #47 (merged, this session as Session B): ENG-16 — MiningManager/
  OreDefinition (procedural 5x5 floors, rock-breaking, ore/gem gathering,
  ladder descent). Reuses ToolManager's iron_ore/gold_ore item ids.
  344/344 tests pass.
* PR #45 (merged, this session as Session B): ENG-15 — FishingManager/
  FishDefinition (season/time/location fish pools, attempt_catch()
  pass/fail contract for a future mini-game). 285/285 tests pass.
* PR #44 (merged, concurrent session, verified independently): ENG-17 —
  ForagingManager/ForageableDefinition/ForageNode (gather nodes, respawn
  cooldown).
* PR #43 (merged, concurrent session, verified independently): ENG-14 —
  AnimalManager/AnimalDefinition/Animal (feed/brush/harvest loop).
* PR #41 (merged): ENG-26 — Opening hook intro sequence, SaveManager
  disk persistence (new_game/save_game/load_game).
* PR #42 (merged): ENG-13 — Agriculture (FarmPlotManager/CropDefinition/
  FarmPlot) + general InventoryManager autoload.
* PR #32 (merged): ENG-12 — Godot project bootstrap, TimeManager/
  StaminaManager/SaveManager autoloads.
* PR #33 (merged): ENG-18 — NPCScheduleEntry/NPCSchedule + NPCController.
* PR #28 (merged, parallel session): UX-FLOW-01 — menu/HUD flow spec.
* PR #34 (merged, parallel session, verified independently): ENG-19 —
  RelationshipManager + GiftPreferenceTable.
* PR #36 (merged): ENG-22 — ShippingBinManager (wallet, overnight payout,
  pass-out penalty consumer).
* PR #37 (merged): ENG-31 — QuestManager/QuestCondition/QuestDefinition.
* PR #38 (merged): ENG-25 — SkillManager (shared XP hook, level curve).
* PR #39 (merged, this session as UX-UI squad): UX-GRID — isometric grid
  spec (design/art/isometric-grid-spec.md).
* PR #40 (merged): ENG-23 — ToolManager/ToolUpgradeTier (per-tool
  Copper->Iron->Gold, deliberately no quest gate).
* PR #50 (this session): ENG-24 — InfrastructureManager
  (house expansion, coop/barn capacity via get_max_animal_capacity()
  integration point, artisan machines keg/preserves_jar/mayo_machine),
  quest-gated per Decision C via QuestManager.is_unlocked() +
  ShippingBinManager.spend()/InventoryManager.
* PR #49 (merged, this session): ENG-20 — MarriageManager: marriage-eligible
  NPC list, propose()/marry() state machine gated on RelationshipManager
  hearts + a proposal item consumed via InventoryManager, a wedding-prep
  day countdown, a minimal daily-gold-bonus post-marriage benefit, and a
  season-start child-chance roll.
* PR #48 (merged, this session): ENG-21 — FestivalManager: date-driven
  seasonal events reusing TimeManager's freeze mechanism, generic
  submit_mini_game_result() contract for a future mini-game scene.
* PR #47 (merged, concurrent session): ENG-16 — MiningManager: procedural
  floors, rock-breaking, ore/gem gathering, ladder descent.

## Blockers & QA Failures
None currently blocking. All known backend leaf tasks (ENG-13 through
ENG-27, ENG-31) are shipped as of PR #51. Next epoch's job is Step 0
issue discovery on GitHub — check for any new issue opened since this
update (frontend polish, cross-squad integration work, or a genuinely new
system) before declaring the backlog empty.

## Cross-Squad Requests
* No WeatherManager exists yet, but NPCSchedule has a weather field ready
  for one (from #18).
* HUD binding conventions are in design/ui-flows/menu-hud-flow-spec.md
  (PR #28) — §2 already references gold (via ShippingBinManager) and
  stamina (from #12) as HUD-bound state; could extend to tool tier display.
* Isometric grid math is in design/art/isometric-grid-spec.md (PR #39) —
  ToolManager's AoE offsets use this coordinate system directly.


## DONE — S4-B2 (#90 festival lost on quit+relaunch)
* Fixed via pure backend re-derivation: `FestivalManager.rederive_active_festival()` (PR #104, squash-merged), called from `SaveManager.apply_save_data()`/`new_game()`; no new save fields.
* Audit note (per #90 AC): any future autoload deriving state solely from `day_started` needs the same boot-time rederivation — none currently do besides FestivalManager.

## Sprint 1 — ENG-91 DONE (seed economy)
Fixed the "planting is free & infinite" gap from issue #91: `CropDefinition`
gains `seed_price`; `FarmPlotManager.plant()` now requires and consumes a
real `"<crop_id>_seed"` InventoryManager item instead of being a pure
season/empty-plot check; `FarmPlotManager.buy_seed(crop_id, quantity)` is
the smallest-viable purchase path (spends gold via
`ShippingBinManager.spend()`, credits `InventoryManager` directly, no new
autoload); `SaveManager.new_game()` calls the new
`FarmPlotManager.grant_starting_seeds()` (8 parsnip seeds) alongside the
existing `STARTING_GOLD` grant, so day 1 has a real plant-vs-ship choice.

Every existing test that called `FarmPlotManager.plant()` directly needed
updating to stock a seed first (`_grant_seed_for_test()` helper added) --
the inventory-gated contract is a real behavior change, not just additive.
+17 new tests covering the seed-gated plant contract, `buy_seed()`
happy/failure paths, and the starting-grant. 1009/1009 tests pass (up
from 992 on base), verified headless via Godot 4.3-stable (downloaded
fresh into this session's scratchpad, matching `project.godot`'s engine
version) — re-ran against the unmodified base branch first to confirm the
992-check baseline and that the pre-existing `ObjectDB leaked at exit`
warning / stray error lines are unrelated pre-existing noise, not
introduced by this change. Backend-only (`scripts/autoload/**`,
`scripts/farming/**`) per SQUAD-SPLIT.md, no scenes/UI touched.

PR: gritui/story-of-country-side#122 (branch
`feature/eng-91-seed-economy`).

Follow-up gaps flagged in the PR description rather than built here:
no shop/purchase UI hook exists yet for `buy_seed()` (a Frontend/UI task
once claimed); `seed_price` values are a documented ratio-of-sell-price
heuristic, not a real playtested balance pass -- Content lane's job per
the issue's own AC.

## Recent Commits — PO-16BIT-CORE-1 (feat/16bit-redesign, not yet PR)

* `scripts/farming/farm_plot.gd:15` — Added soil_state/days_watered/days_without_water/blocked_type + save compat (soil_state, daysWatered, daysWithoutWater) while aliasing cropType→crop_id, growthStage→days_grown for the {soilState,cropType,growthStage,daysWatered,daysWithoutWater} metadata contract.
* `scripts/autoload/farm_plot_manager.gd:12` — SoilState 8-state enum + SOIL_STATE_NAMES, till()/water_area() 1x1/1x3, set_blocked()/clear_blocked() (Axe/Hammer), use_sickle(), get_tile_metadata()/get_soil_state(), updated plant/water/harvest to maintain soil_state, new crops turnip/radish/eggplant/strawberry (4/5/7d, strawberry regrow 3d), daily tick watered→dry, advance only if watered prior day, wither if daysWithoutWater>2, stamina hooks via StaminaManager.spend().
* `scripts/autoload/stamina_manager.gd:1` — 100 max, spend()→passed_out/collapsed, get_movement_speed_multiplier() 0→0.5x, restore_full() on day_started, to_save_dict/from_save_dict, daily restore hook.
* `scripts/autoload/time_manager.gd:12` — DAYS_PER_SEASON 28→30, MINUTES_PER_REAL_SECOND 7.0→1.0 (1 sec=1 min), DAY_END_HOUR 2→24 with midnight (hour 0) rollover to 06:00, preserves freeze/sleep API.
* `scripts/autoload/shipping_bin_manager.gd:1` — ship_item() now unit_price-aware, process_payout() at 06:00 via TimeManager.day_started, gold persistence.
