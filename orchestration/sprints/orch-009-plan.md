# ORCH-009 Sprint Plan — "Player Avatar + NPC Visibility"

**Owner:** Product Owner (ox-alpha)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** ✅ READY
**Timebox:** <=90 min wall-clock
**Squad mix:** eng-backend, fe-ui, qa-tester

## Sprint goal

Make the social world feel alive: the player controls a visible animated avatar in every world scene, and all six villagers appear at their scheduled locations with movement animations. After this sprint: players can move around, click on NPCs, see them walk between scheduled stops, and interact via the existing Relationships overlay.

## Issues addressed

| Issue | Priority | Lane |
|-------|----------|------|
| #100 Player avatar as embodied character | P1 | Frontend |
| #102 Instantiate NPCs in world scenes | P2 | Frontend |

## Tasks

### T1 — Player avatar (frontend, #100)
- Branch: `frontend/orch-009-player-avatar`
- Implement `scripts/world/player_avatar.gd` as CharacterBody2D with directional animation states (IDLE/WALKING/SWING_TOOL)
- Add 4-directional movement (WASD) with grid-based positioning
- Provide backend-facing API: `get_facing() -> Vector2i`, `get_current_tool() -> StringName`, `tool_changed` signal
- Integrate with every world scene (Farm, Ranch, Forage, Mine)
- **Acceptance:** animated avatar visible in all world scenes; keyboard movement works; tool-use feedback visualizes; headless-testable API.

### T2 — NPC presence pass (frontend, #102)
- Branch: `frontend/orch-009-npc-presence`
- Every NPC in `npc_roster.gd` instantiated in at least one world scene
- Use `NPCRoster.npcs_for_scene()` to populate world scenes
- NPCs render with `procedural_character_art.gd` silhouettes
- NPCs move between schedule waypoints; idle animation at destination
- **Acceptance:** at least 2 NPCs visible in FarmScene during Spring morning; they move on schedule; player can talk (E key near NPC, shows gift preference hint); full suite green.

### T3 — Schedule-debug overlay API (backend, #102)
- Branch: `feature/orch-009-schedule-debug`
- Add `get_debug_schedule_for(npc_name)` to NPCSchedule.gd for introspection
- Add `get_current_entry(npc_name, hour, minute, season, weather)` for QA testing
- **Acceptance:** debug getter works; QA can assert NPC location in E2E.

### T4 — Sprint QA gate (qa-tester)
- Full suite + smoke boot + E2E: boot → avatar visible → NPCs appear walking → can open relationships overlay near NPC → schedule debug API works → all existing tests pass.
- Deliverable: pass/fail + defect list.

## Dependencies & sequencing

```
T1 (avatar) ──┐
T2 (NPC presence) ──┤
T3 (debug API) ──┘

T4 (QA gate) waits for all.
```

T1, T2, T3 independent. T4 waits for all.

## Retro hook

Retrospective 9 reviews: does the avatar feel embodied? Are NPCs distracting or delightful? Can QA use the debug API for reliable tests? What balance between visibility and gameplay impact?