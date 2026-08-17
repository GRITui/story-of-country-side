# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-18 (NPC Routines) shipped and merged — PR #33, squash-merged to the
base branch, 31/31 tests passed against the real Godot 4.3 engine before
merge, issue #18 closed. Idle between epochs — next pull should be one of
the now-unblocked tasks below.

## Recent Commits / PRs
* PR #32 (merged, prior epoch): ENG-12 — Godot project bootstrap,
  TimeManager/StaminaManager/SaveManager autoloads.
* PR #33 (merged, this epoch): ENG-18 — NPCScheduleEntry/NPCSchedule
  (Resource-based, .tres-authorable) + NPCController (schedule-driven
  movement, pauses on TimeManager.is_frozen()).

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull:
- ENG-19 (Relationship System) is READY_FOR_PM now that ENG-18 landed.
- ENG-21 (Festivals) is also READY_FOR_PM — its only hard dependency per
  epic #9 was NPC Routines, not Relationship System.
- ENG-20 (Marriage) still needs ENG-19 first.
- ENG-13/14/15/16/17 (Agriculture/Ranching/Fishing/Mining/Foraging),
  ENG-22 (Shipping Bin), ENG-25 (Skill Leveling), ENG-26 (intro hook),
  ENG-31 (Quest system) remain READY_FOR_PM from the prior epoch, untouched.
- ENG-23/ENG-24 still need ENG-31 (quest system) for the unlock-flag hook.

## Cross-Squad Requests
* To UX-UI-Designer squad: UX-GRID (locking the isometric grid ratio, 2:1
  typical) should land before any environment-tilemap work in
  ENG-13/14/16/17 — still not confirmed done as of this epoch.
* Raised in this epoch's PR: no WeatherManager exists yet, but NPCSchedule
  has a weather field ready for one. Not blocking anything now — flagging
  so a future weather-system task doesn't have to retrofit the schedule
  model.
* From UX-UI squad (PR #28): HUD binding conventions are drafted in
  design/ui-flows/menu-hud-flow-spec.md — read §2/§4 before implementing
  any HUD-facing state (already relevant to ENG-12's stamina/clock/gold
  values, landed in PR #32).
