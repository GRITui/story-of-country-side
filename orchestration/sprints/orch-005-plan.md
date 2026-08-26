# ORCH-005 Sprint Plan — "Player Identity + Cooking"

**Owner:** Product Owner (ox-alpha)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** READY
**Timebox:** <=90 min wall-clock
**Squad mix:** eng-backend, fe-ui, content-writer, qa-tester

## Sprint goal

Give the player a visible body (#100) and a reason to farm beyond shipping (#109 cooking). After this sprint: the player sees their avatar moving in world scenes, can cook harvested crops into stamina-restoring food, and the core loop gains a "grow → cook → eat → do more" cycle that wasn't possible before.

## Issues addressed

| Issue | Priority | Lane |
|-------|----------|------|
| #100 Player avatar: visible main character in world scenes | P2 | Frontend |
| #109 Cooking & eating: turn produce into stamina food | P2 | Backend + Frontend |
| #94 UX polish batch: live hotbar, last-location persistence | P3 | Frontend |

## Tasks

### T1 — Cooking system (backend, #109)
- Branch: `feature/eng-109-cooking`
- New `CookingManager` autoload + `RecipeDefinition` Resource in `scripts/cooking/`.
- Recipes: Parsnip Soup (parsnip + 50g → +30 stamina), Veggie Medley (tomato + pumpkin → +50 stamina), Fish Stew (any fish → +40 stamina). Placeholder values, documented.
- `cook(recipe_id)`: validates ingredients in InventoryManager, removes them, credits stamina via StaminaManager, adds Cooking XP via SkillManager.
- `get_available_recipes()`: returns recipes whose ingredients the player currently has.
- SaveManager integration.
- **Acceptance:** cook() consumes ingredients and restores stamina; invalid recipes rejected; full suite green.

### T2 — Player avatar (frontend, #100)
- Branch: `frontend/player-avatar`
- New `PlayerAvatar` scene (CharacterBody2D + Sprite2D with procedural art from Art Squad's existing `procedural_character_art.gd` pattern).
- Player-controlled movement via T1-ORCH-004's input map (`move_up/down/left/right` actions).
- Placed in each world scene (FarmScene, RanchScene, etc.) at a default spawn point.
- Camera2D follows the player (replaces the current static camera).
- **Acceptance:** player avatar visible and movable in all four world scenes; camera follows; no collision with tile objects; full suite green.

### T3 — UX polish: live hotbar + location persistence (frontend, #94)
- Branch: `frontend/ux-polish-94`
- Hotbar reflects current InventoryManager contents (icons/counts update on `item_changed` signal).
- Last-location persistence: on scene swap via MapOverlay, remember last position and respawn there.
- Intro advance hint: small "Press E" prompt after intro narration completes.
- **Acceptance:** hotbar updates live when items change; returning to a scene places player at last position; full suite green.

### T4 — Sprint QA gate (qa-tester)
- Full suite + smoke boot + E2E: new game → avatar moves → plant → harvest → cook → eat → stamina restored → ship.
- Deliverable: pass/fail + defect list.

## Dependencies & sequencing

```
T1 (cooking) ──┐
T2 (avatar)  ──┤── T4 (QA gate)
T3 (UX polish) ┘
```

T1, T2, T3 independent (disjoint systems). T4 waits for all three.

## Retro hook

Retrospective 5 reviews: does the avatar make the world feel inhabited? Does cooking add meaningful decision-making? Was the hotbar polish worth the time?
