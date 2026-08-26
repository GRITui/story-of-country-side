# ORCH-008 Sprint Plan — "Seasonal Music + Marriage Polish + World Expansion"

**Owner:** Product Owner (ox-alpha)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** READY
**Timebox:** <=120 min wall-clock
**Squad mix:** eng-backend, fe-ui, content-writer, art-squad, qa-tester

## Sprint goal

Replace procedural sine drones with seasonal music (#113), make marriage feel like a real event (#111), and open up the world with two new map regions (#105, #107). After this sprint: the game has ambient seasonal music, a complete marriage ceremony flow, and the player can travel to a sea coast and mountain region.

## Issues addressed

| Issue | Priority | Lane |
|-------|----------|------|
| #113 Real seasonal music | P3 | Backend (Audio) |
| #111 Marriage presentation: heart events + proposal + wedding | P2 | Backend + Frontend |
| #105 Sea coast map: pier scene | P2 | Frontend |
| #107 Mountain region map | P2 | Frontend |

## Tasks

### T1 — Seasonal music (backend/audio, #113)
- Branch: `feature/eng-113-seasonal-music`
- AudioManager: replace sine drone with per-season ambient loop. Source: search for CC0 music packs (Kenney "Music Jingles" / "RPG Audio" via GitHub mirrors, or OpenGameArt).
- If no fitting free music found: generate improved procedural music (chord progressions, not single sine tones) as a better placeholder.
- Festival jingle: short (3-5 sec) tune on `festival_started`.
- Season changes swap the ambient track.
- **Acceptance:** music plays on boot; changes on season; festival jingle fires; no ObjectDB leaks; full suite green.

### T2 — Marriage ceremony presentation (backend + frontend, #111)
- Branch: `feature/eng-111-marriage-presentation`
- Backend: MarriageManager.gd — flesh out `propose()` flow: requires 10 hearts + Pendant item in inventory. `marry()` triggers wedding ceremony scene.
- New `WeddingScene.tscn`: simple ceremony with NPC + player avatar, dialogue lines, "Married!" notification.
- Heart events: at 2/4/6/8/10 hearts, fire `heart_event_triggered` with dialogue (already plumbed in PR #82, just needs content for each milestone).
- Content: write 30 heart event dialogue lines (5 milestones × 6 NPCs) + wedding vows.
- **Acceptance:** propose requires 10 hearts + pendant; wedding scene plays; heart events fire at milestones with dialogue; full suite green.

### T3 — Sea coast map (frontend, #105)
- Branch: `frontend/sea-coast-map`
- New `scenes/world/SeaCoastScene.tscn` + `scripts/world/sea_coast_scene.gd`.
- Pier area with fishing spots (connects to existing FishingManager pools).
- Sandy beach tiles, water edge, a pier structure.
- MapOverlay: add "Sea Coast" travel option.
- **Acceptance:** player can travel to Sea Coast; fishing works from the pier; scene renders with procedural/CC0 art; full suite green.

### T4 — Mountain region map (frontend, #107)
- Branch: `frontend/mountain-region-map`
- New `scenes/world/MountainScene.tscn` + `scripts/world/mountain_scene.gd`.
- Mountain entrance leading to MineScene (travel_to mine from mountain).
- Rocky terrain, mine cart tracks, cave entrance.
- MapOverlay: add "Mountain" travel option.
- **Acceptance:** player can travel to Mountain; mine entrance connects to MineScene; scene renders; full suite green.

### T5 — Sprint QA gate (qa-tester)
- Full suite + smoke boot + E2E: boot → seasonal music plays → travel to sea coast → fish from pier → travel to mountain → enter mine → return to farm → reach 10 hearts → propose → wedding scene.
- Deliverable: pass/fail + defect list.

## Dependencies & sequencing

```
T1 (music)          ──┐
T2 (marriage)       ──┤
T3 (sea coast)      ──┼── T5 (QA gate)
T4 (mountain)       ──┘
```

T1-T4 independent. T5 waits for all.

## Retro hook

Retrospective 8 reviews: does seasonal music improve atmosphere? Does the marriage ceremony feel earned? Do the new regions expand gameplay meaningfully or just add walking distance? Final sprint retro — assess overall velocity across ORCH-004 through ORCH-008.
