# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-23 (Tool Upgrades) shipped and merged — PR #40, squash-merged,
131/131 tests pass. Scope was discussed with the owner before building:
kept quest-free (QuestManager stays reserved for #24's automation tiers,
not core tool progression — Decision C's quest-gating was aimed at
automation, not basic upgrades), per-tool not global (Hoe/WateringCan/
Axe/Pickaxe independent). Idle between epochs — next pull should be one
of the now-unblocked tasks below.

## Recent Commits / PRs
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

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull:
- ENG-24 (Infrastructure Upgrades) is READY_FOR_PM — THIS is where
  Decision C's quest-gating actually belongs (sprinklers, auto-feeders,
  collection hub behind QuestManager.is_unlocked(flag)), per ENG-23's own
  PR discussion. Needs actual QuestDefinition content chosen and
  documented, same as ENG-23/ENG-31 did.
- ENG-13/14/15/16/17 (Agriculture/Ranching/Fishing/Mining/Foraging) have
  zero structural blockers left (TimeManager, SkillManager, UX-GRID all
  shipped) and can now also consume ToolManager.get_aoe_offsets()/
  get_stamina_cost() for tool-use actions.
- ENG-20 (Marriage), ENG-21 (Festivals), ENG-26 (intro hook) remain
  READY_FOR_PM, untouched.
- No general InventoryManager exists anywhere (flagged in #40) — whoever
  builds the first activity that produces real items (#13/#16/#17) will
  hit this gap directly; ToolManager's local ore ledger is not meant to
  generalize into one.

## Cross-Squad Requests
* No WeatherManager exists yet, but NPCSchedule has a weather field ready
  for one (from #18).
* HUD binding conventions are in design/ui-flows/menu-hud-flow-spec.md
  (PR #28) — §2 already references gold (via ShippingBinManager) and
  stamina (from #12) as HUD-bound state; could extend to tool tier display.
* Isometric grid math is in design/art/isometric-grid-spec.md (PR #39) —
  ToolManager's AoE offsets use this coordinate system directly.
