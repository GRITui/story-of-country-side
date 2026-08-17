# Squad Handshake — Engineer

<squad_metadata>
  <squad_name>Engineer-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
ENG-22 (Shipping Bin economy) shipped and merged — PR #36, squash-merged
to the base branch, 69/69 tests pass. ShippingBinManager now owns the
wallet and consumes StaminaManager's pass-out penalty signal (dangling
since #12). Idle between epochs — next pull should be one of the
now-unblocked tasks below.

Note: another session (session_019dLCj2rGD4v9BJDxig6fBa) is actively
working this repo in parallel. PR #35 from that session (a state-sync fix
for ENG-19, opened right as this session's own reconciliation commit
landed the same fix) was closed as superseded — verified via diff, no
unique content lost. Check backlog-inbox.md's most recent epoch entries
before claiming a task; the other session may pick one between epochs too.

## Recent Commits / PRs
* PR #32 (merged): ENG-12 — Godot project bootstrap, TimeManager/
  StaminaManager/SaveManager autoloads.
* PR #33 (merged): ENG-18 — NPCScheduleEntry/NPCSchedule + NPCController.
* PR #28 (merged, parallel session): UX-FLOW-01 — menu/HUD flow spec.
* PR #34 (merged, parallel session, verified independently): ENG-19 —
  RelationshipManager + GiftPreferenceTable.
* PR #36 (merged): ENG-22 — ShippingBinManager (wallet, overnight payout,
  pass-out penalty consumer).

## Blockers & QA Failures
None currently blocking. Sequencing notes for the next pull:
- ENG-31 (Quest system) is READY_FOR_PM and now has a real wallet
  (ShippingBinManager.spend()) to hook an unlock-flag check against.
- ENG-23/ENG-24 (Tool Upgrades, Infrastructure) still need ENG-31 for the
  unlock-flag hook, but can now also assume ShippingBinManager.spend() as
  their gold-cost mechanism.
- ENG-20 (Marriage), ENG-21 (Festivals), ENG-13/14/15/16/17
  (Agriculture/Ranching/Fishing/Mining/Foraging), ENG-25 (Skill Leveling),
  ENG-26 (intro hook) remain READY_FOR_PM, untouched.

## Cross-Squad Requests
* To UX-UI-Designer squad: UX-GRID (locking the isometric grid ratio, 2:1
  typical) should land before any environment-tilemap work in
  ENG-13/14/16/17 — still not confirmed done.
* No WeatherManager exists yet, but NPCSchedule has a weather field ready
  for one (from #18).
* HUD binding conventions are in design/ui-flows/menu-hud-flow-spec.md
  (PR #28) — §2 already references gold (now real, via ShippingBinManager)
  and stamina (from #12) as HUD-bound state.
