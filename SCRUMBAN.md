# Scrumban Board

Live snapshot maintained by the **Advisor** seat (`ADVISOR.md`), rebuilt
from GitHub issues/PRs + `backlog-inbox.md`/`STANDUP.md` every 6 hours by
an automated refresh. Unlike `backlog-inbox.md` (append-only ledger),
this file is **overwritten** each cycle — it's a snapshot, not a log.
A short changelog of the last few refreshes is kept at the bottom for
continuity.

WIP limit: keep **In Progress ≤ 1 item per squad lane** (Backend,
Frontend, Content, Audio, QA) — matches the one-epoch-at-a-time pattern
already visible in `STANDUP.md`.

---

## Backlog (filed, unclaimed)

| # | Sev | Lane | Title |
|---|-----|------|-------|
| 90 | P1 bug | backend | Festivals lost on quit+relaunch mid-festival (day-edge state never re-derived at boot) |
| 91 | P1 enhancement | backend+content | Seed economy: seeds as items + starting grant + purchase path |
| 92 | P2 enhancement | frontend (backend-dependent) | Title screen with New Game / Continue |
| 93 | P2 enhancement | backend+frontend | Sleep / day-skip interaction |
| 94 | P3 enhancement | frontend | UX polish batch: hotbar, last-location persistence, intro advance hint |

## Ready (unblocked, next to claim — advisor recommendation, not a claim)

- #90 and #91 — both unblocked, no dependency, recommended first per
  `ADVISOR.md` sequencing rule (P1 bug/foundational-enhancement before
  P2/P3).

## In Progress (claimed, no PR yet)

_None — no open GitHub issue currently carries a "Claiming this"
comment without a matching PR._

## Review (open PRs)

_None — 0 open pull requests as of this snapshot._

## Done (recent — last ~10 shipped items, newest first)

- PR #89 — Audio: Festival/Community-Goal signal hookups (real CC0 SFX)
- PR #88 — Audio: Skill/Quest/Tool-upgrade signal hookups (real CC0 SFX)
- PR #87 — Marketing: real ~9.2s gameplay capture (FarmScene loop)
- PR #86 — Audio: real CC0 Interface Sounds pack (replaces procedural placeholder SFX for core signals)
- PR #82 — Content/Writer: heart-event dialogue table + festival flavor text
- PR #77 — Frontend: Fishing mini-game overlay
- PR #75 — Audio: `AudioManager` (initial procedural SFX/music)
- PR #74 — Frontend: Community Goal contribution UI
- PR #73 — Frontend: Infrastructure cost display + automation devices UI
- PR #72 — Backend + Frontend: prior Cross-Squad Requests batch

## Epics status

| # | Epic | Status |
|---|------|--------|
| 8 | Core Gameplay Loop | ✅ Closed |
| 9 | Social Mechanics & World Building | ✅ Closed |
| 10 | Progression & Economy | ✅ Closed |
| 11 | Story & Meta-Objectives | ✅ Closed |
| 52 | Frontend: scenes & UI for shipped backend systems | 🟡 Open — Settings system is the one named remaining gap |
| 53 | Content: replace placeholder content with real balance/copy | 🟡 Open — Content-Squad numeric pass + real music still open |

## Escalations (advisor flags for PM/Producer/human)

_None currently._ Will flag here if: an issue in Backlog survives more
than 2 consecutive refreshes (12h) with no claim comment, two squads
touch the same file concurrently outside `SQUAD-SPLIT.md`'s known
shared-file cases, or a refresh finds the test suite red on the base
branch.

---

## Refresh log

- **2026-08-26T00:03Z** — Initial board seeded. Foundation (epics
  #8–#11, decisions #2–#7) confirmed closed. Epics #52/#53 open.
  5 fresh Super User issues (#90–#94) in Backlog, all unclaimed, 0 open
  PRs. Next automated refresh in 6h.
