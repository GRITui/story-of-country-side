# ORCH-004 Sprint Report — "Seed Economy + Controls + Sleep"

**Date:** 2026-08-26
**Sprint:** ORCH-004
**Status:** SHIPPED (1081/1081 tests pass)
**Timebox:** ~60 min wall-clock (under budget)

## Summary

Closed the three most critical gameplay gaps from Super User's playtest in one parallel sprint. After this sprint a new player can: boot → receive starter seeds → buy seeds from a shop → plant (consumes seed) → skip to next day via bed → ship → earn gold overnight.

## Tasks completed

| Task | Agent | Branch | Files | Tests |
|------|-------|--------|-------|-------|
| T1: Seed economy | eng-backend | `feature/eng-91-seed-economy` | shop_manager.gd, seed_definition.gd, farm_plot_manager.gd, inventory_manager.gd, quest_manager.gd, quest_condition.gd | +181 lines tests |
| T2: Input map | fe-ui | `feature/eng-101-input-map` | input_map_manager.gd, main_controller.gd | +76 lines tests (6 new) |
| T3: Sleep interaction | fe-ui | `frontend/sleep-interaction` | time_manager.gd, sleep_system.gd, sleep_zone.gd, sleep_overlay.gd, fade_transition.gd, morning_notification.gd, main_controller.gd | +tests (12 new) |

## Merge resolution

- T1 → base: fast-forward, clean
- T2 → base: auto-merge, clean
- T3 → base: conflict in `main_controller.gd` (T2 added `get_movement_vector()`, T3 added sleep zone functions — resolved by keeping both)
- Autoload order fix: `ShopManager` moved after `ShippingBinManager` and `InventoryManager` in project.godot (compile error otherwise)

## Test results

```
ALL TESTS PASSED (1081 checks)
```

Up from 992 checks on the base branch before this sprint. Non-fatal warnings: `ObjectDB` leak at exit (pre-existing), one missing WAV asset reference (pre-existing), one JSON parse test (pre-existing).

## What shipped

### Seed Economy (#91) — P1 CLOSED
- `ShopManager` autoload: `list_seeds()`, `buy_seed()`, `get_seed_price()`
- `SeedDefinition` Resource: seed_id, crop_id, price, season
- `FarmPlotManager.plant()`: rejects without seed, consumes 1 seed on success
- Starter grant: 15 parsnip seeds on new game
- `EARN_GOLD` quest condition type: tracks lifetime gold earned via ShippingBinManager.payout_processed

### Input Map (#101) — P2 CLOSED
- `InputMapManager` autoload: 16 input actions (WASD/arrows, E/Enter, Escape, 1-9)
- `MainController.get_movement_vector()`: normalized keyboard movement

### Sleep / Day-Skip (#93) — P2 CLOSED
- `TimeManager.advance_day()`: public API for immediate day advance
- `SleepZone` Area2D + `SleepSystem` orchestrator: confirmation dialog → fade-to-black → advance_day → fade-in → morning notification
- `FadeTransition` CanvasLayer + `MorningNotification` HUD element

## Issues closed

- GitHub #91 (Seed economy) — P1
- GitHub #101 (Input map) — P2
- GitHub #93 (Sleep / day-skip) — P2

## Issues still open (next sprint candidates)

- #100 Player avatar (P2) — disembodied cursor
- #102 NPC visibility (P2) — social systems invisible
- #109 Cooking (P2) — no grow→consume loop
- #96 Price registry (P2) — scattered prices
- #112 Weather depth (P3) — rain does nothing
- #110 Birthdays (P2) — no birthday system

## Retro notes

1. **Parallel branching worked** — 3 independent tasks completed in ~60 min vs ORCH-001's serial approach.
2. **Autoload ordering is a recurring trap** — new autoloads placed before their dependencies. Recommend: always put new autoloads at the END of the list, before SaveManager.
3. **main_controller.gd is a conflict magnet** — touched by multiple frontend tasks. Consider splitting sleep logic into its own scene controller.
4. **T3 agent hit T1's unmerged compile errors** — expected and correct behavior (separate branches, merge after). The agent correctly flagged it rather than trying to fix the other branch.
