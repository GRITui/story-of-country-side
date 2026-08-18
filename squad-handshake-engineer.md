# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

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
