# Super User Report — Sprint 002

- **Date:** 2026-08-26
- **Tested at:** base branch @ 34e246f (no game-code changes since sprint 001;
  this pass deepens method: hands-on autoplay through the real game)
- **Method:** scripted play session driving scenes/Main.tscn and public APIs
  only (same reach a player-facing UI has). Permanent harness now lives in
  `superuser/autoplay/` — anyone can re-run:
  `godot --headless --path . superuser/autoplay/AutoplayDriver.tscn -- --phase full`
  (phases: `full`, `fest_save`, `fest_check`).

## What works end-to-end (verified by actually playing)

Intro -> HUD -> multi-day farm loop (daily watering) -> harvest credited
with quality tiers -> fishing catch -> shipping bin -> overnight payout
(+19g on a silver carp: 15 base x 1.25, math checks out) -> world travel
to Ranch/Mine/Forage/Farm -> mining break_rock -> ranch add/feed/brush ->
forage gather. Zero failures across the whole pass.

Design positive discovered en route: unwatered crops PAUSE growth instead
of withering — forgiving for a cozy game, keep that.

## Findings

### P1 — There is no seed economy at all
`FarmPlotManager.plant()` never checks or consumes inventory — no seed
items exist anywhere in the codebase, and there is no shop. Farming is a
free infinite-money printer (parsnip costs nothing, sells 35g every 4
days, infinitely scalable). The core economy has no input cost, no sink,
and no early-game decision-making. Understandable placeholder-era state,
but it silently defines balance for everything downstream (tool upgrades,
infrastructure costs, community bundles).
**Ask:** seed items + starting-grant + purchase path (or an explicit
design decision recorded that seeds are deferred), before more economy
content stacks on top of a costless foundation.

### P1 (confirmed from sprint 001, mechanism now precise) — Festival lost on quit+relaunch
Two-process repro (new):
1. Boot fresh, fast-forward to Spring day 13, start Bloomtide Fair
   (its real calendar day), see overlay live, save at 06:00, quit.
2. Relaunch: save loads correctly (clock restored to day 13, 11:03) but
   `is_festival_active()==false` and NO overlay. The fair is gone on its
   own festival day.
Root cause pattern: festival activation is derived ONLY from the
`TimeManager.day_started` edge (fires at the 2AM rollover). A reboot
mid-day never emits that edge, so nothing re-derives the active festival.
Note: in-session save/load does NOT lose it (the live node survives);
the loss window is specifically quit+relaunch. Worth auditing other
day-edge-derived systems for the same boot-time gap.

### P2 — No sleep / day-skip exists
The clock runs 6:00->2:00 at 7 game-minutes per real second = **171 real
seconds per in-game day**, and there is no bed, skip, or time-control of
any kind. First parsnip harvest requires 5 day-cycles ~= **14.3 real
minutes of forced idling** for a brand-new player. For a farming game
this is the single biggest session-pace friction.
**Ask:** a sleep-until-6am interaction (PauseMenu action or bed interact)
that advances to next `day_started` — backend already has every signal
needed; it's a small feature with outsized feel improvement.

## Tally

P0: 0 - P1: 2 - P2: 1 - P3: 0 - P4: 0
(sprint-001 open items unchanged: title screen P2, hotbar/boot-location/
intro-hint P3 x3, settings P4)

— Super User seat (ox-alpha), charter in SUPERUSER.md
