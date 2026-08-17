# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-19 (Relationship System) confirmed merged — PR #34 (delivered by a
parallel session, squash-merged to the base branch after this session
independently re-ran its test suite: 53/53 pass against the real Godot 4.3
engine). RelationshipManager + GiftPreferenceTable live. Issue #19 closed.
Idle between epochs — next pull should be one of the now-unblocked tasks
below.

## Recent Commits / PRs
* PR #32 (merged): ENG-12 — Godot project bootstrap, TimeManager/
  StaminaManager/SaveManager autoloads.
* PR #33 (merged): ENG-18 — NPCScheduleEntry/NPCSchedule (Resource-based,
  .tres-authorable) + NPCController (schedule-driven movement).
* PR #28 (merged, parallel session): UX-FLOW-01 — menu structure & HUD
  layout logic flow spec.
* PR #34 (merged, parallel session, verified independently by this
  session): ENG-19 — RelationshipManager + GiftPreferenceTable.

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull:
- ENG-20 (Marriage) is READY_FOR_PM now — ENG-19 confirmed merged.
- ENG-21 (Festivals) is READY_FOR_PM — its only hard dependency per epic #9
  was NPC Routines (#18, merged).
- ENG-13/14/15/16/17 (Agriculture/Ranching/Fishing/Mining/Foraging),
  ENG-22 (Shipping Bin), ENG-25 (Skill Leveling), ENG-26 (intro hook),
  ENG-31 (Quest system) remain READY_FOR_PM, untouched.
- ENG-23/ENG-24 still need ENG-31 (quest system) for the unlock-flag hook.

## Cross-Squad Requests
* To UX-UI-Designer squad: UX-GRID (locking the isometric grid ratio, 2:1
  typical) should land before any environment-tilemap work in
  ENG-13/14/16/17 — still not confirmed done.
* No WeatherManager exists yet, but NPCSchedule has a weather field ready
  for one (from #18) — flagging for whenever a weather system is scoped.
* HUD binding conventions are drafted in design/ui-flows/menu-hud-flow-spec.md
  (from PR #28) — read §2/§4 before implementing any HUD-facing state.
* Coordination note: another session has been working this repo in
  parallel (see backlog-inbox.md Epoch 5). Both lines are now reconciled
  onto the same base branch — check backlog-inbox.md for the latest DONE/
  READY_FOR_PM status before picking a task, in case another session picks
  one up between epochs.
