# Squad Handshake — Frontend (Squad B)

<squad_metadata>
  <squad_name>Frontend-Squad</squad_name>
  <current_status>IN_PROGRESS</current_status>
  <active_task_id>FRONTEND-FARM-SCENE</active_task_id>
  <sprint_completion_percentage>0</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Epoch 18: dispatched a subagent to build the FarmPlot world/tile-rendering
scene (branch frontend/farm-plot-scene) against issue #52 — the single
biggest player-visible gap (nothing currently renders the farming loop).
Note: issue #52 got auto-closed by GitHub when PR #54 merged despite
explicit text saying to leave it open (it's tracking-only) — reopened it;
told this new subagent to avoid any closing-keyword phrasing near "#52"
in its PR body to prevent a repeat.

## Prior epoch (16): dispatched a subagent to build the pause menu + full-screen
Inventory overlay (branch frontend/pause-menu-inventory) against issue
#52 (the new tracking epic for all remaining frontend scene work, opened
once the full backend leaf-task backlog closed). This is exactly the
scope PR #46 deferred. Claimed a sub-scope on #52 via GitHub comment
first (it's tracking-only, not meant to be closed by one PR). Running in
parallel with a Content-lane subagent doing a farming/ranching/fishing/
foraging balance pass (issue #53) — disjoint files, only shared risk is
tests/test_runner.gd (expected, resolvable per SQUAD-SPLIT.md's pattern).

## Prior epoch (12): built the first real HUD scene (scenes/ui/HUD.tscn +
scripts/ui/hud.gd, new scripts/ui/ folder) against
design/ui-flows/menu-hud-flow-spec.md §2/§4, binding reactively to
ShippingBinManager.gold_changed (gold), StaminaManager.stamina_changed
(stamina bar, with a distinct pass-out visual state), TimeManager's
minute_passed/day_started (clock + date) via public signals/getters only,
per SQUAD-SPLIT.md's contract rule. Wired into scripts/story/main_controller.gd
as a CanvasLayer shown once the ENG-26 intro sequence finishes (or
immediately on a boot that's already seen it), without altering the intro
flow itself. Opened as PR #46 against claude/farming-game-pm-requirements-w9ugtk
(no single GitHub issue — flow-spec implementation work, not a numbered
backlog item). 6 new headless tests added to tests/test_runner.gd; full
suite at 252 checks passing after merging in ENG-14 Ranching (landed
concurrently; only conflict was a pure-append in tests/test_runner.gd).

Explicitly deferred as follow-up frontend work: the pause menu and the
full-screen Inventory/Map/Skills overlays (spec §1/§3) — large enough
scope to warrant their own PR. Content gaps flagged in the PR rather than
faked: no WeatherManager exists yet (weather omitted from the HUD), and
InventoryManager has no hotbar-slot/item-metadata concept yet (hotbar
ships as an empty 8-slot placeholder strip, not a real item binding).

## Recent Commits / PRs
* PR #46 (open): Frontend — always-on HUD implementation
  (scenes/ui/HUD.tscn, scripts/ui/hud.gd, main_controller.gd wiring).
* PR #28 (merged): UX-UI squad — menu/HUD flow spec (design doc, not
  implementation).
* PR #39 (merged): UX-UI squad — isometric grid spec (design doc, not
  implementation).
* PR #41 (merged): ENG-26 — IntroSequence + MainController
  (scenes/intro/IntroSequence.tscn, scripts/story/*.gd). This is the
  first real Frontend-lane code, though it landed before this squad
  split existed — logged here retroactively for continuity.

## Blockers & QA Failures
None. Nothing structural blocks a first HUD/menu scene implementation.

## Cross-Squad Requests
* To Backend squad: per SQUAD-SPLIT.md's contract rule, any state
  Frontend needs that isn't exposed via an existing signal/public method
  is a Backend task — flag it here rather than reaching into a manager's
  private fields.
