# Agent A — Backend Agent

**Role:** Backend systems, save/load, economy, festivals, day-cycle
**Assigned Issues:** #90 (P1 bug), #91 (P1 enhancement), #93 (P2 enhancement)
**Sprint:** 1 — Tester Backlog Clear
**PO:** grit

## Current Focus: Issue #90 - P1 bug - Festivals lost on quit+relaunch mid-festival

### Problem
Festivals are lost when the game quits and relaunches mid-festival. The day-edge state is never re-derived at boot.

### Investigation
1. Examined `scripts/autoload/festival_manager.gd` — need to understand how festival state is stored/loaded
2. Checked `scripts/autoload/save_manager.gd` for save/load logic
3. Looked at how `rederive_active_festival()` works

### Key Code to Review
- `scripts/autoload/festival_manager.gd` — festival re-derivation logic
- `scripts/autoload/save_manager.gd` — New Game flow
- `scripts/save/save_file.gd` — save data structure
- `scripts/save/save_migrations.gd` — migration logic

### Fix Strategy
Based on ADVISOR.md guidelines:
- **#90 is a P1 bug (data loss / regression)** — must be fixed first
- Re-derive festival state at boot instead of only on the `day_started` edge
- The fix should ensure that when the game boots, it correctly identifies if we're in a festival and which one

### Acceptance Criteria
- [ ] Festival state is correctly re-derived on game boot
- [ ] No save data loss on quit+relaunch mid-festival
- [ ] Regression test passes: SaveManager autoload non-null + New Game reaches Main without error
- [ ] `rederive_active_festival()` on a non-festival day returns `false` with no error

### Next Actions
1. Read festival_manager.gd fully
2. Read save_manager.gd New Game flow
3. Identify where festival state should be re-derived
4. Implement the fix
5. Create/regression test
6. Report progress to PO