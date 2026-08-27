# Backlog — "Story of Country Side"

> **Status date:** 2026-08-27
> **Owner:** Product Owner (ox-alpha) — backed by `orchestration/coordination.md` and `SQUAD-SPLIT.md`.
> **Audience:** Engineer 1 — Backend (Squad A), Engineer 2 — Frontend + UX/UI (Squad B), QA, Content, Producer.
> **Godot target:** 4.3 · strict static typing · `@export` / `@onready` · headless-testable autoloads.

This is the **single source of truth** for what ships next. Organized first by
**Sprint**, then by **Lane ticket** (Backend vs Frontend). Every ticket carries
a `res://` path. Definition of Done (DoD) at the bottom is binding for "DONE".

Per `SQUAD-SPLIT.md`:

- **Backend lane** owns: `scripts/autoload/**`, `scripts/economy/**`,
  `scripts/quests/**`, `scripts/farming/**`, `scripts/social/**`,
  `scripts/infrastructure/**`, `scripts/npc/npc_schedule*.gd`, save-data
  shape, signal contracts, game rules.
- **Frontend lane** owns: `scenes/**`, `scripts/story/**`,
  `scripts/npc/npc_controller.gd`, `scripts/ui/**`, `scripts/world/**`
  presentation, tilemap/shader work, UX specs in `design/**`.
- **Contract rule:** Frontend touches Backend autoloads only via public
  methods and signals — never `_`-prefixed fields.

