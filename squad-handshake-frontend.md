# Squad Handshake — Frontend (Squad B)

<squad_metadata>
  <squad_name>Frontend-Squad</squad_name>
  <current_status>ACTIVE</current_status>
  <active_task_id>epoch-24-world-scenes</active_task_id>
  <sprint_completion_percentage>0</sprint_completion_percentage>
</squad_metadata>

## Epoch 24 update
Shipped a small, self-contained sub-scope: HUD weather display, via PR #63
(squash-merged). `WeatherManager` (backend, PR #62 this same epoch) had a
public `get_current_weather()`/`weather_changed` ready to consume; wired a
new `WeatherLabel` into `scenes/ui/HUD.tscn`'s existing top-left date/season
cluster (a new `Row` HBoxContainer alongside `DateLabel`, since the cluster
previously held a single Label), primed on `_ready()` and kept in sync via
the signal, per menu-hud-flow-spec.md §2's diagram which already listed
weather there. Read-only via the public getter/signal, no new backend
surface needed, per SQUAD-SPLIT.md's contract rule. 677/677 tests pass (6
new), clean smoke boot. Self-merged per standing authorization.

Next up in this epoch: picking a world/tile-rendering scene for one of the
remaining activity systems (Ranching/Fishing/Mining/Foraging), following
FarmScene's precedent (reactive to backend signals, isometric grid spec,
no polling).

Shipped a second sub-scope same epoch: `scenes/world/RanchScene.tscn` +
`scripts/world/ranch_scene.gd`, via PR #64 (squash-merged). 5x4 isometric
pen grid, reactive to `AnimalManager`'s `animal_added`/`animal_fed`/
`animal_brushed`/`product_collected`. `AnimalManager` has no positional
concept of its own, so each pen's `animal_id` is derived deterministically
from grid position (`"pen_<x>_<y>"`) rather than a scene-local duplicate
lookup table -- `get_animal()`/`has_animal()` stay the single source of
truth. Click-to-add/feed/brush/collect stretch interaction mirrors
FarmScene's click-to-plant/water/harvest cycle. 689/689 tests pass (12
new), clean smoke boot. Self-merged per standing authorization.

Next up: Fishing/Mining/Foraging world scenes remain, same pattern.

Shipped a third sub-scope same epoch: `scenes/world/ForageScene.tscn` +
`scripts/world/forage_scene.gd`, via PR #65 (squash-merged). 8x8 isometric
grid, reactive to `ForagingManager`'s `forage_gathered`/
`forage_node_rerolled`. Unlike FarmPlotManager/AnimalManager,
ForagingManager hands node placement to the caller (per its own
docstring), so this scene both populates the grid (`register_node()` per
cell, a no-op if already registered) and renders it. Click-to-gather on
available tiles only, mirroring ForagingManager's own validation. 702/702
tests pass (13 new), clean smoke boot. Self-merged per standing
authorization.

Next up: Fishing/Mining world scenes remain, same pattern.

Shipped a fourth sub-scope same epoch: `scenes/world/MineScene.tscn` +
`scripts/world/mine_scene.gd`, via PR #66 (squash-merged). Isometric grid
sized from `MiningManager.get_floor_size()`, reactive to `rock_broken`/
`floor_descended` (the latter triggers a full re-render since the backend
regenerates the entire floor). `MiningManager` deliberately exposes no
getter for a rock's ore contents before it's broken -- this scene respects
that, every intact rock renders identically. Click-to-break rock,
click-to-descend ladder. 714/714 tests pass (12 new, using
`generate_floor(1, <seed>)` for determinism, same as the existing ENG-16
tests), clean smoke boot. Self-merged per standing authorization.

Remaining per #52: Map/Skills/Settings full-screen overlays, and scenes
for Fishing (mini-game contract, `attempt_catch()` -- a genuinely
design-open task per FishingManager's own "input/skill-check design TBD"
disclosure, unlike the four grid-based world scenes above which had an
obvious FarmScene-precedent shape), Marriage/Festivals/Infrastructure/
Community-Goal.

Shipped a fifth sub-scope same epoch: Skills full-screen overlay
(`scenes/ui/SkillsOverlay.tscn` + `scripts/ui/skills_overlay.gd`), via
PR #67 (squash-merged). Same chrome/discipline as InventoryOverlay,
reactive to `SkillManager`'s `xp_gained`/`level_changed`. The four skill
names shown (Farming/Fishing/Mining/Foraging) are read from existing
content -- every activity manager already calls `add_xp()` with one of
these -- not invented. `PauseMenu`'s Skills button is now real (was a
disabled placeholder since PR #54); Map/Settings stay disabled since
neither has a backend system yet. 724/724 tests pass (10 new), clean
smoke boot. Self-merged per standing authorization.

Remaining per #52: Map/Settings full-screen overlays (blocked on a
backend system existing for either -- not a Frontend-only task), and
scenes for Fishing (mini-game contract), Marriage/Festivals/
Infrastructure/Community-Goal.

## Epoch 20 note (this session, PM/Backend, log sync only)
This file was stale as of epoch 20 — Epoch 18's FarmScene sub-scope had
already shipped and merged (PR #57, squash-merged, 508/508 tests passing
per its own PR comment on #52) but this handshake file hadn't been synced
to reflect that. Syncing status here; no new Frontend work done by this
session this epoch. Remaining per #52: Map/Skills/Settings screens, world
scenes for Ranching/Fishing/Mining/Foraging/Marriage/Festivals/
Infrastructure/Community-Goal, and a Weather system (no WeatherManager
exists yet).

## Current Focus
Epoch 18: dispatched a subagent to build the FarmPlot world/tile-rendering
scene (branch frontend/farm-plot-scene) against issue #52 — the single
biggest player-visible gap (nothing currently renders the farming loop).
Note: issue #52 got auto-closed by GitHub when PR #54 merged despite
explicit text saying to leave it open (it's tracking-only) — reopened it;
told this new subagent to avoid any closing-keyword phrasing near "#52"
in its PR body to prevent a repeat.

**Shipped**: PR #57 (squash-merged) — `scenes/world/FarmScene.tscn`, an
8x8 isometric TileMap per `design/art/isometric-grid-spec.md`, fully
reactive to `FarmPlotManager`'s signals (no new backend surface needed).
Placeholder runtime-generated 5-color tileset (empty/planted/watered/
ready/withered) plus a click-to-plant/water/harvest stretch feature.
508/508 checks passed, clean smoke boot. Issue #52 left open (tracking-
only) — see the epoch 20 note above for what's still outstanding.

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
* PR #67 (merged, this session): Frontend — Skills full-screen overlay
  (scenes/ui/SkillsOverlay.tscn, scripts/ui/skills_overlay.gd,
  pause_menu.gd wiring).
* PR #66 (merged, this session): Frontend — MineScene world/tile-
  rendering for MiningManager (scenes/world/MineScene.tscn,
  scripts/world/mine_scene.gd).
* PR #65 (merged, this session): Frontend — ForageScene world/tile-
  rendering for ForagingManager (scenes/world/ForageScene.tscn,
  scripts/world/forage_scene.gd).
* PR #64 (merged, this session): Frontend — RanchScene world/tile-
  rendering for AnimalManager (scenes/world/RanchScene.tscn,
  scripts/world/ranch_scene.gd).
* PR #63 (merged, this session): Frontend — HUD weather display
  (scenes/ui/HUD.tscn WeatherLabel, scripts/ui/hud.gd wiring to
  WeatherManager).
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
