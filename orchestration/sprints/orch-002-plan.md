# ORCH-002 Sprint Plan — "Comfort & Balance" (drafted at ORCH-001 planning,
# re-confirmed at Retrospective 1)

**Owner:** Product Owner (ox-alpha orchestration session)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk` (post-ORCH-001)
**Status:** PLANNED
**Squad mix:** eng-backend, fe-ui, content-writer, qa-tester
(different mix than ORCH-001: content lane joins for the balance pass)

## Sprint goal

Fix the pacing complaint (issue #93) and the UX friction batch (issue
#94), and replace the seed-economy placeholder economics (issue #91
follow-up, content lane) with tuned values so the money sink introduced
in ORCH-001 is actually balanced.

## Tasks

### T6 — Sleep / day-skip API (backend, GitHub #93, P2)
- Branch: `feature/eng-93-sleep-day-skip`
- Public `TimeManager` (or SleepManager if cleaner) API to advance to
  next morning: restores stamina, advances day/date, fires the normal
  day-cycle edges so downstream systems behave identically to natural
  midnight rollover. Guard rules kept minimal and documented.
- Acceptance: unit tests prove stamina restore + date advance + edge
  firing equivalence; full suite green.

### T7 — UX polish batch (frontend, GitHub #94, P3)
- Branch: `frontend/ux-polish-batch`
- Intro advance hint + skip control; boot returns to last-visited world
  location (uses persisted location shipped in 8fe6f4e); hotbar
  placeholder strip resolved (remove or wire minimal real hotbar).
- Acceptance: each sub-item demonstrably fixed; suite green.

### T8 — Seed/economy balance pass (content lane, #91 follow-up)
- Branch: `content/seed-balance-pass`
- Replace placeholder seed prices, starter grant size, and related
  payout/cost values with tuned numbers targeting: starter grant funds
  ~first plot expansion; seed cost vs harvest payout margin in line with
  existing tool-tier costs; document rationale per value.
- Allowed per convention: updating test assertions that intentionally
  pinned placeholder numbers. Values only — no logic edits.
- Acceptance: every placeholder number in the seed chain replaced or
  explicitly justified; suite green with updated assertions.

### T9 — Sleep interaction UI (frontend) — BLOCKED by T6 merge
- Branch: `frontend/sleep-interaction`
- Bed interaction prompt in the farm scene + confirm dialog + HUD
  day-advance feedback, consuming only T6's public API/signals.
- Acceptance: E2E sleep path works; suite green.

### T10 — Sprint QA gate — BLOCKED by T6..T9 merge
- Full regression + scripted E2E new-player arc: title -> new game ->
  buy seeds -> plant -> sleep-skip -> harvest -> ship -> correct payout;
  festival persistence regression re-check; contract sweep.

## Retro hook

Retrospective 2 reviews both sprints cumulatively; PO feedback appended
to `backlog-inbox.md` (next-candidate scope: settings backend P4,
CC0 music search, day-edge audit outcomes).
