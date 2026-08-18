# Squad Handshake — QA-Tester

<squad_metadata>
  <squad_name>QA-Tester-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
No open PRs against `claude/farming-game-pm-requirements-w9ugtk` as of
this epoch (epoch 2). Backlog of merged-but-unreviewed PRs from epoch 1
is now clear except for one new arrival mid-epoch (see "Queued for next
epoch" below).

## Recent Commits / PRs — Epoch 2
Reviewed all 20 PRs merged since epoch 1's review, against current
base-branch HEAD (`059773e`):

* PR #45 (ENG-15, Fishing) — PASS. Commented.
* PR #46 (Frontend: always-on HUD) — PASS. Commented.
* PR #47 (ENG-16, Mining) — PASS. Commented.
* PR #48 (ENG-21, Festivals) — PASS. Commented.
* PR #49 (ENG-20, Marriage & Family) — PASS. Commented. Minor
  observation (non-blocking): child-birth roll uses global `randf()`
  instead of the seedable `RandomNumberGenerator` pattern every other
  RNG-consuming manager uses; the PR's own test correctly works around
  this by asserting invariants rather than a fixed outcome.
* **PR #50 (ENG-24, Infrastructure Upgrades) — PASS on what it ships,
  but flagged a real scope gap.** Decision C (#4)'s actual resolution
  explicitly calls for automation devices — "sprinklers → auto-feeders →
  collection hub, each behind its own unlock quest" — landing in this
  issue. `InfrastructureManager` only ships House/Coop/Artisan-machine
  tracks; no automation device exists anywhere in the repo (confirmed by
  grep — only a docstring reference in `tool_manager.gd` and three
  illustrative flag names in `QuestManager`'s own test suite, not real
  content). PR #40 (Tool Upgrades) explicitly deferred all quest-gating
  to this issue, so the gap isn't covered elsewhere either. Unlike every
  other content gap in this repo, this one wasn't flagged in the PR's own
  description. Commented on the PR with the full citation trail
  (Decision C's resolution comment + PR #40's own deferral). **This is
  the one finding this epoch that needs PM attention** — flagging here
  since PM is this session; not filing a GitHub issue myself per QA's
  scope (that's PM's call).
* PR #51 (ENG-27, Ultimate-goal / Community Goal) — PASS. Commented.
* PR #54 (Frontend: pause menu + Inventory overlay) — PASS. Commented.
* PR #55 (Content: Marriage roster) — PASS, content-only. Commented.
* PR #56 (Content: Agriculture/Ranching/Fishing/Foraging rosters) —
  PASS, content-only. Commented.
* PR #57 (Frontend: FarmScene) — PASS. Commented.
* PR #58 (Content: gift preferences + intro narration) — PASS,
  content-only. Commented.
* PR #59 (Backend: NPC→GiftPreferenceTable lookup) — PASS. Commented.
* PR #60 (Content: 5 new Community Goal bundles) — PASS, content-only.
  Commented.
* PR #61 (Content: festival names + tool cost rebalance) — PASS,
  content-only. Commented.
* PR #62 (Backend: WeatherManager) — PASS. Commented.
* PR #63 (Frontend: HUD weather display) — PASS. Commented.
* PR #64 (Frontend: RanchScene) — PASS. Commented.
* PR #65 (Frontend: ForageScene) — PASS. Commented.
* PR #66 (Frontend: MineScene) — PASS. Commented. Noted a claimed-vs-
  actual test-count mismatch (PR claims 714/714, I independently measured
  711/711 on the exact same commit) — confirmed via `git log`/`git show`
  across every intervening PR that **no test function was ever deleted**,
  so this is not a coverage regression, just an inaccurate count
  somewhere in the PR chain's own local runs. Not blocking, logged for
  visibility.

**Verification performed, independently, this epoch:**
- `godot --headless --editor --quit` (class-cache refresh), then
  `godot --headless --path . tests/TestRunner.tscn` →
  **711/711 checks pass** on current HEAD (cumulative across all 20 PRs
  reviewed this epoch, on top of epoch 1's 262).
- `godot --headless --path . --quit-after 60` — clean smoke test, no
  runtime errors/warnings.
- Repo-wide contract-boundary grep sweep (re-run against every new
  directory: `scripts/fishing`, `scripts/mining`, `scripts/events`,
  `scripts/infrastructure`, `scripts/goals`, `scripts/world`,
  `scripts/social/gift_preferences`) — two grep hits, both confirmed
  false positives (comments mentioning a path/method name, not real
  cross-boundary code). Zero real violations.
- Every PR's scope diffed against its linked GitHub issue (#15/#16/#20/
  #21/#24/#27/#52/#53) — one real gap found (PR #50, see above); every
  other PR matches its issue.
- Manual line-by-line read of the new backend managers' actual logic:
  `fishing_manager.gd`, `mining_manager.gd` (weighted ore roll,
  save round-trip), `festival_manager.gd` (freeze pairing, auto-trigger
  idempotency), `marriage_manager.gd` (proposal never partially consumes
  the item, wedding countdown fires exactly once), `infrastructure_manager.gd`
  (material-before-gold ordering, job lifecycle), `community_goal_manager.gd`
  (contribution clamping, one-shot completion/evaluation firing),
  `weather_manager.gd` (dedup on unchanged roll), and the
  `relationship_manager.gd` gift-lookup addition. Also read
  `pause_menu.gd`/`inventory_overlay.gd` and spot-checked
  `ranch_scene.gd`/`mine_scene.gd` for the frontend world-scene batch
  (position↔id derivation, no private-field reach-around, correct signal
  reactivity). **No logic bugs found** beyond the two non-blocking
  observations above. `save_manager.gd` confirmed wired for every new
  manager that needs persistence (and correctly NOT wired for the two
  that don't — FishingManager/FestivalManager — matching their own
  documented "fully re-derivable, nothing to round-trip" reasoning).

## Blockers & QA Failures
None blocking test suite / contract integrity. One scope-completeness
finding on PR #50 (Infrastructure automation gap) needs PM attention —
see above.

## Cross-Squad Requests
To PM: PR #50 (Infrastructure Upgrades) doesn't implement the automation
devices (sprinklers/auto-feeders/collection hub) that Decision C (#4)
explicitly resolved should land there. Needs a call: fix-forward PR, or
explicit documentation that it's intentionally deferred and issue #24
isn't fully closed.

## Queued for next epoch
One more PR merged to the base branch while this epoch's review was in
progress — not yet reviewed, first item next epoch:
* PR #67 (Frontend: Skills full-screen overlay)
