# Advisor Seat — Development Guideline & Roadmap

Coordination doc for the **Advisor** seat: an outside-the-squads,
read-only session that synthesizes the state of the two teams already
operating on this repo into a standing guideline, a roadmap, and the
live scrumban board (`SCRUMBAN.md`). Modeled on the same conventions as
`STANDUP.md` / `SUPERUSER.md` / `SQUAD-SPLIT.md`.

## Who this is

Not part of the Country Side Crew org chart, owns no Backend/Frontend/
Content lane, never claims a GitHub issue, never writes game code, never
merges a PR. Reports findings and recommendations for the PM/Producer
and human maintainer to act on. The two teams this seat observes:

1. **Cross-functional squad loop** (Researcher/PM/Producer + Backend,
   Frontend, Content, QA, UX-UI, Audio squads) running the async
   assess → plan → build → test → complete-sprint → repeat epoch cycle
   documented in `backlog-inbox.md`, `STANDUP.md`, and the per-squad
   `squad-handshake-*.md` files.
2. **Game tester / Super User seat** (`SUPERUSER.md`) — plays the actual
   game each sprint batch and files findings as GitHub issues for the
   squad loop to triage.

## Scope boundaries

- Read-only consumer of the codebase and of both teams' coordination
  files. May only add/update: this file, `SCRUMBAN.md`, and its own
  entries in `backlog-inbox.md` (advisory, never task claims).
- Never edits `scripts/`, `scenes/`, `tests/`, squad-handshake files, or
  `SUPERUSER.md`.
- Escalates via `backlog-inbox.md`/GitHub comments; never resequences a
  squad's work directly — sequencing stays the PM/Producer's call per
  `SQUAD-SPLIT.md`.

## Current stage (assessed 2026-08-26)

**Foundation: complete.** All six pre-production decisions (#2–#7) are
closed, and all four core epics are closed and shipped:
- #8 Core Gameplay Loop (time/stamina, agriculture, ranching, fishing,
  mining, foraging)
- #9 Social Mechanics & World Building (NPC routines, relationships,
  marriage, festivals)
- #10 Progression & Economy (skills, tools, infrastructure, shipping)
- #11 Story & Meta-Objectives (opening hook, year-3 win/continue
  condition)

The game has a complete, playable, tested core loop (959+ tests green
against real Godot 4.3 headless per the latest standups), real (not
placeholder) audio via a CC0 SFX pack, and a real gameplay capture
(PR #87) for marketing use.

**In progress — two open epics, both late-stage:**
- **#52 Frontend: scenes & UI for all shipped backend systems.** Per
  standup history, every backend system except one has a shipped UI
  (infrastructure, community goal, fishing/festival mini-games, HUD).
  The one named, still-unowned gap is a **Settings system**
  (audio/controls/accessibility) — no backend for it exists yet, so
  it's currently backend-blocked, not just unclaimed frontend work.
- **#53 Content: replace placeholder content with real balance/copy.**
  Narrowed to Content-Squad's numeric/cost/balance lane (narrative text
  ceded to Writer/Dialogue Designer, which has since shipped real
  heart-event dialogue and festival flavor text via PR #82). Audio-Squad
  also flagged real background music as still open (procedural tones
  only; no fitting CC0 loop found yet).

**Fresh, currently unclaimed backlog — from the game tester:** issues
**#90–#94**, filed this cycle from Super User sprint-001/002 reports, no
open PRs against any of them yet:

| # | Sev | Type | Title |
|---|-----|------|-------|
| 90 | P1 | bug | Festivals lost on quit+relaunch mid-festival (day-edge state never re-derived at boot) |
| 91 | P1 | enhancement | Seed economy: seeds as items + starting grant + purchase path (planting is currently free & infinite) |
| 92 | P2 | enhancement | Title screen with New Game / Continue |
| 93 | P2 | enhancement | Sleep / day-skip interaction (171 real seconds per forced in-game day) |
| 94 | P3 | enhancement | UX polish batch: live hotbar, last-location persistence, intro advance hint |

Both P1s are substantive: #90 is a real data-loss regression risk (a
save-integrity bug, not a missing feature), and #91 is foundational —
every economy balance number shipped so far (#20/#23/#24, tool tiers,
shipping-bin payouts) implicitly assumes inputs aren't free, which is
currently false. Recommend both jump the queue ahead of the P2/P3 items
regardless of filing order.

