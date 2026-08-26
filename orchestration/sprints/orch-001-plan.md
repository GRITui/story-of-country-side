# ORCH-001 Sprint Plan — "Core Loop Integrity"

**Owner:** Product Owner (ox-alpha orchestration session)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** PLANNED -> IN_PROGRESS
**Squad mix:** eng-backend, fe-ui, qa-tester (no content lane this sprint)

## Sprint goal

Eliminate the two P1 player-facing breaks (issues #90, #91) and give the
game a front door (issue #92). After this sprint a new player can:
boot -> title screen -> New Game -> receive starter seeds -> buy seeds ->
plant (seeds consumed) -> play without losing an active festival on relaunch.

## Tasks

### T1 — Festival persistence across quit+relaunch (backend, GitHub #90, P1)
- Branch: `feature/eng-90-91-core-loop-integrity`
- Root cause (per superuser/reports/sprint-002.md): FestivalManager
  activation derives only from the `day_started` edge, which never fires
  when booting mid-day; no FestivalManager save dict exists.
- Fix: persist active-festival state through SaveManager; restore on
  load AND on mid-day boot. Audit other day-edge-derived systems
  (WeatherManager et al.) for the same gap; fix cheap ones, file the rest.
- Acceptance: two-process repro from sprint-002 report passes; new unit
  tests prove save->restore of an active festival; full suite green;
  clean smoke boot.

### T2 — Seed economy foundation (backend, GitHub #91 part A, P1)
- Same branch as T1 (sequential commits).
- Scope: seed item definitions (one per crop), new-game starter grant
  (placeholder numbers documented inline), `plant()` requires + consumes
  a seed, ShopManager public API (`list_seeds()`, `buy_seed()` with gold
  integration). Headless-testable; no scene dependencies (contract rule).
- Acceptance: tests prove plant() fails without seed / succeeds and
  consumes with seed; grant applies on new game only; buying reduces
  gold and adds seeds; full suite green.

### T3 — Title screen with New Game / Continue (frontend, GitHub #92, P2)
- Branch: `frontend/title-screen`
- Implement per `design/ui-flows/menu-hud-flow-spec.md` section 1.
- Contract rule: touch SaveManager/FestivalManager only via public APIs
  and signals. Boot routes: Continue (if save) vs New Game (fresh state,
  intro sequence).
- Acceptance: scene boots headless-clean; both paths reach expected
  scene; no `_`-prefixed cross-lane access.

### T4 — Shop overlay UI (frontend, GitHub #91 part B) — BLOCKED by T2 merge
- Branch: `frontend/shop-overlay`
- Overlay lists seeds, buy buttons, gold display via backend signals.
- Acceptance: buy path E2E against real ShopManager; suite green.

### T5 — Sprint QA gate — BLOCKED by T1..T4 merge
- Pull merged base; headless import pass; full TestRunner suite;
  smoke boot (`--quit-after 60`); festival repro re-run; title-screen
  boot check; contract-boundary sweep over all new diffs.
- Deliverable: pass/fail per acceptance criterion + defect list (P0-P4).

## Process conventions (this orchestrated sprint)

- Engineers work in isolated worktrees under `/Users/grit/soc-orch/`;
  PO performs ALL remote operations (push / PR / squash-merge) using the
  documented standing self-merge authorization, after reviewing diffs.
- Ledger consolidation: PO writes consolidated `backlog-inbox.md`
  task_items + STANDUP entries post-merge (avoids the repo's known
  concurrent-append conflict class). Squad handshakes untouched unless a
  lane owner ships.
- Claim comments posted on #90/#91/#92 at dispatch time per the
  claim-comment-before-dispatch discipline.
- Findings use the P0-P4 scale from SUPERUSER.md.
