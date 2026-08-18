# Squad Split: Backend (A), Frontend (B), Content, QA, PM

This started as a two-lane split and grew a third as the pattern proved
itself. Current lanes:

Read this before claiming any task if you're operating as either lane.
This formalizes a split the codebase was already trending toward — every
autoload so far exposes state changes via signals and read-only getters,
and nothing reaches into another autoload's private (`_`-prefixed)
fields from outside. The rule below just makes that boundary explicit and
draws the line for new work, including scenes/UI that don't exist yet.

## Ownership by directory

**Backend (Squad A) owns:**
- `scripts/autoload/**` — every `*_manager.gd` singleton (`TimeManager`,
  `StaminaManager`, `ShippingBinManager`, `RelationshipManager`,
  `QuestManager`, `SkillManager`, `ToolManager`, `InventoryManager`,
  `FarmPlotManager`, `SaveManager`) and any new one.
- `scripts/economy/**`, `scripts/quests/**`, `scripts/farming/**`,
  `scripts/social/**` — content/data `Resource` types (`ToolUpgradeTier`,
  `QuestCondition`, `QuestDefinition`, `CropDefinition`, `FarmPlot`,
  `GiftPreferenceTable`) and any new domain-data folder that holds
  `.tres`-authorable content, not scenes.
- `scripts/npc/npc_schedule.gd`, `scripts/npc/npc_schedule_entry.gd` —
  the schedule *data model*.
- Game rules, balance numbers, save-data shape, and every signal
  contract.

**Frontend (Squad B) owns:**
- `scenes/**` — every `.tscn` file, including `Main.tscn` and anything
  under `scenes/intro/`.
- `scripts/story/**` — `IntroSequence`, `MainController`: these
  sequence *presentation* (narration timing, boot-time scene wiring),
  not game rules — confirmed by reading both files before writing this
  split, they contain no gameplay logic of their own.
- `scripts/npc/npc_controller.gd` — reads `NPCSchedule` (backend data)
  and moves a `Node2D`; this is presentation consuming backend data, not
  the data model itself.
- `scripts/ui/**` (doesn't exist yet — create it for the first HUD/menu
  implementation) — reads `design/ui-flows/menu-hud-flow-spec.md`.
- Environment tilemap/sprite work reading `design/art/isometric-grid-spec.md`.
- `design/**` — UX-UI-Designer-Squad's specs feed Frontend's
  implementation; Frontend can also produce these specs itself when
  claiming its own convention decisions (precedent: `UX-GRID` was
  claimed and delivered directly by an orchestrator acting as UX-UI
  squad rather than waiting on a separate pass).

## The contract rule (this is the part that actually prevents collisions)

Frontend code may only touch a backend autoload through:
1. Its public methods (`add_xp()`, `ship_item()`, `spend()`, `plant()`,
   etc.) — never a `_`-prefixed field.
2. Its signals (`stamina_changed`, `gold_changed`, `crop_harvested`,
   etc.) for reacting to state changes.

If Frontend needs a read or write path that doesn't exist yet, that's a
**backend task** to add — file it (or comment on the relevant issue)
rather than reaching around the contract. This is exactly the discipline
`tests/test_runner.gd` already exercises against every autoload; a scene
consuming a manager should look like that test file's usage, not like
internal test-only field pokes (`sm._xp = {}` etc. are for tests only,
never for frontend runtime code).

Backend must not import/reference anything under `scenes/` or
`scripts/story/` or `scripts/ui/` — backend is headless-testable by
construction (see every existing autoload), and staying decoupled from
any scene is what makes that possible.

## Shared file caution

`project.godot`'s `[autoload]` block and `scripts/autoload/save_manager.gd`
are backend files but get touched by *every* new backend system (new
autoload registration + save wiring) — expect conflicts here specifically
when backend work lands concurrently from two sessions. Resolution
pattern already established: `git merge` the base branch into your
feature branch before opening/updating a PR, resolve by keeping both
sides' additions (they're almost always pure appends to the same
dictionary/list), re-run the full test suite, then push. Don't discard
either side without reading both first.

`tests/test_runner.gd` is shared by construction — both squads' work
gets tested in the same file for now. Same resolution pattern: concurrent
additions are almost always non-overlapping appends (new `_test_*()`
functions, new calls in `_ready()`); merge conflicts here are almost
never a real logic conflict, just two diffs touching adjacent lines.

## Branch naming

- Backend: `feature/eng-<N>-<slug>` (unchanged from existing convention).
- Frontend: `frontend/<slug>` or `feature/eng-<N>-<slug>` if tied to a
  specific issue — either is fine, just keep one task per branch.

## Coordination artifacts

- `backlog-inbox.md` stays the single shared backlog — don't fork it per
  squad. Existing `<task_item>` entries aren't retroactively tagged; new
  entries should note `(backend)` / `(frontend)` in their description
  when the split matters for who should claim them.
- `squad-handshake-engineer.md` = Backend/Squad A's status log (it's
  already been serving this role — every task logged there so far is
  backend work).
- `squad-handshake-frontend.md` = Frontend/Squad B's status log (new;
  create it on first frontend claim if it doesn't exist yet).
- `squad-handshake-uxui.md` stays UX-UI-Designer's log — spec/convention
  docs, feeding Frontend's implementation, not implementation itself.
- `squad-handshake-researcher.md`, `squad-handshake-qa.md` unchanged.

## What this doesn't solve

No CI exists, so there's no automated gate stopping backend and frontend
PRs from landing in an order that breaks one against the other — the
contract rule above is discipline, not enforcement. If a frontend PR
needs a backend method that doesn't exist yet, land backend first and
say so in the frontend PR description rather than stubbing around it.

## Content lane

Every squad so far has hit the same pattern and moved on: an issue needs
concrete content (item names, balance numbers, dialogue) that doesn't
exist anywhere in the design doc, so the squad picks a reasonable
placeholder, documents it as such, and ships the system around it. That's
the right call in the moment — don't block a system on unwritten
content — but the placeholders were piling up (crop/animal/fish/forage
names and prices, gift preferences, intro narration, quest content, tool
costs) with nobody's job to go back and actually write them.

**Content squad may edit:** the literal content/value definitions inside
any file — a `DEFAULT_LINES` array, a `_register_default_content()`
function's registered values, a `GiftPreferenceTable`'s item lists, a
`QuestDefinition`'s chosen item/quantity/flag — regardless of which
lane's directory that file lives in. **Content squad may not edit:**
method signatures, signal definitions, control flow, or anything that
isn't a value/string a designer could plausibly tune without touching
logic. If a content change requires a logic change to express (e.g. a
new condition type), that's a backend or frontend task to file, not
something to build around.

Changing a placeholder value will break any test that asserts the old
placeholder number — updating those specific assertions to match new
content is part of the content task, not scope creep, since the tests
were asserting placeholder values on purpose (documented in each PR that
introduced them).

Status log: `squad-handshake-content.md`.

## PM / orchestrator

One session holds the PM role at any given time: owns `backlog-inbox.md`
as the single source of truth, resolves cross-lane merge conflicts
(these have been real and recurring — see git history), decides when a
QA or Content finding needs a tracked GitHub issue vs. a direct fix, and
spawns/redirects squad sessions as gaps appear. PM does not own a
directory the way Backend/Frontend/Content do — PM's job is coordination
and unblocking, stepping into hands-on work (any lane) only when nothing
else is picking it up.
