# ORCH-007 Sprint Plan — "Economy Integrity + Discovery"

**Owner:** Product Owner (ox-alpha)
**Base branch:** `claude/farming-game-pm-requirements-w9ugtk`
**Status:** READY
**Timebox:** <=75 min wall-clock
**Squad mix:** eng-backend, fe-ui, content-writer, qa-tester

## Sprint goal

Fix the scattered price problem (#96), add sale history (#98), and give players a collection journal (#117). After this sprint: every sellable item has one canonical price, the player sees a morning sales summary, and there's a discoverable encyclopedia of found items.

## Issues addressed

| Issue | Priority | Lane |
|-------|----------|------|
| #96 Canonical price registry | P2 | Backend |
| #98 Nightly sale receipt | P3 | Backend + Frontend |
| #117 Collection journal: discovery encyclopedia | P3 | Backend + Frontend |

## Tasks

### T1 — Price registry (backend, #96)
- Branch: `feature/eng-96-price-registry`
- New `PriceRegistry` autoload: `register_price(item_id, base_price)`, `get_price(item_id)`, `get_all_prices()`.
- Migrate all existing hardcoded prices (ShippingBinManager, FarmPlotManager crop prices, AnimalManager product prices, MiningManager ore prices, ForagingManager forage prices) to register through PriceRegistry on `_ready()`.
- Quality multiplier applied at sell time via PriceRegistry: `get_price(item_id, quality)`.
- **Acceptance:** every item_id has one canonical price; quality multiplier works; removing a registration logs a warning; full suite green.

### T2 — Nightly sale receipt (backend + frontend, #98)
- Branch: `feature/eng-98-sale-receipt`
- ShippingBinManager: on payout, persist per-line shipment history (item_id, quantity, quality, price) to a lightweight array.
- New `get_last_receipt()` getter.
- Frontend: morning HUD notification showing "Yesterday's Shipments: Parsnip x3 (105g), Tomato x2 (112g) — Total: 217g".
- **Acceptance:** receipt shows correct line items after overnight payout; cleared on new day; full suite green.

### T3 — Collection journal (backend + frontend, #117)
- Branch: `feature/eng-117-journal`
- New `JournalManager` autoload: tracks discovered item_ids across all categories (crop, animal, fish, ore, forage). Listens to harvest/collect/catch signals from each activity manager.
- `get_discovered(category)`, `get_total(category)`, `is_discovered(item_id)`.
- Frontend: new Journal overlay (pause menu entry) showing discovered/total per category with item names and icons.
- **Acceptance:** discovering an item updates the journal; overlay shows correct counts; undiscovered items are hidden; full suite green.

### T4 — Sprint QA gate (qa-tester)
- Full suite + smoke boot + E2E: ship items → morning receipt shows → harvest new item type → journal updates.
- Deliverable: pass/fail + defect list.

## Dependencies & sequencing

```
T1 (price registry) ──┐
T2 (sale receipt)   ──┤── T4 (QA gate)
T3 (journal)        ──┘
```

T1, T2, T3 independent. T4 waits for all.

## Retro hook

Retrospective 7 reviews: does the price registry eliminate silent drift? Does the journal motivate collection? Is the morning receipt informative without being annoying?
