# AI-Sub-Agent Team — Sprint 1: Tester Backlog Clear

**Product Owner:** grit (you)
**Orchestration Session:** ox-alpha
**Date:** 2026-08-30

## Mission
Clear the Super User tester backlog issues #90–#94 from GitHub, close them with verified fixes, and update the scrumban board. Follow the Advisor's sequencing: P1 bug (#90) first, then P1 enhancement (#91), then P2/P3 items.

## Team Roles

### 1. PO / Coordinator (Product Owner)
- Owns the issue prioritization and final closure decisions
- Reviews and approves all fix PRs
- Updates SCRUMBAN.md and backlog-inbox.md
- Ensures sequencing rules are followed (P1 bug > P1 enhancement > P2 > P3)

### 2. Backend Agent (Agent A)
- Lane: Backend (scripts/autoload/, scripts/save/, scripts/farm*, scripts/forage*)
- Handles: #90 (festival state re-derive), #91 (seed economy grant), #003/004 save round-trip, BUG-006, BUG-007
- Reports to: PO + Backend squad lead

### 3. Frontend Agent (Agent B)
- Lane: Frontend (scenes/, scripts/ui/, scripts/story/)
- Handles: #92 (title screen), #93 (sleep/day-skip), BUG-005 (player avatar), BUG-008 title screen confirmation
- Reports to: PO + Frontend squad lead

### 4. QA / Test Agent (Agent C)
- Lane: tests/, test harness, round-trip validation
- Handles: regression tests, fixture fixes, test hygiene (BUG-013, BUG-015)
- Reports to: PO + QA squad lead

### 5. Orchestration Agent (Agent D)
- Lane: orchestration/, scripts, documentation
- Handles: updating SCRUMBAN.md, backlog-inbox.md, issue comments, closing GitHub issues
- Reports to: PO

## Sprint 1 Issue Assignments (from GitHub #90–#94)

| Issue | Severity | Agent | Focus |
|-------|----------|-------|-------|
| #90 | P1 bug | Agent A | Re-derive festival state at boot; fix save-data-loss regression |
| #91 | P1 enhancement | Agent A | Seeds as items + starting grant + purchase path |
| #92 | P2 enhancement | Agent B | Title screen with New Game / Continue |
| #93 | P2 enhancement | Agent A | Sleep / day-skip interaction |
| #94 | P3 enhancement | Agent B | UX polish: live hotbar, last-location persistence, intro advance hint |

## Sequential Execution Order (Advisor-mandated)

1. **Agent A: #90** — P1 bug (data loss). Must be fixed and regression-tested first.
2. **Agent A: #91** — P1 enhancement (economy foundation). Depends on #90 fix.
3. **Agent B: #92** — P2 enhancement (title screen). Can start after #90.
4. **Agent A: #93** — P2 enhancement (day-skip). Depends on #91 economics.
5. **Agent B: #94** — P3 enhancement (UX polish). Last or opportunistic.

## Definition of Done (per Advisor)

- Full suite green against Godot 4.3 headless
- Clean smoke boot (no script errors on New Game → Main)
- PR merged to `claude/farming-game-pm-requirements-w9ugtk`
- Standup entry logged
- GitHub issue closed with link to PR
- SCRUMBAN.md updated

## Immediate Next Steps

1. Agent A begins #90 investigation immediately
2. Agent A sets up regression test for festival state re-derive
3. PO creates tracking issue for sprint progress
4. Daily heartbeat checks on progress

## Success Criteria (Sprint Complete)

- [ ] #90 closed with fix + regression test
- [ ] #91 closed with fix + grant-once semantics test
- [ ] #92 closed with title screen implementation
- [ ] #93 closed with day-skip interaction fix
- [ ] #94 closed with UX polish items
- [ ] SCRUMBAN.md refreshed with new backlog state
- [ ] All 5 issues cleared from backlog