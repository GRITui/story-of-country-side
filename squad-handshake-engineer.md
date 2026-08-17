# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-12 (Time & Stamina foundation) shipped and merged — PR #32, squash-merged
to the base branch, 19/19 tests passed against the real Godot 4.3 engine
before merge, issue #12 closed. Godot project now bootstrapped
(project.godot, TimeManager/StaminaManager/SaveManager autoloads,
tests/TestRunner.tscn). Idle between epochs — next pull should be one of
the now-unblocked tasks below.

## Recent Commits / PRs
* PR #32 (merged): ENG-12 — TimeManager, StaminaManager, SaveManager
  autoloads; Godot project scaffold; test harness pattern documented
  (scene-based, not `--script`, since `--script` bypasses autoload
  registration — see tests/test_runner.gd header comment).

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull (see
backlog-inbox.md Epoch 3 update for full detail):
- ENG-13, ENG-14, ENG-15, ENG-16, ENG-17, ENG-18, ENG-22, ENG-25, ENG-26,
  ENG-31 are all READY_FOR_PM now that ENG-12 has landed.
- ENG-19 still needs ENG-18 (NPC Routines) first; ENG-20 needs ENG-19;
  ENG-21 needs both ENG-12 (done) and ENG-18.
- ENG-23/ENG-24 need ENG-31 (quest system) for the unlock-flag hook before
  their automation tiers can be built.

## Cross-Squad Requests
* To UX-UI-Designer squad: UX-GRID (locking the isometric grid ratio, 2:1
  typical) should land before any of ENG-13/14/16/17 touch environment
  tilemaps — flagged from DEC-E's resolution, not yet confirmed done.
