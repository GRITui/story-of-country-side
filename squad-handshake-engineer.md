# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>EXECUTING</current_status>
  <active_task_id>ENG-19</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-19 (Relationship System) claimed and built: RelationshipManager
autoload (friendship points, once-per-day talk/gift caps, threshold-based
heart events) + GiftPreferenceTable resource. PR #34 open against the base
branch, not yet merged/reviewed. Picked as the highest-leverage next pull
since it directly continues the just-landed NPC Routines work (#18) and
unblocks ENG-20 (Marriage & Family).

## Recent Commits / PRs
* PR #32 (merged, prior epoch): ENG-12 — Godot project bootstrap,
  TimeManager/StaminaManager/SaveManager autoloads.
* PR #33 (merged, prior epoch): ENG-18 — NPCScheduleEntry/NPCSchedule
  (Resource-based, .tres-authorable) + NPCController (schedule-driven
  movement, pauses on TimeManager.is_frozen()).
* PR #34 (open): ENG-19 — RelationshipManager + GiftPreferenceTable.
  53/53 tests pass (22 new) against the real Godot 4.3 engine headless.

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull:
- ENG-20 (Marriage) is READY_FOR_PM once PR #34 merges — depends on ENG-19.
- ENG-21 (Festivals) is READY_FOR_PM now — its only hard dependency per
  epic #9 was NPC Routines (#18, already merged), not Relationship System.
- ENG-13/14/15/16/17 (Agriculture/Ranching/Fishing/Mining/Foraging),
  ENG-22 (Shipping Bin), ENG-25 (Skill Leveling), ENG-26 (intro hook),
  ENG-31 (Quest system) remain READY_FOR_PM, untouched.
- ENG-23/ENG-24 still need ENG-31 (quest system) for the unlock-flag hook.

## Cross-Squad Requests
* To UX-UI-Designer squad: UX-GRID (locking the isometric grid ratio, 2:1
  typical) should land before any environment-tilemap work in
  ENG-13/14/16/17 — still not confirmed done as of this epoch.
* Raised in PR #33: no WeatherManager exists yet, but NPCSchedule has a
  weather field ready for one. Not blocking anything now — flagging so a
  future weather-system task doesn't have to retrofit the schedule model.
* From UX-UI squad (PR #28): HUD binding conventions are drafted in
  design/ui-flows/menu-hud-flow-spec.md — read §2/§4 before implementing
  any HUD-facing state (already relevant to ENG-12's stamina/clock/gold
  values, landed in PR #32).