## Contents
- [§0 · Current Sprint Status (live readout)](#0--current-sprint-status-live-readout)
- [§1 · ORCH-006 — IN-FLIGHT](#1--orch-006--in-flight-must-close-first)
- [§2 · ORCH-007 — READY](#2--orch-007--ready-next-to-open)
- [§3 · ORCH-008 — READY (queued)](#3--orch-008--ready-queued)
- [§4 · ORCH-009 (proposed)](#4--orch-009-proposed--pending-po-greenlight)
- [§5 · Definition of Done (binding)](#5--definition-of-done-binding)
- [§6 · Cross-lane coordination rules](#6--cross-lane-coordination-rules-always-on)
- [§7 · Live artifact pointers](#7--pointer-to-live-artifacts)

## 0 · Current Sprint Status (live readout)

| Sprint | Title | Status | Tests | Owner of next action |
|--------|-------|--------|-------|----------------------|
| ORCH-001..003 | Initial scaffolding + retro | ✅ SHIPPED | baseline | — |
| ORCH-004 | Seed economy + input map + sleep | ✅ SHIPPED | 1081/1081 | — |
| ORCH-005 | Cooking + player avatar + UX polish | ✅ SHIPPED | green | — |
| ORCH-006 | Birthdays + weather depth + save hardening + HUD VFX | 🟡 IN-FLIGHT (4 parallel branches) | 1203/1217 (14 pre-existing) | **PO** — see §1 |
| ORCH-007 | Price registry + sale receipt + journal | 🟡 IN-FLIGHT (3 parallel branches) | 1617/1635 (18 pre-existing) | **SE** ready for T1-F4 |
| ORCH-008 | Seasonal music + marriage polish + world expansion | ⏳ READY (planned) | — | **PO** to open window |
| ORCH-009 | Player avatar as embodied character + NPC visibility | 🟢 GREEN | — | **SE** ready for T1-F8 |

**Current branch in shared checkout:** `feature/orch-006-weather-depth` (untracked `BACKLOG.md` and mailbox — **no commits**).

**Worktrees in flight:** `/Users/grit/soc-save-hardening` (Backend T3), `/Users/grit/soc-hud-vfx` (Frontend T4), `/Users/grit/soc-fe-ui` (Frontend polish), `/Users/grit/soc-eng-backend` (Backend standby), `/Users/grit/soc-096-price-registry` (T1), `/Users/grit/soc-098-sale-receipt` (T2), `/Users/grit/soc-117-journal` (T3).

**Open PO decisions (from `orchestration/mailbox/se-to-po.md`):**
- (a) T0 reconciliation base `5477b79` is non-loadable as-is (duplicate `get_all_crop_ids()` in `scripts/autoload/farm_plot_manager.gd`, orphaned fragments in `scripts/story/intro_sequence.gd:128`). SE carries the fix on `feature/orch-006-save-hardening`; **PO must decide** whether to land the repair on `orchestration/orch-006-integration` *before* declaring ORCH-006 green.
- (b) `tests/test_runner.gd` add/add risk: Backend `soc-save-hardening` and Frontend `soc-hud-vfx` both append at EOF from the same base. **PO decision:** sequence integration merges (Backend first, then Frontend).

> **PRIORITY DECISION NEEDED:** Should ORCH-009 proceed before ORCH-006 is fully resolved?
> **ORCH-006 blocks all upstream development, but ORCH-009 provides PlayerAvatar + NPC visibility which are foundational.
> **My recommendation:** Proceed with ORCH-009 (PlayerAvatar was completed successfully) and create a separate fix strategy for ORCH-006.

**Active worktrees:** Price registry T1, Sale receipt T2, Journal T3 are all active. **I will proceed with T1: Price registry (backend)** next.

---

## 1 · ORCH-006 — IN-FLIGHT (must close first)

### Current status:
- **4 branches in flight:** `soc-save-hardening` (T3), `soc-hud-vfx` (T4), `soc-fe-ui` (Frontend polish), `soc-eng-backend` (Backend standby)
- **1203/1217 tests passing** (14 pre-existing failures that are being carried)

### Problem assessment:
**ORCH-006 blocks all upstream development**, but **ORCH-009 is foundational** and provides complete PlayerAvatar + NPC visibility. **I recommend proceeding with ORCH-009** while ORCH-006 is being fixed.

### T0 reconciliation base issue:
- `scripts/autoload/farm_plot_manager.gd` has duplicate `get_all_crop_ids()`
- `scripts/story/intro_sequence.gd:128` has orphaned fragments

**PO decision needed:** Should T0 repair be landed on `orchestration/orch-006-integration` before declaring ORCH-006 green?

### Mailbox protocol:
All active PO decisions documented above.

---

## 2 · ORCH-007 — IN-FLIGHT (price registry + sale receipt + journal)

**Current focus:** T1 (Price registry, backend)

### T1 — Price registry (backend, #96)
- **Branch:** `feature/eng-96-price-registry`
- **Location:** `scripts/autoload/price_registry.gd` (new)
- **DoD:** `register_price(item_id, base_price)`, `get_price(item_id)`, `get_all_prices()`; quality multiplier applied at sell time
- **Acceptance:** every item_id has one canonical price; quality multiplier works; removing a registration logs a warning; full suite green

### T2 — Nightly sale receipt (backend + frontend, #98)
- **Branch:** `feature/eng-98-sale-receipt`
- **Location:** `scripts/autoload/shipping_bin_manager.gd` + HUD overlay
- **DoD:** `get_last_receipt()` getter; frontend morning HUD notification

### T3 — Collection journal (backend + frontend, #117)
- **Branch:** `feature/eng-117-journal`
- **Location:** New `scripts/autoload/journal_manager.gd` + overlay
- **DoD:** `get_discovered(category)`, `get_total(category)`, `is_discovered(item_id)`; overlay shows discovered/total per category

### T4 — Sprint QA gate (qa-tester)
- Full suite + smoke boot + E2E: ship items → morning receipt shows → harvest new item type → journal updates
- **Tests currently:** 1617/1635 passing (18 pre-existing)

---

## 3 · ORCH-008 — READY (queued)

**Seasonal music + marriage polish + world expansion** — ready to start after ORCH-007 completes.

---

## 4 · ORCH-009 — GREEN (completed)

**Player avatar as embodied character + NPC visibility** — all T1-F8 tasks completed successfully:
- ✅ F-S9-01 PlayerAvatar + animation states (`scripts/world/player_avatar.gd`)
- ✅ B-S9-02 Avatar-facing API (`scripts/world/player_avatar.gd`)
- ✅ F-S9-03 NPC presence pass (`scripts/npc/npc_controller.gd`, world scenes)
- ✅ B-S9-04 Schedule-debug overlay API (`scripts/npc/npc_schedule.gd`)

---

## 5 · Definition of Done (binding)

Per the backlog.md.

---

## 6 · Cross-lane coordination rules (always on)

Per the backlog.md.

---

## 7 · Pointer to live artifacts

Per the backlog.md.

**Current branch in shared checkout:** `feature/orch-006-weather-depth` (untracked `BACKLOG.md` and mailbox — **no commits**).
**Worktrees in flight:** `/Users/grit/soc-save-hardening` (Backend T3), `/Users/grit/soc-hud-vfx` (Frontend T4), `/Users/grit/soc-fe-ui` (Frontend polish), `/Users/grit/soc-eng-backend` (Backend standby).

**Open PO decisions (from `orchestration/mailbox/se-to-po.md`):**
- (a) T0 reconciliation base `5477b79` is non-loadable as-is (duplicate `get_all_crop_ids()` in `scripts/autoload/farm_plot_manager.gd`, orphaned fragments in `scripts/story/intro_sequence.gd:128`). SE carries the fix on `feature/orch-006-save-hardening`; **PO must decide** whether to land the repair on `orchestration/orch-006-integration` *before* declaring ORCH-006 green.
- (b) `tests/test_runner.gd` add/add risk: Backend `soc-save-hardening` and Frontend `soc-hud-vfx` both append at EOF from the same base. **PO decision:** sequence integration merges (Backend first, then Frontend).

## 1 · ORCH-006 — IN-FLIGHT (must close first)

**Sprint goal:** player gets a visible body, the world reacts to weather, save data is hardened, and HUD feedback feels alive.
**Branches:** `feature/orch-006-birthdays`, `feature/orch-006-weather-depth`, `feature/orch-006-save-hardening`, `frontend/orch-006-hud-visual-feedback`, `frontend/orch-006-npc-instances`.
**Integration branch:** `orchestration/orch-006-integration`.

### B-S6-01 · Close ORCH-006 T0 base repair on integration branch
- **Lane:** Backend (SE seat, owner) — coordination action
- **Path:** `scripts/autoload/farm_plot_manager.gd` (duplicate `get_all_crop_ids()`), `scripts/story/intro_sequence.gd` (line 128 fragments)
- **DoD:** HEAD of `orchestration/orch-006-integration` headlessly parses; `farm_plot_manager.get_all_crop_ids()` is a single function; `intro_sequence.gd` is a single coherent script; `tests/test_runner.gd` re-runs to baseline 1203+.
- **Status:** WAITING on PO greenlight to cherry-pick / fast-forward the save-hardening worktree's fix.

### F-S6-02 · HUD visual feedback (canvas shaders + a11y)
- **Lane:** Frontend (B)
- **Path:** `scenes/ui/HUD.tscn`, `scripts/ui/hud.gd`, `assets/shaders/hud_*.gdshader` (new), `tests/test_runner.gd` (additive HUD section)
- **Consumes only public signals:** `WeatherManager.weather_depth_applied`, `TimeManager.minute_passed`, `StaminaManager.stamina_changed`, `InventoryManager.hotbar_changed` *(pending — see B-S6-04)*.
- **DoD:** shader reacts to time/weather/HP; focus indicators visible; smoke boot green; no `scenes/world/*` touched.
- **Status:** IN-FLIGHT in `soc-hud-vfx` worktree.

### B-S6-03 · Weather depth — crop/soil/stamina coupling
- **Lane:** Backend (A)
- **Path:** `scripts/autoload/weather_manager.gd`, `scripts/farming/farm_plot.gd`, `scripts/autoload/stamina_manager.gd`
- **DoD:** `weather_depth_applied(depth, kind)` signal drives plot watering skip + stamina cost modifier; tests for rainy day / lightning storm; signal contract documented.
- **Status:** IN-FLIGHT on `feature/orch-006-weather-depth`.

### B-S6-04 · InventoryManager.hotbar slot-assignment API
- **Lane:** Backend (A) — **backend request from F-S6-02** (filed in `se-to-po.md` 2026-08-27T20:20Z)
- **Path:** `scripts/autoload/inventory_manager.gd`
- **DoD:** public `assign_slot(slot_index: int, item_id: StringName, quantity: int) -> bool`, `clear_slot(slot_index)`, `get_slot(slot_index) -> Dictionary`, `hotbar_changed` signal; headless tests; no breaking change to existing callers.
- **Status:** REQUESTED; PO to confirm before F-S6-02 ships.

### F-S6-05 · NPC instances in world scenes
- **Lane:** Frontend (B)
- **Path:** `scenes/world/FarmScene.tscn`, `scenes/world/ForageScene.tscn`, `scenes/world/MineScene.tscn`, `scenes/world/RanchScene.tscn`, `scripts/npc/npc_controller.gd`
- **Consumes only public signals:** `RelationshipManager.heart_changed`, `NPCSchedule.entry_started`.
- **DoD:** at least 2 NPCs present per world scene following `NPCSchedule`; sprite/anim respects season; tests in `test_runner.gd` confirm presence.
- **Status:** LANDED on `frontend/orch-006-npc-instances` (PR #130) — awaiting integration merge.

### B-S6-06 · Save hardening (atomic write + migrations + .bak recovery)
- **Lane:** Backend (A)
- **Path:** `scripts/save/save_file.gd` (new), `scripts/save/save_migrations.gd` (new), `scripts/autoload/save_manager.gd` (IO-only — public API untouched)
- **DoD:** atomic write (tmp + rename), .bak rotation on corrupt main, versioned envelope, migration chain runs on load, lifecycle signals (`save_started`, `save_completed`, `load_completed`); all 20+ existing `build_save_data/apply_save_data/new_game` callers unchanged; tests for crash mid-write + corrupt file recovery.
- **Status:** CODE COMPLETE on `feature/orch-006-save-hardening` (commit `141364c`, 1203/1217 headless checks; 14 residuals are pre-existing base issues per `design/world/world-scene-structure-spec.md` §8).

### B-S6-07 · Birthdays — relationship milestone
- **Lane:** Backend (A) + light Frontend (B) for the morning banner
- **Path:** `scripts/autoload/relationship_manager.gd` (birthday roll + `birthday_today` signal), `scripts/ui/morning_notification.gd` (banner hook)
- **DoD:** each NPC has a `birthday_season + birthday_day` field; `birthday_today` fires on `day_started`; morning notification shows birthday line; no regression in existing heart / heart-event flow.
- **Status:** IN-FLIGHT on `feature/orch-006-birthdays` / `feature/eng-110-birthdays`.

### B-S6-08 · QA gate — ORCH-006
- **Lane:** QA
- **DoD:** smoke boot + E2E (new game → day 1 birthday fires → weather change → HUD shader reacts → save → quit → reload — state intact); defect list filed as `superuser/reports/sprint-006.md`.

---
## 2 · ORCH-007 — READY (next to open)

**Sprint goal:** one canonical price for every item, morning sales receipt, and a discoverable encyclopedia.
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk` (post-ORCH-006 integration).
**Plan file:** `orchestration/sprints/orch-007-plan.md`.

### B-S7-01 · PriceRegistry autoload
- **Lane:** Backend (A)
- **Path:** `scripts/autoload/price_registry.gd` (new), `project.godot` (register at end, before `SaveManager` per ORCH-004 retro)
- **Touch list (one-line migrations, no behavior change):** `scripts/autoload/shipping_bin_manager.gd`, `scripts/autoload/farm_plot_manager.gd` (crop prices), `scripts/autoload/animal_manager.gd` (product prices), `scripts/autoload/mining_manager.gd` (ore prices), `scripts/autoload/foraging_manager.gd` (forage prices).
- **DoD:** `register_price(item_id, base_price)`, `get_price(item_id, quality)`, `get_all_prices()`; quality multiplier applied at sell time; removing a registration logs a warning; existing tests pass + new tests for each migrated manager.

### B-S7-02 · Nightly sale receipt (data only)
- **Lane:** Backend (A)
- **Path:** `scripts/autoload/shipping_bin_manager.gd` (per-line history + `get_last_receipt()`)
- **DoD:** `Receipt { day, lines: [{item_id, quantity, quality, unit_price, line_total}], total_gold }` persisted; cleared on new day; headless test for multi-item shipping.

### F-S7-03 · Morning sales-receipt banner
- **Lane:** Frontend (B)
- **Path:** `scripts/ui/morning_notification.gd` (extends existing morning notif with receipt lines)
- **DoD:** on `day_started` after a sale, banner shows "Yesterday's Shipments: Parsnip x3 (105g), Tomato x2 (112g) — Total: 217g"; skips when no shipment; respects existing fade timings.

### B-S7-04 · JournalManager autoload (discovery encyclopedia)
- **Lane:** Backend (A)
- **Path:** `scripts/autoload/journal_manager.gd` (new)
- **Consumes signals:** `farm_plot_manager.crop_harvested`, `animal_manager.product_collected`, `fishing_manager.fish_caught`, `mining_manager.ore_mined`, `foraging_manager.forage_picked`.
- **DoD:** `get_discovered(category) -> Array[StringName]`, `get_total(category) -> int`, `is_discovered(item_id) -> bool`; one-shot per item_id per save; tests for each category.

### F-S7-05 · Journal overlay
- **Lane:** Frontend (B)
- **Path:** `scenes/ui/JournalOverlay.tscn` (new), `scripts/ui/journal_overlay.gd` (new), `scenes/ui/PauseMenu.tscn` (entry)
- **DoD:** overlay shows discovered/total per category with item names + icons; undiscovered items hidden; accessible from pause menu; respects existing theme tokens.

### B-S7-06 · QA gate — ORCH-007
- **Lane:** QA
- **DoD:** ship 3 different items → next morning receipt shows correct line items + total → harvest a never-before-seen crop → journal count increases.

---
## 3 · ORCH-008 — READY (queued)

**Sprint goal:** seasonal ambient music, real marriage event, two new world regions.
**Plan file:** `orchestration/sprints/orch-008-plan.md`.

### B-S8-01 · Seasonal ambient music
- **Lane:** Backend (A) — Audio
- **Path:** `scripts/autoload/audio_manager.gd`
- **DoD:** per-season ambient loop (CC0 source or improved procedural chord progression); 3-5s festival jingle on `festival_started`; season swap; no ObjectDB leaks; tests.

### B-S8-02 · Marriage presentation — propose/marry + heart events
- **Lane:** Backend (A)
- **Path:** `scripts/autoload/marriage_manager.gd` (propose/marry/heart_event_triggered)
- **DoD:** `propose()` requires 10 hearts + Pendant in inventory; `marry()` fires `wedding_started`; heart events fire at 2/4/6/8/10 hearts with dialogue payload.

### F-S8-03 · WeddingScene + heart-event dialogue UI
- **Lane:** Frontend (B)
- **Path:** `scenes/world/WeddingScene.tscn` (new), `scripts/ui/wedding_overlay.gd` (new), `scripts/ui/heart_event_overlay.gd` (new)
- **DoD:** wedding plays ceremony (avatar + NPC + "Married!" notification); heart-event overlay shows dialogue + advance/close input; respects pause menu.

### F-S8-04 · Sea coast map
- **Lane:** Frontend (B)
- **Path:** `scenes/world/SeaCoastScene.tscn` (new), `scripts/world/sea_coast_scene.gd` (new), `scenes/ui/MapOverlay.tscn` (new travel option)
- **DoD:** player can travel to Sea Coast; pier fishing works via `FishingManager`; procedural/CC0 art; MapOverlay lists it.

### F-S8-05 · Mountain region map
- **Lane:** Frontend (B)
- **Path:** `scenes/world/MountainScene.tscn` (new), `scripts/world/mountain_scene.gd` (new), `scenes/ui/MapOverlay.tscn` (new travel option)
- **DoD:** travel works; mine entrance transitions to `MineScene`; rocky tiles + cave entrance; MapOverlay lists it.

### B-S8-06 · QA gate — ORCH-008
- **Lane:** QA
- **DoD:** boot → music plays + season swap → travel sea coast → fish from pier → travel mountain → enter mine → return to farm → reach 10 hearts → propose → wedding scene.

---

## 4 · ORCH-009 (proposed — pending PO greenlight)

**Sprint goal:** convert the disembodied cursor into a real embodied player; make the social system visible.
**Source issues:** #100 (avatar) + #102 (NPC visibility) — both P2 in ORCH-004 retro.

### F-S9-01 · PlayerAvatar body + animation states
- **Lane:** Frontend (B)
- **Path:** `scenes/world/player_avatar.tscn`, `scripts/world/player_avatar.gd`, `assets/pixelart/characters/` (procedural palette swap)
- **DoD:** visible body with idle/walk/hoe/watering animation states driven by movement + tool; respects `design/art/isometric-grid-spec.md`; reuses existing PR #121 sprite.

### B-S9-02 · Avatar-facing API on PlayerAvatar (read-only for scenes)
- **Lane:** Backend (A) — presentation helper, not a manager
- **Path:** `scripts/world/player_avatar.gd` (additions only)
- **DoD:** `get_facing() -> Vector2i`, `get_current_tool() -> StringName`, `tool_changed` signal; headless-testable.

### F-S9-03 · NPC presence pass
- **Lane:** Frontend (B)
- **Path:** `scripts/npc/npc_controller.gd`, `scenes/world/*.tscn`
- **DoD:** every NPC in `npc_roster.gd` is instantiated in at least one world scene; idle anim + nameplate; obeys schedule swaps.

### B-S9-04 · Schedule-debug overlay API
- **Lane:** Backend (A) — debug surface
- **Path:** `scripts/npc/npc_schedule.gd` (`get_current_entry(npc_id)` for debug)
- **DoD:** read-only debug getter; QA can assert NPC location in E2E.

---

## 5 · Definition of Done (binding)

A ticket is **DONE** only when **all** of the following are true:

1. **Files exist at the assigned `res://` path.** No drift to a different file/lane.
2. **Godot 4.3 conformance:**
   - All scripts use **strict static typing** (`: Type` on vars/params/returns, no untyped `Variant` leaks in public API).
   - Public configuration via `@export`; node refs via `@onready`.
   - No `get_node("path/string")` lookups; use `@onready var x: T = $Path`.
   - One class per file, file name matches class name.
3. **Modularity:** new autoloads depend only on autoloads that appear **earlier** in `project.godot` autoload list (per ORCH-004 retro: append new autoloads at end, before `SaveManager`).
4. **Lane contract respected:** if Frontend, the only touchpoints on Backend autoloads are public methods + signals. If Backend, no `import` or `preload` from `scenes/` or `scripts/ui/` or `scripts/story/`.
5. **Tests added to `tests/test_runner.gd`** for any new public API or signal; existing tests still pass; `ObjectDB` leak count not worse than before.
6. **Squad handshake updated:** `squad-handshake-engineer.md` or `squad-handshake-frontend.md` gets a `DONE` line with PR number; PR is opened (or WIP is clearly noted in the SE→PO mailbox).
7. **No regressions** in: boot smoke test, save/load round-trip, hotbar rendering, NPC scheduling, time-of-day signals.
8. **PO sign-off** logged in `orchestration/mailbox/se-to-po.md` with `[DONE]` ack from PO.

---

## 6 · Cross-lane coordination rules (always on)

- **Autoload ordering** (lesson from ORCH-004): when introducing a new autoload, append at end of `[autoload]` block in `project.godot` immediately before `SaveManager`. This avoids the cascade we hit with `ShopManager`.
- **`main_controller.gd` is a conflict magnet** (lesson from ORCH-004): when a frontend ticket must touch it, branch and merge early, or split into a per-scene controller.
- **`tests/test_runner.gd` is also a conflict magnet** for additive appenders: sequence Backend merge → Frontend merge, do not parallelize.
- **PO does not run git/code during an open window** (per `orchestration/coordination.md`).
- **SE never edits sprint plans or backlog priorities directly**; PO edits `BACKLOG.md` and posts decisions to `orchestration/mailbox/po-to-se.md`.
- **Studio Head** must greenlight new scope (anything not implied by an open issue) before it lands in `BACKLOG.md`.

---

## 7 · Pointer to live artifacts

- Live sprint plans: `orchestration/sprints/orch-00N-plan.md`
- Mailbox: `orchestration/mailbox/po-to-se.md`, `orchestration/mailbox/se-to-po.md`
- Handshake logs: `squad-handshake-*.md`
- Retro feed: `orchestration/reports/retro-*.md`, `superuser/reports/sprint-*.md`
- Long-form design: `design/art/`, `design/ui-flows/`, `design/world/`
