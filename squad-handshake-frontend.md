# Squad Handshake — Frontend (Squad B)

<squad_metadata>
  <squad_name>Frontend-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Epoch 16: built the pause menu + full-screen Inventory overlay
(branch frontend/pause-menu-inventory, scenes/ui/PauseMenu.tscn +
scripts/ui/pause_menu.gd, scenes/ui/InventoryOverlay.tscn +
scripts/ui/inventory_overlay.gd) against
design/ui-flows/menu-hud-flow-spec.md §1/§3 — the exact scope PR #46
deferred. Claimed the sub-scope on issue #52 via GitHub comment first
(it's tracking-only, not meant to be closed by one PR; left open).
Pause menu toggles on the built-in `ui_cancel` action, freezes
TimeManager via freeze("pause")/unfreeze("pause") (same reference-
counted mechanism festivals already use). Resume + Inventory are real;
Map/Skills/Settings ship as disabled "(not yet implemented)" stubs;
Save & Quit saves for real then quits the app outright since there's
still no title screen to return to. Inventory overlay binds reactively
to InventoryManager.item_changed, primed on _ready() by reading the
existing public to_save_dict()["counts"] snapshot (no enumeration
getter exists on InventoryManager yet — flagged as a possible future
Backend cross-squad ask below, not a private-field reach-around).
Opened as PR #54 against claude/farming-game-pm-requirements-w9ugtk.
9 new headless tests added to tests/test_runner.gd; full suite at 496
checks passing after merging the base branch in (no conflicts — the
concurrent Content-lane pass, issue #53, touched only the handshake
docs on the base branch by the time this PR opened).

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
* PR #54 (open): Frontend — pause menu + full-screen Inventory overlay
  (scenes/ui/PauseMenu.tscn, scripts/ui/pause_menu.gd,
  scenes/ui/InventoryOverlay.tscn, scripts/ui/inventory_overlay.gd,
  main_controller.gd wiring). Addresses one sub-scope of #52.
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
* To Backend squad: InventoryManager has no "enumerate every non-zero
  item" getter — the Inventory overlay (PR #54) works around this by
  reading the public to_save_dict()["counts"] snapshot, which works but
  is a save-method being reused for a display read. A real
  get_all_items() -> Dictionary getter would be cleaner if another
  consumer needs the same thing.
