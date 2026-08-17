# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-25 (Skill Leveling) shipped and merged — PR #38, squash-merged,
104/104 tests pass. SkillManager's add_xp() is now the shared event hook
the five activity sub-issues should emit into. Idle between epochs — next
pull should be one of the now-unblocked tasks below.

No open PRs from the parallel session this epoch; Step 0 discovery found
no new GitHub issues beyond what's already tracked.

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
* PR #38 (merged): ENG-25 — SkillManager (shared XP hook, level curve,
  QuestManager.evaluate_skill_level() now has a caller).

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull:
- ENG-13/14/15/16/17 (Agriculture/Ranching/Fishing/Mining/Foraging) are
  READY_FOR_PM and now have both TimeManager (day/season) and SkillManager
  (add_xp hook) to build against — no more foundational systems blocking
  them. Whoever picks these up should call SkillManager.add_xp("Farming",
  amount) for Ranching activities too, not a separate skill (see #25's PR
  for why).
- ENG-23 (Tool Upgrades) and ENG-24 (Infrastructure Upgrades) remain
  READY_FOR_PM — need quest content decided (flagged in prior epochs, not
  yet picked up by any squad).
- ENG-20 (Marriage), ENG-21 (Festivals), ENG-26 (intro hook) remain
  READY_FOR_PM, untouched.

## Cross-Squad Requests
* UX-GRID landed this epoch (design/art/isometric-grid-spec.md, PR #39) —
  ENG-13/14/16/17 have no structural blockers left at all now. Whoever
  picks these up next should read that doc's §3 (coordinate transform)
  before writing environment placement code.
* No WeatherManager exists yet, but NPCSchedule has a weather field ready
  for one (from #18).
