# Super User Report — Sprint 003

- **Date:** 2026-08-26
- **Tested at:** base branch @ 78fa37e (parity first: **962/962** checks pass,
  clean smoke boot — so every finding below is new signal, not drift)
- **Method:** retailer-lens business-use-case simulation of the whole economy
  loop (sell side = shipping bin, buy side = gold sinks). New permanent
  harness `superuser/autoplay/RetailSimDriver.tscn`, public APIs only,
  same reach a player-facing shop UI has. Re-run:
  `godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase retail`
  → **21 checks, 19 pass, 2 fail** (both one bug class).

## What works end-to-end (verified)

Sell happy-path (stock → bin → overnight payout) with exact multi-line
math (350g + 48g + 30g = 428g settled once, exactly); oversell rejected
with ledger untouched; empty-item-id rejected; save/reload mid-day keeps
gold AND pending shipments byte-exact (phantom post-save lines correctly
cannot survive reload); failed tool purchases never consume ore first
(two-gate ordering held under short-gold); spend() rejects 0/negative.
Buy-side retail loop is in noticeably better contract shape than sell-side.

## Findings (filed as issues this sprint)

### #97 — P1 blocker: `sell_item()` silently destroys stock at price ≤ 0
`InventoryManager.sell_item("x", n, 0)` returns **true**, removes all n
units from inventory, and ships nothing — `ShippingBinManager.ship_item()`
silently no-ops on its own `unit_price <= 0` guard after the stock is
already gone. Cross-autoload guard mismatch; goods unrecoverable.
Latent today (no sell UI yet) but sits directly on #91's seed-shop path.
Repro + damage printout in the driver run log; fix is a one-line front
validation in `sell_item()` plus the missing zero-price test case.

### #96 — P2 feature: canonical price registry
" What does this sell for?" currently has three disconnected answers:
`CropDefinition.base_sell_price` (normal ids only), quality-multiplier
constants inside FarmPlotManager, or caller-supplied `unit_price` with no
table behind it. No public lookup for `"parsnip_silver"` exists; every
future vendor screen must re-invent multiplier math. Ask: read-only
`EconomyRegistry` lookup for sell/buy prices, data-first per SQUAD-SPLIT's
content lane; unblocks #91 buy prices too.

### #98 — P3 feature: nightly sale receipt/history
Payout emits aggregates only; per-line detail dies at settlement and is
never serialized. Foundation ask for a genre-standard morning sales
summary — cheap now, annoying after artisan/festival payouts also route
through the bin.

## Positive design notes
Pending-shipment persistence is exactly right (raw lines survive
save/reload and still pay exactly once — the festival #90 boot-gap does
NOT afflict the bin). Two-gate purchase ordering is consistently correct
across ToolManager and InfrastructureManager.
