# ORCH-004 Sprint Plan — "Seed Economy + Controls + Sleep"

**Owner:** Product Owner (ox-alpha)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** READY
**Timebox:** <=90 min wall-clock
**Squad mix:** eng-backend, fe-ui, qa-tester

## Sprint goal

Close the three most critical gameplay gaps from Super User's playtest: seeds are free/infinite (#91), there's no keyboard/gamepad input (#101), and day-skip forces 171 real seconds of waiting (#93). After this sprint a new player can: boot → receive starter seeds → buy seeds from shop → plant (consumes seed) → skip to next day via bed → ship → earn gold overnight.

## Issues addressed

| Issue | Priority | Lane |
|-------|----------|------|
| #91 Seed economy: seeds as items + starting grant + purchase path | P1 | Backend |
| #101 Define a control scheme + input map | P2 | Backend + Frontend |
| #93 Sleep / day-skip interaction | P2 | Frontend |

## Tasks

### T1 — Seed economy core (backend, #91)
- Branch: `feature/eng-91-seed-economy`
- **Recover from stale ORCH-003 worktree** (`/Users/grit/soc-orch/eng-backend`): `shop_manager.gd`, `seed_definition.gd`, seed-consumption changes in `farm_plot_manager.gd` / `inventory_manager.gd` / `save_manager.gd` / `project.godot`. Do NOT take festival_manager rewrites, title-screen deletions, or backlog/report deletions.
- Add `EARN_GOLD` condition type to QuestManager (~10 lines, existing condition pattern): listens to `ShippingBinManager.payout_processed`, tracks lifetime earned gold, completes when >= target.
- ShipManager.gd: add `list_seeds()`, `buy_seed(seed_id)` reducing gold, `get_seed_price(seed_id)`.
- FarmPlotManager.plant(): reject if no seed in inventory, consume 1 seed on success.
- New game starter grant: 15 parsnip seeds via InventoryManager on `new_game()`.
- **Acceptance:** plant() fails without seed / succeeds+consumes with seed; grant applies on new_game() only; list_seeds()/buy_seed() reduce gold; EARN_GOLD quest completes on payout; FULL suite green headless.

### T2 — Input map + basic controls (backend + frontend, #101)
- Branch: `feature/eng-101-input-map`
- Register Godot InputMap actions in an autoload `InputMapManager` (or at project.godot level): `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `menu`, `hotbar_1` through `hotbar_9`. Default: WASD/arrows for movement, E/Enter for interact, Escape for menu, 1-9 for hotbar.
- Update `main_controller.gd` to accept keyboard movement (not just mouse click) for world scene transitions.
- Frontend: add input action hints to HUD (e.g. "E to interact" tooltip when near interactable).
- **Acceptance:** player can navigate FarmScene with WASD/arrows; interact with tiles via E key; open/close pause menu with Escape; full suite green.

### T3 — Sleep / day-skip interaction (frontend, #93)
- Branch: `frontend/sleep-interaction`
- Add a sleep zone (Area2D) in Main.tscn or each world scene near a "bed" node. When player enters and presses interact → confirmation dialog → `TimeManager.advance_day()` (or equivalent, skipping to next morning).
- If TimeManager has no public `advance_day()`, add one (Backend task, tiny — triggers `_on_day_started` manually).
- Visual feedback: fade-to-black transition, then morning state.
- **Acceptance:** player can skip to next day in < 5 seconds of real time; TimeManager state advances correctly; save/load round-trips the new day; full suite green.

### T4 — Sprint QA gate (qa-tester)
- Pull merged base; headless import pass; full TestRunner suite; smoke boot (`--quit-after 60`); contract sweep over all new diffs.
- Scripted new-player arc E2E: new game → starter grant → buy seed → plant consumes → ship → payout → EARN_GOLD quest completes → sleep skips to next day.
- Deliverable: pass/fail per acceptance criterion + defect list (P0-P4).

## Dependencies & sequencing

```
T1 (seed economy) ──┐
T2 (input map)   ───┤── T4 (QA gate)
T3 (sleep)       ───┘
```

T1, T2, T3 are independent (touching disjoint systems) and can run in parallel. T4 waits for all three to merge.

## Process conventions

- Engineers work in isolated worktrees under `/Users/grit/soc-orch/`.
- PO performs ALL remote operations (push / PR / squash-merge) using standing self-merge authorization.
- PO posts claim comments on claimed issues at dispatch time.
- Ledger consolidation: PO writes consolidated `backlog-inbox.md` task_items + STANDUP entries post-merge.
- Findings use P0-P4 severity from SUPERUSER.md.

## Retro hook

Retrospective 4 reviews: did seed economy + input + sleep close the "first session that matters" loop? Was the ORCH-003 branch recovery worth it vs rewriting fresh? Feedback appended to backlog-inbox.md.
