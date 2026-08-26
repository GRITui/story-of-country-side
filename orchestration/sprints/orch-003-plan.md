# ORCH-003 Sprint Plan — "First Session That Matters"

**Owner:** Product Owner (ox-alpha orchestration session)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** IN_PROGRESS (dispatched 2026-08-26)
**Timebox:** <=120 min wall-clock
**Squad mix:** eng-backend, fe-ui, content-writer, qa-tester
(fresh roster for this sprint; prior sprint mixes not reused blindly)

## Sprint goal

A new player can: boot -> receive starter seeds -> buy seeds -> plant
(consumes a seed) -> ship produce -> earn overnight gold -> follow a
visible starter quest chain. Closes GitHub #91 end-to-end and most of
GitHub #108.

## Key discovery at planning

The ORCH-001-era branch `feature/eng-90-91-core-loop-integrity`
(worktree `/Users/grit/soc-orch/eng-backend`) holds valuable unmerged
seed-economy work (shop_manager.gd, seed_definition.gd, plant()
consumption, starter grant) but was cut BEFORE PR #99 (title screen)
and PR #104 (festival boot rederivation) merged — a straight merge
would revert shipped work. T1 therefore RECOVERS selected files onto
fresh base rather than merging the branch.

## Tasks

### T1 — Seed-economy recovery + EARN_GOLD quest condition (backend, #91 + #108 enabler)
- Branch: `feature/eng-91-seed-economy-recovery` off current base.
- Recover from the stale branch ONLY: `scripts/autoload/shop_manager.gd`,
  `scripts/farming/seed_definition.gd`, and the seed-related deltas in
  `farm_plot_manager.gd` / `inventory_manager.gd` / `save_manager.gd` /
  `project.godot`. Do NOT take its festival_manager.gd rewrites,
  title-screen deletions, backlog/report deletions.
- Add EARN_GOLD condition type to QuestManager (~10 lines, existing
  condition pattern): listens to `ShippingBinManager.payout_processed`,
  tracks lifetime earned gold, completes when >= target. Interface
  contract published to content lane before dispatch.
- Acceptance: plant() fails without seed / succeeds+consumes with seed;
  grant applies on new_game() only; list_seeds()/buy_seed() reduce gold;
  EARN_GOLD quest completes on payout; FULL suite green headless.

### T2 — Starter quest chain content (content lane, #108)
- Branch: `content/starter-quest-chain`.
- New `scripts/quests/starter_content.gd` registering through the
  EXISTING QuestManager API: "Off Your Chest" (ship 3 items),
  "First Coin" (EARN_GOLD per T1 contract), "A Friendly Face"
  (1 heart any villager), stretch "Something From Everywhere".
- Deliberately NO plant-a-seed step beyond seed-consumption reality
  (#108 ordering note). Rewards small gold via payout path.
- Values documented; test-assertion updates allowed per convention.

### T3 — HUD active-quest tracker line (frontend, #108 UI footprint)
- Branch: `frontend/quest-tracker-hud`.
- ONE active quest line in HUD adjacent to hotbar area, consuming only
  QuestManager public API/signals. Full quest-log UI out of scope.

### T4 — Shop overlay UI (frontend, #91 part B) — BLOCKED by T1 merge
- Branch: `frontend/shop-overlay`.
- Overlay lists seeds, buy buttons, gold display; ShopManager public
  API + signals only (contract rule).

### T5 — Sprint QA gate (qa-tester) — BLOCKED by T1..T4 merge
- Pull merged base; headless import pass; full TestRunner suite;
  smoke boot (`--quit-after 60`); contract sweep over all new diffs;
  scripted new-player arc E2E: new game -> starter grant -> buy ->
  plant consumes -> ship -> payout -> First Coin completes.
- Deliverable: pass/fail per acceptance criterion + defect list (P0-P4).

## Process conventions (unchanged from ORCH-001)

- Engineers work in isolated worktrees under `/Users/grit/soc-orch/`;
  PO performs ALL remote operations (push / PR / squash-merge) using
  the documented standing self-merge authorization, after reviewing diffs.
- PO posts claim comments on claimed issues at dispatch time.
- Ledger consolidation: PO writes consolidated `backlog-inbox.md`
  task_items + STANDUP entries post-merge.
- Findings use the P0-P4 scale from SUPERUSER.md.

## Retro hook

Retrospective 3 reviews velocity vs the 30-120 min box, the recovery
play (salvaging stranded branch work), and cross-lane interface-contract
effectiveness; feedback appended to backlog-inbox.md (next candidates:
#96 price registry, embodiment cluster #100-#102 sizing, #120 decision).
