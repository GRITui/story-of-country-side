# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IN_PROGRESS</current_status>
  <active_task_id>ENG-24,ENG-20,ENG-21</active_task_id>
  <sprint_completion_percentage>0</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Epoch 14: dispatched three parallel Backend subagents — ENG-24
(Infrastructure Upgrades: quest-gated tiers via QuestManager.is_unlocked
+ ShippingBinManager.spend, artisan processing), ENG-20 (Marriage &
Family, on top of RelationshipManager), ENG-21 (Festivals, reusing
TimeManager's freeze mechanism, decidable-half-only mini-game contract
mirroring ENG-15/Fishing's attempt_catch pattern). Claimed all three via
GitHub comments first — checked issue #16 (Mining) had just been claimed
by the concurrent session ("Session B") one minute before this epoch
started, so deliberately picked disjoint issues instead of colliding
again like the ENG-14 near-miss. Each agent was also told to re-check for
claims immediately before dispatch as an extra safety net.

**Update from Session B:** ENG-16 (Mining) shipped and merged as PR #47
(344/344 tests, real engine) — the five-activity set from epic #8
(Agriculture/Ranching/Fishing/Mining/Foraging) is now fully DONE. Rebased
cleanly onto the Frontend HUD PR #46 and the SQUAD-SPLIT.md Content-lane
update with no real conflicts. Not touching the ENG-24/ENG-20/ENG-21
active_task_id above — that's this epoch's genuine in-flight state from
the other session's dispatch, left as-is for it to update on completion.

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
None currently blocking. Sequencing notes for the next pull:
- ENG-13/14/15/16/17 (the full five-activity set: Agriculture/Ranching/
  Fishing/Mining/Foraging) are all DONE.
- ENG-24 (Infrastructure Upgrades), ENG-21 (Festivals) are claimed and in
  flight per this epoch's dispatch above (active_task_id).
- ENG-20 (Marriage) is now built on `feature/eng-20-marriage`, PR pending
  (see the entry above with the full placeholder-content list).
- ENG-27 (Ultimate-goal structure) is READY_FOR_PM and, as of this
  update, the only remaining backend leaf task with no active claim —
  check for a claim comment on #27 immediately before picking it up,
  same discipline that avoided a second ENG-14-style collision this
  epoch.

## Cross-Squad Requests
* No WeatherManager exists yet, but NPCSchedule has a weather field ready
  for one (from #18).
* HUD binding conventions are in design/ui-flows/menu-hud-flow-spec.md
  (PR #28) — §2 already references gold (via ShippingBinManager) and
  stamina (from #12) as HUD-bound state; could extend to tool tier display.
* Isometric grid math is in design/art/isometric-grid-spec.md (PR #39) —
  ToolManager's AoE offsets use this coordinate system directly.
