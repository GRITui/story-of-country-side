# Sprint Plan — Split bug backlog into sprints

Owner: Product Owner / scrum-master (ai-orchestration). Source: `orchestration/bug-backlog.md`.
Severity P0-P4 per `SUPERUSER.md`; lanes per `SQUAD-SPLIT.md`
(Backend = A owns `scripts/autoload`, `scripts/save`, save shape; Frontend = B owns
`scenes`, `scripts/story`, `scripts/ui`; QA owns test harness).

Definition of Done (DoD) for every sprint:
- Each scoped bug has a headless regression test that fails on the old code and passes
  on the fix.
- `godot --headless --path . --scene res://tests/TestRunner.tscn` runs; scoped checks green
  and no new failures introduced.
- Backlog entries updated (BUG-id status appended, never rewritten — append-only ledger rule).
- PR per bug with file:line refs and a one-line "why" comment.

---

## Sprint 1 — Boot & Save Integrity  (P0 blockers first)
**Goal: "New Game" always reaches a rendered world; no save can be silently corrupted.**

| ID | Sev | Item | Action | Lane | AC (acceptance criteria) |
|----|-----|------|--------|------|--------------------------|
| BUG-001 | P0 | Blank black screen on New Game | **Fix DONE**; convert `tests/_p0_repro` to a committed regression test | A | Test asserts SaveManager autoload non-null and New Game lands on Main with no error; boot is green |
| BUG-002 | P0 | `new_game()` crashes on null festival | **Fix DONE**; add regression test | A | `rederive_active_festival()` on a non-festival day returns `false`, no error |
| BUG-003 | P0 | Farm-plot save round-trip loses state (`from_save_dict` Vector2i→String, farm_plot_manager.gd:347) | Fix | A | Farm plot state survives save→load byte-for-byte (test asserts equality) |
| BUG-004 | P0 | Forage-node save round-trip loses state (`foraging_manager.gd:202`) | Fix | A | Forage node state survives save→load (test asserts equality) |
| BUG-007 | P1 | Seed-economy grant not exactly-once / ledger not restored | Fix (coupled to BUG-003) | A | `new_game` grants exact STARTING_SEED_QUANTITY once; loading a save restores the exact ledger (test asserts counts) |

**Exit criteria:** all above checks green; 0 failures in the targeted area; game boots to
Farm with HUD + avatar visible.

---

## Sprint 2 — Core Play Loop
**Goal: player can be seen/moved and core gather loop works.**

| ID | Sev | Item | Action | Lane | AC |
|----|-----|------|--------|------|-----|
| BUG-005 | P1 | PlayerAvatar not spawning in Farm/Ranch/Forage/Mine | Fix world scenes to spawn `PlayerAvatar` + Camera2D follow | B | `_test_player_avatar_*` pass for all 4 scenes |
| BUG-006 | P1 | Foraging gather returns empty / not season-valid | Fix `foraging_manager` seeding + `gather()` credit | A | `gather()` returns item_id/quantity and credits InventoryManager; item is season-valid |
| BUG-013 | P2 | `festival_started` double-connect in test harness | Fix test connect/disconnect hygiene | QA | No "already connected"/"nonexistent connection" errors in suite |

**Exit criteria:** all `_test_player_avatar_*` green; gather loop green; suite has no
signal-connection errors.

---

## Sprint 3 — Affordances, Polish, Known-Open UI
**Goal: close P2/P3 gaps and broken fixtures.** Scope the P2/P3/P4 items (BUG-008..012,
014, 015) that aren't blocked on unmade Decisions A/D/E. Frontend owns overlay/confirm/save-slot-UI
surfacing; Backend owns the persistence contracts they depend on (BUG-009/010 are backend).
Deferred explicitly: challenge-toggle / name-entry (unmade Decisions), Settings art direction
(Decision E).

---

## Runbook (how the ai-orchestration team executes)
1. Claim a bug by BUG-id (append a claim note; never edit another lane's claimed item).
2. Reproduce headlessly first (`_p0_repro` pattern → assert failing check).
3. Fix minimal + add regression test; touch only the owning lane's files.
4. Run the full suite; fix or coordinate on any new failure.
5. Append status to `backlog-inbox.md` / `bug-backlog.md`; open PR.
6. Sprint retros and per-sprint reports land in `orchestration/reports/`.