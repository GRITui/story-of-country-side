# Bug Backlog — Story of Country Side

Owner: Product Owner / ai-orchestration. This backlog supersedes, for *screen / boot /
save* issues, the feature-led ledger in `backlog-inbox.md`. Severity per `SUPERUSER.md`:

| Sev | Meaning |
|-----|---------|
| P0  | Blocks play entirely (crash, hard lock, save loss) |
| P1  | Major — breaks or seriously frustrates a core loop |
| P2  | Moderate — confusing, awkward, or missing affordance |
| P3  | Minor polish |
| P4  | Idea / nice-to-have |

Lane ownership per `SQUAD-SPLIT.md`: Backend (A) owns `scripts/autoload/**`,
`scripts/save/**`, save-data shape, game rules; Frontend (B) owns `scenes/**`,
`scripts/story/**`, `scripts/ui/**`, presentation.

## Legend
- **[FIXED]** — root cause fixed; follow-up = committed regression test.
- **[SURFACED]** — newly reported by the headless suite once the P0 boot blocker was
  removed (the suite previously could not even reach these checks).
- **[KNOWN-OPEN]** — already in `backlog-inbox.md` / GitHub, carried forward.

## P0 — Blocks play entirely

### BUG-001 [FIXED] Blank black screen on "New Game" (the reported regression)
- **Sev:** P0 · **Lane:** Backend · **priority:** 1
- **Symptom:** player clicks **New Game** on the title screen → game leads to a blank
  black screen.
- **Root cause (confirmed):** `scripts/autoload/save_manager.gd:47-48` `preload`s
  `scripts/save/save_file.gd` + `save_migrations.gd`. The staged save-hardening edit
  added a **duplicate** `const SaveMigrations = preload(...)` to `scripts/save/save_file.gd`
  (both line 1 and line 40), and `save_file.gd`/`save_migrations.gd` `preload`ed each
  other (**circular preload**). `save_file.gd` failed to parse → `preload` returned
  nothing → `SaveManager` autoload failed → SaveManager = `Nil` → every manager
  referencing it threw on boot → **nothing rendered = black screen**.
- **Fix applied:** removed duplicate `const SaveMigrations`; broke the circular preload
  by giving `save_migrations.gd` its own local `LEGACY_VERSION` const so it no longer
  references `SaveFile`; re-scanned global class cache
  (`godot --headless --path . --import`) so `SaveFile`/`SaveMigrations` register.
- **Verification:** `tests/_p0_repro.tscn` drives real TitleScreen → New Game → Main;
  **no script errors** after fix (before: 5+ cascade errors).
- **Follow-up (Sprint 1):** convert `tests/_p0_repro.gd` (marked `DELETE AFTER USE`)
  into a committed regression test: SaveManager autoload non-null + New Game reaches
  Main without error.

### BUG-002 [FIXED] `new_game()` crashes on null festival
- **Sev:** P0 (throws during every New Game) · **Lane:** Backend
- **Root cause (confirmed):** `rederive_active_festival()` in
  `scripts/autoload/festival_manager.gd` dereferenced `def.festival_id` while `def == null`
  (most days are not festival days). `SaveManager.new_game()` calls it, so every New Game
  threw `Invalid access to property 'festival_id' on type 'Nil'` (`at festival_manager.gd:195`).
- **Fix applied:** reordered logic (`def != null and _active_festival_id == def.festival_id`
  → return true; else drop stale active festival; `def == null` → return false). No null deref.
- **Follow-up (Sprint 1):** regression test — `rederive_active_festival()` on a
  non-festival day returns `false` with no error.

### BUG-003 [SURFACED] Save data corruption: farm-plot round-trip loses state
- **Sev:** P0 (save loss) · **Lane:** Backend · **priority:** 2
- **Evidence:** `FAIL: farm plot state should round-trip through save/load, got <null>`;
  `Trying to assign value of type 'Vector2i' to a variable of type 'String'` at
  `scripts/autoload/farm_plot_manager.gd:347` (`from_save_dict`).
- **Root cause (to confirm):** `from_save_dict` type mismatch — saved `Vector2i` assigned
  to a `String` variable during restore, corrupting plot state.
- **Action:** fix type handling + round-trip test.

### BUG-004 [SURFACED] Save data corruption: forage-node round-trip loses state
- **Sev:** P0 (save loss) · **Lane:** Backend
- **Evidence:** `FAIL: forage node state should round-trip through save/load, got <null>`;
  `Trying to assign value of type 'Vector2i' to a variable of type 'String'` at
  `scripts/autoload/foraging_manager.gd:202` (`from_save_dict`).
