# ORCH-006 Sprint Plan — "NPC Visibility + Weather Depth + Birthdays"

**Owner:** Product Owner (ox-alpha)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** READY
**Timebox:** <=90 min wall-clock
**Squad mix:** eng-backend, fe-ui, content-writer, qa-tester

## Sprint goal

Make the social world feel alive: NPCs walk around visible in scenes (#102), rain has gameplay effect (#112), and villagers have birthdays (#110). After this sprint: NPCs appear at their scheduled locations, rain auto-waters crops, and the player can give birthday gifts for bonus friendship.

## Issues addressed

| Issue | Priority | Lane |
|-------|----------|------|
| #102 Instantiate NPCs in world scenes | P2 | Frontend |
| #112 Weather depth: rain waters crops | P3 | Backend |
| #110 Villager birthdays + season calendar overlay | P2 | Backend + Content |

## Tasks

### T1 — NPC instantiation in world scenes (frontend, #102)
- Branch: `frontend/npc-instances`
- Each world scene spawns NPCController instances for NPCs scheduled to be in that location.
- NPCController already reads NPCSchedule + NPCController.gd — just needs scene placement.
- NPCs render with Art Squad's `procedural_character_art.gd` silhouette (already shipped in PR #79).
- NPCs move between schedule waypoints; idle animation at destination.
- **Acceptance:** at least 2 NPCs visible in FarmScene during Spring morning; they move on schedule; player can talk (E key near NPC, shows gift preference hint); full suite green.

### T2 — Weather depth: rain auto-waters (backend, #112)
- Branch: `feature/eng-112-weather-depth`
- WeatherManager: on `Rainy`, call `FarmPlotManager.water()` on every planted plot (same pattern as InfrastructureManager's sprinkler_system).
- On `Snowy` in Winter: no auto-water (crops are withered or dormant).
- Rare storm event: 5% chance on Rainy → `Stormy`, drains 20 stamina (thematic hazard).
- Signal: `weather_depth_applied` for HUD feedback.
- **Acceptance:** rain waters all planted crops automatically; storm drains stamina; full suite green.

### T3 — Villager birthdays (backend + content, #110)
- Branch: `feature/eng-110-birthdays`
- BirthdayManager autoload: each NPC has a birthday (day + season). On `TimeManager.day_started`, check if any NPC's birthday matches → fire `npc_birthday_started(npc_name)` signal.
- Gift multiplier: 2x friendship points when gifting on a birthday (RelationshipManager integration).
- Content: assign birthday dates to all 6 marriageable NPCs (content lane values).
- Frontend: birthday indicator on HUD when it's someone's birthday.
- **Acceptance:** birthday signal fires on correct day; 2x gift multiplier works; content values registered; full suite green.

### T4 — Sprint QA gate (qa-tester)
- Full suite + smoke boot + E2E: boot → rain day → crops auto-watered → NPC visible walking → give birthday gift → 2x hearts.
- Deliverable: pass/fail + defect list.

## Dependencies & sequencing

```
T1 (NPC instances) ──┐
T2 (weather depth)  ──┤── T4 (QA gate)
T3 (birthdays)      ──┘
```

T1, T2, T3 independent. T4 waits for all.

## Retro hook

Retrospective 6 reviews: do NPCs feel alive or just decorative? Does rain auto-water reduce tedium or remove meaningful choice? Are birthdays discoverable without reading code?