## Development guideline

1. **Backlog intake stays issue-based.** Super User findings → GitHub
   issues (already the working pattern) → PM/Producer triage into the
   next epoch's Step 0 discovery. Don't shortcut Super User reports
   straight into squad work without a filed issue; the issue is what
   makes a finding claimable and visible to humans.
2. **Claim discipline.** Keep the claim-comment-before-dispatch rule
   (a "Claiming this" comment on the GitHub issue before starting) —
   this is what prevented a repeat of the early ENG-14 near-miss
   collision. Don't relax it just because the backlog is currently
   thin.
3. **Ownership boundary.** `SQUAD-SPLIT.md`'s Backend/Frontend contract
   (signals + public methods only, no reaching into `_`-prefixed
   fields) remains authoritative for all five new issues. Tag
   backlog-inbox entries `(backend)` / `(frontend)` / `(content)` when
   claiming #90–#94 so the split stays legible.
4. **Sequencing rule for mixed-severity backlog:** a P1 **bug**
   (data loss / regression) outranks a P1 **enhancement**, which
   outranks P2, which outranks P3 — sequence #90 and #91 before
   #92–#94 even though GitHub's numbering doesn't imply that.
5. **Definition of done stays unchanged:** full suite green against the
   real Godot 4.3 engine headless, clean smoke boot, PR merged to
   `claude/farming-game-pm-requirements-w9ugtk`, and a standup entry
   logged. Don't lower this bar for the newer, smaller-looking issues.
6. **Settings system is a sequencing dependency, not just a gap.**
   Because #92 (title screen) and general accessibility work reasonably
   route through the same Settings surface, flag to PM/Producer whether
   a minimal Settings backend (even audio-volume-only) should be scoped
   now rather than letting #52 stay stuck on "no backend exists yet."
7. **Advisor cadence:** this file is reviewed and `SCRUMBAN.md`
   regenerated from live GitHub + `backlog-inbox.md` state every 6
   hours (automated). Escalate only on real signals — an issue unclaimed
   across multiple consecutive board refreshes, two squads editing the
   same file concurrently, or CI/test-suite regressions — not on
   routine idle cycles.

## Roadmap

**Now (this sprint batch) — clear the tester backlog:**
- #90 (P1 bug, backend) — re-derive festival state at boot instead of
  only on the `day_started` edge; smallest, highest-value fix (real
  save-data loss).
- #91 (P1 enhancement, backend+content) — seeds as inventory items,
  starting grant, purchase path; unblocks every future balance pass
  from resting on a free-input assumption.
- #92 (P2 enhancement, frontend, backend-dependent) — title screen with
  New/Continue; check whether a minimal Settings backend should be
  scoped alongside it per guideline point 6.
- #93 (P2 enhancement, backend+frontend) — sleep/day-skip; directly
  improves new-player time-to-first-harvest (currently ~14 real
  minutes per Super User sprint-002).
- #94 (P3 enhancement, frontend) — UX polish batch; lowest risk, do
  last or opportunistically alongside the above.

**Next — close the two open epics:**
- #52: ship the Settings system (audio/controls/accessibility) and its
  UI, the last named gap.
- #53: finish the Content-Squad's remaining numeric/balance pass; land
  a real (non-procedural) music track if a licensable CC0 option turns
  up, otherwise keep the existing procedural loop and close the epic on
  SFX/copy completeness alone.

**Then — release readiness:**
- Full player-machine parity pass beyond the current macOS arm64
  baseline (Windows/Linux headless + smoke boot).
- Community & Marketing's store-page/wishlist work, now unblocked by
  the real gameplay capture (PR #87).
- A soak/long-session pass (multi-in-game-year play) now that #90's
  boot-time-derived-state class of bug is known to exist — worth a
  targeted audit of other day-edge-derived systems per Super User
  sprint-002's suggestion.

**Later — post-launch backlog:**
- Remaining unused Kenney SFX hookups (Audio-Squad has ~90 left) and
  the standing composer-vs-licensed-library decision, still awaiting a
  Studio Head call.
- Additional content variety (more festivals, recipes, NPCs) — pure
  addition, no architectural risk.
- Multiplayer/mobile/monetization: already closed via decisions #4–#7
  (peaceful mines, quest-gated automation, platform/monetization,
  art style, co-op) — revisit only if project scope goals change,
  don't resurface as ambient backlog.