- **Action:** mirror BUG-003 fix + round-trip test.

---
## P1 — Major / breaks or frustrates a core loop

### BUG-005 [SURFACED] PlayerAvatar not spawning in world scenes
- **Sev:** P1 (player can't see/move the avatar) · **Lane:** Frontend (B)
- **Evidence:** `_test_player_avatar_*` failures — `Cannot call method 'get_children' on a
  null value` for Farm/Ranch/Forage/Mine (`tests/test_runner.gd:5666,5678,5691,5703,5722`);
  `Camera2D should be reparented under PlayerAvatar` FAIL.
- **Root cause (to confirm):** world scenes (`FarmScene.tscn` etc.) fail to spawn
  `PlayerAvatar` (likely a mid-edit change in the current branch).
- **Action:** instantiate/verify `PlayerAvatar` child in Farm/Ranch/Forage/MineScene +
  Camera2D follow.

### BUG-006 [SURFACED] Foraging: gathered nodes / season validity broken
- **Sev:** P1 · **Lane:** Backend
- **Evidence:** `FAIL: register_node should immediately seed a season-valid item`,
  `FAIL: gather() should return the gathered item_id/quantity, got { }`,
  `FAIL: gather should credit InventoryManager, got 0`, season-validity checks.
- **Action:** seed-item selection should validate against current season; `gather()`
  should return + credit. Root cause to confirm in `foraging_manager.gd`.

### BUG-007 [SURFACED] Seed-economy grant not deterministic / ledger not restored
- **Sev:** P1 · **Lane:** Backend
- **Evidence:** `FAIL: new_game should grant starter parsnip seeds exactly once, got 23`;
  `FAIL: ...got 9`; `FAIL: loading an existing save restores its exact ledger instead of
  re-granting starters, got 9`.
- **Root cause (to confirm):** `FarmPlotManager.grant_starting_seeds()` interacts with the
  save/load path so the starting grant is applied on top of (or instead of) the restored
  ledger, and the grant count is wrong. Likely coupled to BUG-003's round-trip corruption.
- **Action:** fix grant-once semantics + ledger restore; add exact-count test.

---

## P2 — Moderate / missing affordance

- **BUG-008 [KNOWN-OPEN]** Title screen **New Game has no confirmation dialog**, silently
  overwrites an existing save (`scripts/ui/title_screen.gd` docstring flags this). Spec's
  name-entry / mode-select children are future scope. **Lane:** Frontend.
- **BUG-009 [KNOWN-OPEN]** No save-slot list (thumbnail/date/playtime) — SaveManager is
  single-slot, no metadata API. **Lane:** Backend.
- **BUG-010 [KNOWN-OPEN]** Last world location not persisted — every boot starts at Farm
  (`main_controller.gd` `travel_to`/SaveManager gap). **Lane:** Backend.
- **BUG-011 [KNOWN-OPEN]** Settings overlay still a disabled placeholder. **Lane:** Frontend.
- **BUG-012 [KNOWN-OPEN]** Map / Skills full-screen overlays incomplete (`#52` remaining
  items in `backlog-inbox.md`). **Lane:** Frontend.
- **BUG-013 [SURFACED]** `FestivalManager.festival_started` double-connected in the test
  harness (`Signal 'festival_started' is already connected...` +
  "disconnect nonexistent connection"). Test hygiene. **Lane:** QA.

## P3 — Minor polish / broken fixtures
- **BUG-014 [SURFACED]** Missing audio asset referenced:
  `res://assets/kenney/interface-sounds/does_not_exist.wav` → `Resource file not found`.
- **BUG-015 [SURFACED]** Invalid JSON fixtures in tests (`Parse JSON failed: got 'this'`,
  `Expected key`). **Lane:** QA.

## P4 — Ideas / nice-to-have
- **(carry from `backlog-inbox.md`)** save-slot UI, festival-name template fallbacks,
  challenge-toggle children, co-op structure notes (per existing epics).

---

## Top-3 recommendations for Sprint 1
1. **BUG-001** — verify the P0 black-screen fix holds and commit a real regression test.
2. **BUG-002** — regression test for the `new_game()` festival null-deref fix.
3. **BUG-003/004** — fix save-data round-trip corruption (P0 save-loss) + the
   `from_save_dict` Vector2i→String type bugs; unblocks BUG-007.
---