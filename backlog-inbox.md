# Backlog Inbox

Append-only ledger for the multi-squad AI engineering loop. Sourced from
GitHub issues on `gritui/story-of-country-side` as of the seed epoch below.
Squads: Researcher, Engineer (= Backend/Squad A), Frontend (Squad B),
QA-Tester, UX-UI-Designer. Do not delete or rewrite closed items — append
status changes as new entries reference the same `<id>`.

**See SQUAD-SPLIT.md (repo root) for the Backend/Frontend ownership
boundary and contract rule, added once multiple concurrent sessions made
an explicit split worth formalizing.** New task_item descriptions should
note `(backend)` / `(frontend)` when the split matters for who should
claim the task.

<!-- Seed epoch: Researcher-Squad, run 1 -->

## Epoch 14 update (Session B): ENG-16 shipped — the five-activity set is now complete

<task_item>
  <id>ENG-16</id>
  <status>DONE</status>
  <description>
    Merged via PR #47 (squash, base claude/farming-game-pm-requirements-w9ugtk).
    MiningManager (autoload) + OreDefinition content type in scripts/mining/.
    Scoped per Decision B (#3, resolved peaceful/no-combat): procedurally
    generated 5x5 floors (seeded RNG for deterministic tests), every tile
    an intact rock except one reserved ladder-down tile, break_rock()
    credits stone or a weighted-rolled ore/gem (copper_ore/iron_ore/
    gold_ore/diamond, floor-gated min_floor) plus Mining XP, descend_ladder()
    regenerates the next floor. Reuses ToolManager's existing "iron_ore"/
    "gold_ore" item ids so mined ore feeds straight into tool-upgrade costs
    -- deliberate cross-system consistency, flagged inline. "copper_ore"
    and "diamond" are new placeholder ids with no consumer yet (documented
    gap, not silent scope). Persisted through SaveManager (floor_index +
    per-tile state) since a floor's progress is meaningful state, unlike
    ENG-15/Fishing's stateless casts. Rebased cleanly onto PR #46
    (Frontend HUD, merged mid-build) and the Content-lane/SQUAD-SPLIT.md
    update -- no real conflicts (all pure appends to shared files).
    344/344 tests pass (rest new) against the real Godot 4.3 engine
    headless. Issue #16 closed.

    This closes out the original five-activity set from epic #8:
    Agriculture (#13), Ranching (#14), Fishing (#15), Mining (#16),
    Foraging (#17) are now all DONE.
  </description>
</task_item>

<!-- Coordination note: claimed #16 via a "Claiming this" GitHub comment
     before starting (per the process this loop settled on after the
     ENG-14 near-miss). The concurrent session's own Epoch 14 dispatch
     (backlog/handshake entries above this one) independently confirmed
     seeing this claim and picked disjoint issues (#24/#20/#21) instead of
     colliding again -- the claim-comment-before-dispatch discipline is
     holding up. -->

<!-- Step 0 discovery this epoch: no new GitHub issues found. Remaining
     open backend-shaped issues after this PR: #20 (Marriage), #21
     (Festivals), #24 (Infrastructure Upgrades), #27 (Ultimate-goal
     structure) -- #20/#21/#24 already claimed by the concurrent session
     per its Epoch 14 dispatch, so #27 is the only unclaimed backend item
     left; #8/#9/#10/#11 are epics/trackers, not leaf work; #1 is the
     process doc. -->

## Epoch 13 update (Session B): ENG-15 shipped — Fishing pools + catch contract

<task_item>
  <id>ENG-15</id>
  <status>DONE</status>
  <description>
    Merged via PR #45 (squash, base claude/farming-game-pm-requirements-w9ugtk).
    FishingManager (autoload) + FishDefinition content type in
    scripts/fishing/. Ships only the decidable half of #15's scope:
    get_available_fish(location, season, hour) for pool queries
    (deterministic sorted output), attempt_catch(fish_id, performance) as
    a pass/fail contract for a future mini-game scene to call into with a
    [0.0, 1.0] performance score. The mini-game's own input/skill-check
    design is explicitly left TBD per the issue text -- building one here
    would invent an undecided design and cross into Frontend/UI territory
    per SQUAD-SPLIT.md, not this autoload's. Consumes InventoryManager +
    SkillManager.add_xp("Fishing", ...), quality tiers (normal/silver/
    gold) driven by global performance thresholds (>=0.9/>=0.6) same
    id-suffix convention as FarmPlotManager/AnimalManager. No
    to_save_dict()/from_save_dict() -- a cast is stateless, nothing to
    persist beyond registered content (documented as a deliberate
    simplification, not an oversight). Four placeholder fish (carp/trout/
    salmon/tuna) with placeholder difficulty/price/XP, MVP balance.
    Rebased cleanly onto PR #44 (ENG-17/Foraging, merged by the other
    session mid-build) -- project.godot/save_manager.gd/test_runner.gd
    all auto-merged with no real conflicts (pure adjacent appends).
    285/285 tests pass (23 new) against the real Godot 4.3 engine
    headless. Issue #15 closed.
  </description>
</task_item>

<!-- Coordination note: claimed #15 via a "Claiming this" GitHub comment
     before starting, after checking no other session had already claimed
     it (learned from the Epoch 12 ENG-14 near-miss to check immediately
     before dispatch, not just once at epoch start). No collision this
     time -- #17 (Foraging, the other session's concurrent pick) and #15
     don't overlap. -->

<!-- Step 0 discovery this epoch: 14 open issues remained before this
     PR (13 after). No new GitHub issues found. No open PRs left after
     merging #45. -->

## Epoch 12 update: ENG-17 (Foraging) shipped

<task_item>
  <id>ENG-17</id>
  <status>DONE</status>
  <description>
    Merged via PR #44 (squash, base claude/farming-game-pm-requirements-w9ugtk).
    ForagingManager autoload owns Vector2i -> ForageNode gather spots
    (same tile-grid convention as FarmPlotManager). gather(position)
    credits InventoryManager + SkillManager.add_xp("Foraging", ...)
    (own skill, not folded into Farming) and puts the node on cooldown
    for its item's respawn_days; nodes reroll to a season-valid item on
    cooldown expiry or when their current item's season ends (mirrors
    FarmPlotManager's wither-on-season-end handling). Placeholder
    content: wild_berries (Spring/Summer, 8g/3xp/2d respawn), wild_flower
    (Spring, 6g/2xp/2d), mushroom (Fall, 12g/4xp/3d), snow_truffle
    (Winter, 20g/6xp/4d) -- documented as not final balance. Fixed a real
    bug found during testing: _reroll_node read TimeManager.current_season()
    directly instead of the season arg already threaded through
    _on_day_started, which happened to match in production but broke
    direct test calls -- fixed to match FarmPlotManager's own convention.
    No scene/tilemap placement yet (Frontend's lane per SQUAD-SPLIT.md);
    register_node() is the integration point for later. Verified
    independently against the real merged base: 262/262 checks pass,
    clean smoke boot. Issue #17 closed.
  </description>
</task_item>

## Epoch 12 update: ENG-14 (Ranching) shipped by a concurrent session

<task_item>
  <id>ENG-14</id>
  <status>DONE</status>
  <description>
    Merged via PR #43 (base claude/farming-game-pm-requirements-w9ugtk),
    delivered by a concurrent session that claimed and shipped it while
    this session had its own ENG-14 subagent mid-build. That subagent
    discovered the duplicate via its pre-PR fetch/merge step and correctly
    stood down without pushing/opening a redundant PR (its local-only
    build is discarded, never pushed to origin). AnimalManager autoload +
    AnimalDefinition/Animal in scripts/ranching/ — daily feed/brush loop,
    egg/milk/wool harvest, quality tied to happiness at collection time
    (>=80 Gold, >=50 Silver, else Normal) -- their PR description flags
    this as worth reconciling with FarmPlotManager's separate
    roll-based quality approach later (not done this epoch; both are
    valid designs, not a bug). Verified independently against the real
    merged base: 241/241 checks pass, clean smoke boot. Issue #14 was
    already closed by the other session.
  </description>
</task_item>

## Epoch 11 update: ENG-13 + ENG-26 shipped in parallel — InventoryManager gap closed

<task_item>
  <id>ENG-13</id>
  <status>DONE</status>
  <description>
    Merged via PR #42 (base claude/farming-game-pm-requirements-w9ugtk).
    FarmPlotManager (plant/water/harvest, season validity, day-clock-driven
    growth, regrowth, season-end withering) + CropDefinition/FarmPlot
    content types in scripts/farming/. Also ships the general-purpose
    InventoryManager autoload flagged as a gap in ENG-23's PR (#23) --
    item_id -> quantity ledger, add_item/remove_item/get_count/has_item/
    sell_item(forwards to ShippingBinManager.ship_item)/item_changed
    signal/to_save_dict/from_save_dict. Deliberately generalized beyond
    crops so Ranching/Fishing/Mining/Foraging (#14/#15/#16/#17) consume
    this same interface next epoch instead of forking their own.
    Placeholder crop content: Parsnip (Spring, 4d, 35g), Tomato (Summer,
    5d/3d regrow, 45g), Pumpkin (Fall, 7d, 120g); quality tiers normal/
    silver/gold at 1x/1.25x/1.5x sell price, 70/20/10 roll odds (SDV
    precedent) -- documented as placeholder, not final balance. Verified
    independently against the real merged state: 208/208 checks pass.
    Issue #13 closed.
  </description>
</task_item>
<task_item>
  <id>ENG-26</id>
  <status>DONE</status>
  <description>
    Merged via PR #41 (squash, base claude/farming-game-pm-requirements-w9ugtk).
    IntroSequence (linear data-driven narration controller, freezes
    TimeManager during playback) + scenes/intro/IntroSequence.tscn +
    main_controller.gd (minimal boot-time new-game entry point -- no real
    title screen exists yet, this is a stand-in per the issue's own scope
    note). SaveManager gained the repo's first real disk persistence
    (new_game()/save_game()/load_game(), user://savegame.json) plus
    intro_seen tracking. Placeholder 6-line narration, clearly marked for
    a writer to replace. Starting resources deliberately limited to what
    ShippingBinManager/ToolManager already track (500 gold, free Copper
    tools) -- a fuller starting-inventory grant is a documented follow-up
    now that InventoryManager exists. Issue #26 closed.
  </description>
</task_item>

<!-- Coordination note: dispatched as two parallel Engineer-Squad
     subagents on isolated worktree branches (feature/eng-13-agriculture,
     feature/eng-26-opening-hook), chosen because they touch disjoint
     primary systems (crop/inventory logic vs. intro scene/save
     persistence). Both PRs opened within the same minute and both
     touched scripts/autoload/save_manager.gd + tests/test_runner.gd
     (SaveManager growing two independent extensions at once, plus two
     independent blocks of new tests appended to the same file) --
     PR #41 merged clean; PR #42 then showed a real (expected, additive)
     merge conflict against the now-moved base. While resolving that
     conflict locally to verify-then-merge it myself, a concurrent
     process/session resolved the same conflict (identical default
     merge-commit message, i.e. a plain `git merge --no-edit`) and merged
     PR #42 first, mid-resolution on my end. Did not overwrite anything --
     abandoned my in-progress local resolution once I saw the merge had
     already landed, and independently re-verified the actual merged
     result on the base branch (not trusting either side's or my own
     unverified fix): 208/208 checks pass, clean smoke boot. No content
     was lost or duplicated in the real merge. -->

<!-- Step 0 discovery this epoch: 15 open issues, all represented in this
     ledger already (no new GitHub issues found). No open PRs left after
     merging #41/#42. -->


## PM Decisions (Researcher squad backlog)

<task_item>
  <id>DEC-A</id>
  <source>GITHUB_ISSUE #2</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Narrative pacing: strict end-date vs. open-ended gameplay</title>
  <description>Blocks epic #11 (Story & Meta-Objectives), sub-issues #26/#27.</description>
  <researcher_notes>See recommendation posted as a comment on issue #2 this epoch.</researcher_notes>
</task_item>

<task_item>
  <id>DEC-B</id>
  <source>GITHUB_ISSUE #3</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Scope of mechanics: combat vs. peaceful mines</title>
  <description>Blocks sub-issue #16 (Mining) in epic #8.</description>
  <researcher_notes>See recommendation posted as a comment on issue #3 this epoch.</researcher_notes>
</task_item>

<task_item>
  <id>DEC-C</id>
  <source>GITHUB_ISSUE #4</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Late-game automation vs. manual labor</title>
  <description>Blocks sub-issues #23 (Tool Upgrades), #24 (Infrastructure) in epic #10.</description>
  <researcher_notes>See recommendation posted as a comment on issue #4 this epoch.</researcher_notes>
</task_item>

<task_item>
  <id>DEC-D</id>
  <source>GITHUB_ISSUE #5</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Single-player only vs. co-op multiplayer at launch</title>
  <description>Highest-leverage decision in the doc — gates architecture for all of epic #8. No sub-issue is formally GitHub-blocked on it, but Engineer squad cannot start real implementation without this plus a stack choice (see ENG-STACK below).</description>
  <researcher_notes>See recommendation posted as a comment on issue #5 this epoch.</researcher_notes>
</task_item>

<task_item>
  <id>DEC-E</id>
  <source>GITHUB_ISSUE #6</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Art style & perspective: 2D pixel vs. 2.5D isometric vs. 3D</title>
  <description>Blocks all UX-UI-Designer squad final-asset work and Engineer squad rendering-layer choices.</description>
  <researcher_notes>See recommendation posted as a comment on issue #6 this epoch.</researcher_notes>
</task_item>

<task_item>
  <id>DEC-F</id>
  <source>GITHUB_ISSUE #7</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Target platform & monetization: premium vs. F2P mobile</title>
  <description>Blocks input model, UI layout constraints across every epic.</description>
  <researcher_notes>See recommendation posted as a comment on issue #7 this epoch.</researcher_notes>
</task_item>

## Gap raised by Researcher squad this epoch

<task_item>
  <id>ENG-STACK</id>
  <source>RESEARCHER_SQUAD</source>
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>HIGH</priority>
  <title>Engine / language / repo scaffold not yet chosen</title>
  <description>
    The design doc's six decisions (A–F) don't include an explicit engine or
    tech-stack pick, but Engineer squad cannot open a real PR for #12 (Time &
    Stamina foundation) or any other Core Gameplay Loop sub-issue without
    one — there is no source tree, build system, or language convention to
    write code against yet. This blocks all Engineer-squad execution
    regardless of decision status. Needs an owner call: engine (e.g. Godot,
    Unity, a custom web/TS stack) and target repo layout, ideally informed
    by Decision E (art style) and Decision F (platform) once those land.
  </description>
  <researcher_notes>
    Not fabricating a stack choice unilaterally — this is exactly the kind
    of scope decision the coordination process (#1) exists to route to a
    human rather than guess at.
  </researcher_notes>
</task_item>

## Epoch 11: multi-session traffic, squad split formalized

Since last epoch, at least two more concurrent actors landed real work:
ENG-26 (Opening hook — IntroSequence, MainController, SaveManager's
new_game/save_game/load_game) via PR #41, and ENG-13 (Agriculture +
a general-purpose InventoryManager, resolving the inventory gap flagged
in #23's PR) via PR #42. Both PRs based off slightly different points in
history and conflicted with each other on merge (both touched
SaveManager and appended to test_runner.gd) — resolved locally by
merging base into the PR-13 branch, keeping both sides' additions (pure
appends, no real logic conflict), re-verifying 208/208 tests pass against
the real engine, then merging. Also spawned a second autonomous session
(session_01RiogEKTgZhZyp8F2QARYvt) explicitly, and a third unidentified
session (session_019dLCj2rGD4v9BJDxig6fBa, seen earlier) is still
presumably active — expect this pattern (concurrent PRs, occasional
conflicts) to continue, not be an anomaly.

<task_item>
  <id>ENG-13</id>
  <status>DONE</status>
  <description>
    Merged via PR #42 (with conflict resolved against #41). FarmPlotManager,
    CropDefinition, and a new general-purpose InventoryManager
    (scripts/autoload/inventory_manager.gd) live. 208/208 tests pass.
    Issue #13 closed. InventoryManager now available for #14/#15/#16/#17
    to consume instead of forking their own ledgers.
  </description>
</task_item>
<task_item>
  <id>ENG-26</id>
  <status>DONE</status>
  <description>
    Merged via PR #41 (by a concurrent session). IntroSequence,
    MainController, and SaveManager's new_game()/save_game()/load_game()
    entry points live. Issue #26 closed.
  </description>
</task_item>

**Squad split formalized: SQUAD-SPLIT.md added at repo root.** Backend
(Squad A) = scripts/autoload, scripts/economy, scripts/quests,
scripts/farming, scripts/social, NPC schedule data. Frontend (Squad B) =
scenes, scripts/story, scripts/npc/npc_controller.gd, future scripts/ui,
design docs. Contract rule: Frontend only touches Backend via public
methods/signals, never private fields; Backend never imports scenes.
New squad-handshake-frontend.md created. squad-handshake-engineer.md is
now understood as Backend/Squad A's log (unchanged in practice — every
entry logged there so far was already backend work).

<!-- Remaining READY_FOR_PM items, reclassified by the new split:
     (backend) ENG-14 Ranching, ENG-15 Fishing, ENG-16 Mining, ENG-17
       Foraging -- data/logic side (growth/catch/dig state machines),
       consume InventoryManager + SkillManager like ENG-13 did.
     (backend) ENG-24 Infrastructure Upgrades -- quest-gated automation,
       QuestManager.is_unlocked(flag) + ShippingBinManager.spend().
     (backend+frontend, needs splitting when claimed) ENG-20 Marriage,
       ENG-21 Festivals -- both have real logic (state machines, triggers)
       and real presentation (ceremony scenes, festival mini-games); split
       into explicit sub-tasks when claimed rather than one squad building
       both halves.
     (frontend) First real HUD/menu scene implementation against
       design/ui-flows/menu-hud-flow-spec.md -- no issue currently tracks
       this as code (only the spec doc, #28); worth filing as a new issue
       if Frontend squad picks it up before a GitHub issue exists for it. -->

## Epoch 10 update: ENG-23 shipped, discussed with owner before building

<task_item>
  <id>ENG-23</id>
  <status>DONE</status>
  <description>
    Merged via PR #40 (squash merge to base branch). Discussed scope with
    owner first: kept quest-free (Decision C's quest-gating belongs to
    #24's automation tiers, not core tool progression), per-tool not
    global (Hoe/WateringCan/Axe/Pickaxe independent), Copper free start.
    ToolManager/ToolUpgradeTier live in scripts/autoload/ and
    scripts/economy/. Raised a new gap: no general InventoryManager
    exists anywhere -- ToolManager owns a minimal ore ledger sized to its
    own needs instead. 131/131 tests pass (27 new). Issue #23 closed.
  </description>
</task_item>

<!-- Also this epoch: user asked mid-build to check on ENG-19's PR status.
     Clarified there were two different PRs -- #34 (the actual feature,
     merged and verified) and #35 (a redundant coordination-state PR from
     the parallel session, correctly closed unmerged as superseded by this
     session's own earlier reconciliation commit). No reopening needed;
     confirmed and moved on. -->

## Epoch 9 update: UX-GRID shipped — the last real blocker on the five activities is gone

<task_item>
  <id>UX-GRID</id>
  <status>DONE</status>
  <description>
    Merged via PR #39 (squash merge to base branch). This session claimed
    and delivered it directly as UX-UI-Designer-Squad rather than waiting
    another epoch for the parallel session — treated as a standard
    implementation convention (2:1 isometric ratio, 64x32px tile,
    coordinate transform, YSort depth convention), not a new game-design
    decision, so it didn't need to go back to the owner. Doc at
    design/art/isometric-grid-spec.md. Confirmed NPCController (#18)
    needs no changes. No GitHub issue tracks this item directly (it's a
    backlog-inbox.md-only entry from DEC-E's resolution), so nothing to
    close there.
  </description>
</task_item>

<!-- ENG-13/14/15/16/17 now have every foundational system AND the grid
     convention they need. Nothing structural blocks them anymore --
     picking one up is purely a matter of a squad claiming it next epoch. -->

<!-- Step 0 discovery this epoch: no new GitHub issues found (16 open, all
     represented). No open PRs from the parallel session either. -->

## Epoch 8 update: ENG-25 shipped — shared XP hook exists ahead of the five activities

<task_item>
  <id>ENG-25</id>
  <status>DONE</status>
  <description>
    Merged via PR #38 (squash merge to base branch). SkillManager live in
    scripts/autoload/ — add_xp(skill_name, amount) is the shared event
    hook Agriculture/Ranching/Fishing/Mining/Foraging should emit into.
    Ranching feeds the Farming skill (documented decision, matches SDV
    precedent). Wires QuestManager.evaluate_skill_level() on every level
    crossed. 104/104 tests pass (16 new, including a real integration test
    proving the SkillManager -> QuestManager hook fires end-to-end).
    Issue #25 closed.
  </description>
</task_item>

<!-- Interface note for whoever picks up ENG-13/14/15/16/17: call
     SkillManager.add_xp("Farming"|"Fishing"|"Mining"|"Foraging", amount)
     on activity completion. Ranching -> "Farming", not a separate skill.
     No fixed XP-per-action values exist anywhere yet -- pick reasonable
     defaults and document them in the PR, same pattern as quest content
     (#31) and gift preferences (#19). -->

<!-- Step 0 discovery this epoch: no new GitHub issues found (17 open, all
     represented). No open PRs from the parallel session either. -->

## Epoch 7 update: ENG-31 shipped — Tool/Infrastructure Upgrades unblocked

<task_item>
  <id>ENG-31</id>
  <status>DONE</status>
  <description>
    Merged via PR #37 (squash merge to base branch). QuestManager,
    QuestCondition, QuestDefinition live in scripts/quests/ and
    scripts/autoload/. Listens to ShippingBinManager.item_shipped and
    RelationshipManager.points_changed; SKILL_LEVEL condition type is
    forward-compatible scaffolding only (no SkillManager exists yet, #25
    not built). 88/88 tests pass (19 new). Issue #31 closed.
  </description>
</task_item>
<task_item><id>ENG-23</id><status>READY_FOR_PM</status><description>Unblocked — ENG-31 landed. Tool Upgrades can now gate automation tiers behind QuestManager.is_unlocked(flag) and use ShippingBinManager.spend() for gold cost.</description></task_item>
<task_item><id>ENG-24</id><status>READY_FOR_PM</status><description>Unblocked — ENG-31 landed. Infrastructure Upgrades, same unlock-flag + spend() pattern as ENG-23.</description></task_item>

<!-- Step 0 discovery this epoch: no new GitHub issues found beyond what's
     already tracked (18 open, all represented). No open PRs from the
     parallel session this time either. -->

## Epoch 6 update: ENG-22 shipped — wallet exists, PR #35 closed as superseded

<task_item>
  <id>ENG-22</id>
  <status>DONE</status>
  <description>
    Merged via PR #36 (squash merge to base branch). ShippingBinManager
    live in scripts/autoload/ — owns the wallet, pays out shipments on
    TimeManager.day_started, consumes StaminaManager.passed_out (a signal
    that's existed since #12 with no listener until now). 69/69 tests pass
    (16 new). Issue #22 closed.
  </description>
</task_item>

<!-- Also this epoch: the parallel session (session_019dLCj2rGD4v9BJDxig6fBa)
     opened PR #35, a state-sync PR for ENG-19's merge, right as this
     session's own Epoch 5 reconciliation commit landed the same fix plus
     more. Closed #35 as superseded (not merged) rather than risk
     conflicting with content already two commits ahead. No unique content
     was lost — verified via diff before closing. -->

## Epoch 5: reconciled with a second session working this repo in parallel

Discovered mid-epoch that another session (session_019dLCj2rGD4v9BJDxig6fBa,
branch `claude/story-country-side-setup-1881dw`) had independently delivered
work against the same base branch: PR #28 (UX-FLOW-01 flow spec), PR #29
(its own coordination-state update, which that session had *already*
rebased itself once this loop's epochs superseded parts of it), and PR #34
(ENG-19, Relationship System — the same task this loop would have picked
next). All three were genuine, non-duplicate, well-tested work, not
building-race collisions to discard. Verified PR #34's claimed 53/53 test
result independently (re-ran the suite myself against the real engine)
before merging rather than trusting the PR description. Merged all three,
in order: #28, #29, #34. Deleted the now-merged head branches where git
permissions allowed (feature/eng-12-*, feature/eng-18-*,
feature/eng-19-relationship-system locally; remote delete returned 403 —
no push permission for ref deletion, and no GitHub API tool covers it
either, so the remote branches remain as harmless merged-and-stale refs).

<task_item>
  <id>ENG-19</id>
  <status>DONE</status>
  <description>
    Delivered by the other session, merged via PR #34 (squash, this
    session verified the 53/53 test claim independently before merging).
    RelationshipManager + GiftPreferenceTable live on the base branch.
    Issue #19 closed. Supersedes the READY_FOR_PM entry below.
  </description>
</task_item>
<task_item>
  <id>UX-FLOW-01</id>
  <status>DONE</status>
  <description>
    Confirmed merged via PR #28 (squash). design/ui-flows/menu-hud-flow-spec.md
    live on the base branch.
  </description>
</task_item>
<task_item><id>ENG-20</id><status>READY_FOR_PM</status><description>Unblocked — ENG-19 confirmed merged. Marriage &amp; Family.</description></task_item>

## Epoch 4 update: ENG-18 shipped — Relationship System unblocked

<task_item>
  <id>ENG-18</id>
  <status>DONE</status>
  <description>
    Merged via PR #33 (squash merge to base branch). NPCScheduleEntry,
    NPCSchedule, NPCController live in scripts/npc/. 31/31 tests pass
    against the real Godot 4.3 engine before merge (12 new checks for
    schedule lookup, day-boundary wrap-around, season overrides,
    controller movement/pause/retarget). Issue #18 closed.
  </description>
</task_item>
<task_item><id>ENG-19</id><status>READY_FOR_PM</status><description>Unblocked — ENG-18 landed. Relationship System: friendship/romance points, gifting, heart events.</description></task_item>

<!-- ENG-20 (Marriage) still needs ENG-19 first. ENG-21 (Festivals) needs
     ENG-18 (done) — check whether it also needs anything from ENG-19
     before picking it up; the epic notes said Festivals and Relationship
     System could run in parallel, so ENG-21 may already be pickable too. -->
<task_item><id>ENG-21</id><status>READY_FOR_PM</status><description>Unblocked — ENG-18 (NPC Routines) landed, which is its only hard dependency per epic #9's sequencing note. Festivals.</description></task_item>

## Epoch 3 update: ENG-12 shipped — dependents unblocked

<task_item>
  <id>ENG-12</id>
  <status>DONE</status>
  <description>
    Merged via PR #32 (squash merge to base branch). TimeManager,
    StaminaManager, SaveManager autoloads live. 19/19 tests passed against
    the real Godot 4.3 engine before merge. Issue #12 closed.
  </description>
</task_item>

<task_item><id>ENG-13</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Agriculture: seasonal crops.</description></task_item>
<task_item><id>ENG-14</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Ranching: livestock.</description></task_item>
<task_item><id>ENG-15</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Fishing mini-game + fish pools.</description></task_item>
<task_item><id>ENG-16</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed, DEC-B already resolved (peaceful). Mining: procedural floors, no combat.</description></task_item>
<task_item><id>ENG-17</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Foraging: seasonal wild goods.</description></task_item>
<task_item><id>ENG-18</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. NPC Routines.</description></task_item>
<task_item><id>ENG-22</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Shipping Bin economy.</description></task_item>
<task_item><id>ENG-25</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Skill Leveling.</description></task_item>
<task_item><id>ENG-26</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed. Opening hook / intro sequence.</description></task_item>
<task_item><id>ENG-31</id><status>READY_FOR_PM</status><description>Unblocked — ENG-12 landed (was already READY_FOR_PM as new scope from DEC-C). Quest system foundation.</description></task_item>

<!-- Still sequenced behind other in-flight work, not just ENG-12:
     ENG-19 depends on ENG-18 (Relationship System needs NPC Routines first).
     ENG-20 depends on ENG-19 (Marriage needs Relationship System first).
     ENG-21 depends on ENG-12 and ENG-18 (Festivals needs NPC Routines too).
     ENG-23/24 depend on ENG-31 (quest system) for the unlock-flag hook.
     ENG-27 has no hard code dependency left but is low priority (ultimate-goal
     structure) — fine to pick up whenever a squad has room.
     UX-GRID (isometric grid ratio) should land before any of ENG-13/14/16/17
     touch environment art, per DEC-E follow-up. -->

## Epoch 2 update: DEC-F resolved — all six decisions + ENG-STACK now closed

<task_item>
  <id>DEC-F</id>
  <status>DECIDED</status>
  <description>
    Owner resolved: free-to-play, PC first (Steam). Reconciled with earlier
    research — the flagged genre risk was energy timers/pay-to-win, not
    "free" itself. Monetization limited to cosmetic-only DLC/tip-jar, no
    gameplay-affecting purchases; every system stays fully playable at zero
    spend. Closed issue #7. Console port stays a near-term follow-up.
    Monetization-store implementation not yet backlogged — low priority,
    revisit once epic #8 is further along.
  </description>
</task_item>

<!-- All of ENG-STACK, DEC-A, DEC-B, DEC-C, DEC-D, DEC-E, DEC-F are now DECIDED.
     Only remaining blockers on the Engineer-Squad queue are sequencing
     dependencies (ENG-13+ depend on ENG-12 landing) and the new ENG-31
     (quest system) gating ENG-23/24. Next epoch: Engineer-Squad pulls ENG-12. -->

## Epoch 2 update: DEC-E resolved

<task_item>
  <id>DEC-E</id>
  <status>DECIDED</status>
  <description>
    Owner resolved: 2.5D isometric — deviates from the flat-2D
    recommendation. Closed issue #6. Flagged for Art Director: isometric
    tilesets need more edge/corner/transition variants than flat top-down
    (size the environment art backlog accordingly); genre precedent for
    isometric specifically is thin, more UX design risk to budget for; lock
    the isometric grid ratio (2:1 typical) early since it constrains every
    environment asset after. Still compatible with Godot (native isometric
    TileMap mode) — no reopening of ENG-STACK.
  </description>
</task_item>
<task_item>
  <id>UX-GRID</id>
  <source>DEC-E follow-up</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Lock isometric grid ratio and tile dimensions</title>
  <description>UX-UI-Designer/Art squad: define the isometric grid ratio (2:1 typical) and base tile pixel dimensions before any environment art or tilemap work starts in ENG-13/14/16/17 (farm, ranch, mine, foraging environments). Blocking dependency for those, not formally a GitHub-blocked issue.</description>
</task_item>

## Epoch 2 update: DEC-D resolved

<task_item>
  <id>DEC-D</id>
  <status>DECIDED</status>
  <description>
    Owner resolved: single-player for v1, co-op scoped as a post-launch
    update (mirrors SDV's own sequencing). Closed issue #5. No sub-issue
    was formally GitHub-blocked on this, but it's a direct build note for
    ENG-12: per-client clock, no server-authority layer now; keep world
    state in one serializable save object as light future-proofing without
    building any netcode yet.
  </description>
</task_item>

## Epoch 2 update: DEC-C resolved

<task_item>
  <id>DEC-C</id>
  <status>DECIDED</status>
  <description>
    Owner resolved: tiered automation, unlocked per-tier by completing a
    quest (in addition to existing material/gold cost), not gold-gating
    alone. Closed issue #4. Unblocks #23/#24, but introduces new scope:
    the design doc has no quest system defined anywhere — opened #31
    (Quest system foundation) as a sub-issue of epic #10 to cover it.
  </description>
</task_item>
<task_item>
  <id>ENG-31</id>
  <source>GITHUB_ISSUE #31</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Quest system foundation</title>
  <description>New scope raised by DEC-C. Minimal objective/trigger/reward-flag system sized only to gate automation tiers. Depends on ENG-12. Blocks ENG-23 and ENG-24.</description>
</task_item>
<task_item><id>ENG-23</id><status>BLOCKED</status><description>DEC-C resolved; no longer decision-blocked. Now depends on ENG-31 (quest system) for the unlock-flag hook.</description></task_item>
<task_item><id>ENG-24</id><status>BLOCKED</status><description>DEC-C resolved; no longer decision-blocked. Now depends on ENG-31 (quest system) for the unlock-flag hook.</description></task_item>

## Epoch 2 update: DEC-B resolved

<task_item>
  <id>DEC-B</id>
  <status>DECIDED</status>
  <description>
    Owner resolved: peaceful mines, no combat (HMBtN model). Closed issue
    #3. Unblocks sub-issue #16 (Mining) — scope fixed to procedural floors,
    rock-breaking, ore/gem gathering, ladder descent; combat dropped from
    scope.
  </description>
</task_item>
<task_item><id>ENG-16</id><status>BLOCKED</status><description>DEC-B resolved (peaceful); no longer decision-blocked. Still queued behind ENG-12 (low priority, sequencing only).</description></task_item>

## Epoch 2 update: DEC-A resolved

<task_item>
  <id>DEC-A</id>
  <status>DECIDED</status>
  <description>
    Owner resolved: open-ended (SDV model) with an optional Homestead
    Challenge toggle at new-game creation. Closed issue #2. Unblocks epic
    #11 and sub-issue #27 (blocked: needs-decision label removed).
  </description>
</task_item>
<task_item><id>ENG-27</id><status>BLOCKED</status><description>DEC-A resolved; no longer decision-blocked. Still queued behind ENG-12+ (low priority, sequencing only).</description></task_item>

## Epoch 2 update: ENG-STACK resolved

<task_item>
  <id>ENG-STACK</id>
  <source>OWNER_DECISION #30</source>
  <status>DECIDED</status>
  <priority>HIGH</priority>
  <title>Engine / language / repo scaffold — Godot (GDScript)</title>
  <description>
    Owner resolved this directly (not via the ai-engineering-loop): Godot
    Engine, GDScript. Chosen because the game is free-to-play, which removes
    Unity's licensing/runtime-fee questions entirely by going with a fully
    open-source engine instead, and Godot's 2D pipeline fits the pending
    art-style recommendation (DEC-E) on issue #6. Logged and closed as
    GitHub issue #30. This unblocks ENG-12 — see updated status below.
  </description>
</task_item>

<!-- Statuses below supersede the identically-keyed entries above; append-only, do not delete prior entries -->

<task_item><id>ENG-12</id><status>READY_FOR_PM</status><description>Unblocked — Godot/GDScript chosen (ENG-STACK #30). First real Engineer-Squad task for epic #8.</description></task_item>
<task_item><id>ENG-13</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12 landing first.</description></task_item>
<task_item><id>ENG-14</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12.</description></task_item>
<task_item><id>ENG-15</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12.</description></task_item>
<task_item><id>ENG-16</id><status>BLOCKED</status><description>Stack choice resolved; still blocked on DEC-B (combat scope, issue #3, GitHub label blocked: needs-decision).</description></task_item>
<task_item><id>ENG-17</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12.</description></task_item>
<task_item><id>ENG-18</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12.</description></task_item>
<task_item><id>ENG-19</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-18.</description></task_item>
<task_item><id>ENG-20</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-19.</description></task_item>
<task_item><id>ENG-21</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12 and ENG-18.</description></task_item>
<task_item><id>ENG-22</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12.</description></task_item>
<task_item><id>ENG-23</id><status>BLOCKED</status><description>Stack choice resolved; still blocked on DEC-C (automation scope, issue #4, GitHub label blocked: needs-decision).</description></task_item>
<task_item><id>ENG-24</id><status>BLOCKED</status><description>Stack choice resolved; still blocked on DEC-C.</description></task_item>
<task_item><id>ENG-25</id><status>BLOCKED</status><description>No longer blocked on stack choice; still depends on ENG-12+.</description></task_item>
<task_item><id>ENG-26</id><status>BLOCKED</status><description>No longer blocked on stack choice; not yet in queue order (low priority).</description></task_item>
<task_item><id>ENG-27</id><status>BLOCKED</status><description>Stack choice resolved; still blocked on DEC-A (narrative pacing, issue #2, GitHub label blocked: needs-decision).</description></task_item>

## Engineering sub-issues (Engineer squad backlog — status mirrors GitHub)

<task_item><id>ENG-12</id><source>GITHUB_ISSUE #12</source><status>BLOCKED</status><priority>HIGH</priority><title>Time &amp; Stamina foundation</title><description>Blocked on ENG-STACK — no repo scaffold to build against yet. Otherwise first in queue for epic #8.</description></task_item>
<task_item><id>ENG-13</id><source>GITHUB_ISSUE #13</source><status>BLOCKED</status><priority>MEDIUM</priority><title>Agriculture: seasonal crops</title><description>Blocked on ENG-STACK; depends on ENG-12 landing first.</description></task_item>
<task_item><id>ENG-14</id><source>GITHUB_ISSUE #14</source><status>BLOCKED</status><priority>MEDIUM</priority><title>Ranching: livestock</title><description>Blocked on ENG-STACK; depends on ENG-12.</description></task_item>
<task_item><id>ENG-15</id><source>GITHUB_ISSUE #15</source><status>BLOCKED</status><priority>MEDIUM</priority><title>Fishing mini-game + fish pools</title><description>Blocked on ENG-STACK; depends on ENG-12.</description></task_item>
<task_item><id>ENG-16</id><source>GITHUB_ISSUE #16</source><status>BLOCKED</status><priority>LOW</priority><title>Mining: procedural floors</title><description>Blocked on both ENG-STACK and DEC-B (combat scope, GitHub label blocked: needs-decision).</description></task_item>
<task_item><id>ENG-17</id><source>GITHUB_ISSUE #17</source><status>BLOCKED</status><priority>MEDIUM</priority><title>Foraging: seasonal wild goods</title><description>Blocked on ENG-STACK; depends on ENG-12.</description></task_item>
<task_item><id>ENG-18</id><source>GITHUB_ISSUE #18</source><status>BLOCKED</status><priority>MEDIUM</priority><title>NPC Routines</title><description>Blocked on ENG-STACK; depends on ENG-12.</description></task_item>
<task_item><id>ENG-19</id><source>GITHUB_ISSUE #19</source><status>BLOCKED</status><priority>MEDIUM</priority><title>Relationship System</title><description>Blocked on ENG-STACK; depends on ENG-18.</description></task_item>
<task_item><id>ENG-20</id><source>GITHUB_ISSUE #20</source><status>BLOCKED</status><priority>LOW</priority><title>Marriage &amp; Family</title><description>Blocked on ENG-STACK; depends on ENG-19.</description></task_item>
<task_item><id>ENG-21</id><source>GITHUB_ISSUE #21</source><status>BLOCKED</status><priority>LOW</priority><title>Festivals</title><description>Blocked on ENG-STACK; depends on ENG-12 and ENG-18.</description></task_item>
<task_item><id>ENG-22</id><source>GITHUB_ISSUE #22</source><status>BLOCKED</status><priority>MEDIUM</priority><title>Shipping Bin economy</title><description>Blocked on ENG-STACK; depends on ENG-12.</description></task_item>
<task_item><id>ENG-23</id><source>GITHUB_ISSUE #23</source><status>BLOCKED</status><priority>LOW</priority><title>Tool Upgrades</title><description>Blocked on ENG-STACK and DEC-C (automation scope, GitHub label blocked: needs-decision).</description></task_item>
<task_item><id>ENG-24</id><source>GITHUB_ISSUE #24</source><status>BLOCKED</status><priority>LOW</priority><title>Infrastructure Upgrades</title><description>Blocked on ENG-STACK and DEC-C.</description></task_item>
<task_item><id>ENG-25</id><source>GITHUB_ISSUE #25</source><status>BLOCKED</status><priority>LOW</priority><title>Skill Leveling</title><description>Blocked on ENG-STACK.</description></task_item>
<task_item><id>ENG-26</id><source>GITHUB_ISSUE #26</source><status>BLOCKED</status><priority>LOW</priority><title>Opening hook / intro sequence</title><description>Blocked on ENG-STACK.</description></task_item>
<task_item><id>ENG-27</id><source>GITHUB_ISSUE #27</source><status>BLOCKED</status><priority>LOW</priority><title>Ultimate-goal structure</title><description>Blocked on ENG-STACK and DEC-A (GitHub label blocked: needs-decision).</description></task_item>

<!-- Epoch 2 -->

## UX-UI-Designer squad backlog

<task_item>
  <id>UX-FLOW-01</id>
  <source>UXUI_SQUAD</source>
  <status>DONE</status>
  <priority>MEDIUM</priority>
  <title>Menu structure &amp; HUD layout logic flow spec</title>
  <description>
    Navigation flow (title screen, pause menu) and always-on HUD layout
    logic, traced to backing system issues (#12, #22, #25) and the still-open
    decisions that gate optional UI branches (#2 Homestead Challenge toggle,
    #5 co-op mode select). Deliberately stack- and art-style-agnostic per the
    run brief — does not wait on Decision E (#6).
  </description>
  <researcher_notes>
    Claimed and delivered this epoch by UX-UI-Designer squad. Doc at
    design/ui-flows/menu-hud-flow-spec.md. PR:
    gritui/story-of-country-side#28 (base:
    claude/farming-game-pm-requirements-w9ugtk). Final visual-asset work
    remains blocked on DEC-E per the original triage.
  </researcher_notes>
</task_item>

<!-- Epoch 3 (this session, not the scheduled Routine): checked in on the
     autonomous ai-engineering-loop's progress, rebased/cleaned up PR #29
     which the loop's own epochs had partially superseded, then claimed and
     delivered one more Engineer-Squad task. -->

<task_item>
  <id>ENG-19</id>
  <status>DONE</status>
  <description>
    Claimed via "Claiming this" comment on issue #19, then delivered:
    RelationshipManager (autoload) with per-NPC friendship points,
    once-per-day talk/gift caps, point clamping, and threshold-crossing
    heart events (fires once per newly-crossed heart, including on
    multi-heart jumps). GiftPreferenceTable (Resource, .tres-authorable
    like NPCSchedule from #18) for loved/liked/disliked/hated item tables.
    SaveManager extended to round-trip relationship state (daily flags are
    intentionally NOT saved — day-scoped, not save-scoped). PR:
    gritui/story-of-country-side#34 (base:
    claude/farming-game-pm-requirements-w9ugtk). 53/53 tests pass (22 new)
    against the real Godot 4.3 engine headless. Unblocks ENG-20 (Marriage
    &amp; Family).
  </description>
</task_item>
<task_item><id>ENG-20</id><status>READY_FOR_PM</status><description>Unblocked — ENG-19 landed (pending PR #34 review/merge). Marriage &amp; Family: eligible bachelors/bachelorettes, proposal, wedding, children.</description></task_item>

<!-- Epoch 15 (this session, PM/Backend): ENG-27 shipped, closing out the
     entire backend leaf-task backlog. Also did a PM pass: closed all four
     design-doc epics (#8/#9/#10/#11) now at 100% sub-issue completion, and
     opened two new tracking epics (#52 Frontend scenes/UI, #53 Content
     placeholder pass) so the substantial remaining non-backend work has
     real issues to claim against instead of loose handshake-log notes. -->

<task_item>
  <id>ENG-27</id>
  <status>DONE</status>
  <description>
    Claimed via "Claiming this" comment on issue #27. Built
    CommunityGoalManager (autoload) + BundleDefinition (Resource,
    .tres-authorable): Community-Center-style bundle/collection goal
    reusing real item_ids from every activity system (crops, animal
    products, fish, ore, forageables) rather than inventing new content.
    contribute_item() pulls from InventoryManager with clamp-to-remaining
    and no-partial-removal-on-failure semantics. Year-3 evaluation fires on
    TimeManager.day_started (year 3/Spring/day 1): non-terminal narrative
    beat by default per Decision A's open-ended resolution, becomes
    pass/fail with a game_over signal only when challenge_mode is on
    (Homestead Challenge toggle). Rebased cleanly onto ENG-24/ENG-20/ENG-21
    which landed concurrently since epoch 14. PR:
    gritui/story-of-country-side#51 (base:
    claude/farming-game-pm-requirements-w9ugtk). 438/438 tests pass (11
    new) against the real Godot 4.3 engine headless, clean smoke test.
    Self-merged per standing authorization; issue #27 auto-closed.
  </description>
</task_item>

<task_item>
  <id>PM-EPOCH-15-CLOSEOUT</id>
  <status>DONE</status>
  <description>
    All four design-doc epics closed as completed (#8 Core Gameplay Loop,
    #9 Social Mechanics, #10 Progression &amp; Economy, #11 Story &amp;
    Meta-Objectives) — each showed 100% sub-issue completion via GitHub's
    sub_issues_summary once ENG-27 landed. The backend leaf-task backlog
    (ENG-12 through ENG-31) is now fully DONE. Opened #52 ([Epic] Frontend:
    scenes &amp; UI for all shipped backend systems) and #53 ([Epic]
    Content: replace placeholder game content with real balance/copy) to
    track the substantial real work still remaining outside the backend
    lane — squad-handshake-frontend.md and squad-handshake-content.md
    already documented these gaps informally but neither had a tracked
    GitHub issue to claim sub-work against.
  </description>
</task_item>

<!-- Epoch 17 (this session, PM/Backend, working the Content lane since the
     backend leaf-task backlog is empty): Step 0 found no new open issues
     beyond #53 (Content epic, already logged) and #1 (process, awareness-
     only) -- #52 (Frontend epic) closed since last epoch via PR #54
     (pause menu + inventory overlay, concurrent session). Claimed the
     Marriage/Festival/Infrastructure/Community-Goal content sub-scope on
     #53 (disjoint from the concurrent Content session's Agriculture/
     Ranching/Fishing/Foraging cluster) and delivered the first slice. -->

<task_item>
  <id>CONTENT-MARRIAGE-ROSTER</id>
  <status>DONE</status>
  <description>
    Expanded MarriageManager.MARRIAGEABLE_NPCS from the two
    RelationshipManager test-fixture names (Elena, Marcus) to a 6-name
    roster (+ Priya, Tobias, Sana, Colton) -- value-only const-array edit,
    no logic/signal changes, per SQUAD-SPLIT.md's Content lane. PR:
    gritui/story-of-country-side#55 (base:
    claude/farming-game-pm-requirements-w9ugtk). 496/496 tests pass
    against the real Godot 4.3 engine headless (class-cache refresh was
    needed first for PauseMenu/InventoryOverlay from the concurrently-
    merged PR #54 -- unrelated to this change, just a required step after
    pulling latest). Self-merged per standing authorization.

    Remaining in this sub-scope, not yet done: Festival definitions
    (currently reasonable placeholder names/dates, lower priority),
    Infrastructure Upgrades' tier/machine costs (touching these would also
    require updating hardcoded expected values in
    tests/test_runner.gd's infrastructure tests -- more logic-adjacent
    than a pure content edit, flagged for whoever picks this up next to
    decide if that crosses the Content lane's boundary), Community Goal
    bundle composition/balance.
  </description>
</task_item>

<!-- Epoch 20 (this session, PM/Backend covering the Content lane): Step 0
     found no new open issues -- #52/#53 both reopened by concurrent
     sessions after GitHub auto-closed them on sub-scope PR merges (their
     own comments already note this), no new issue numbers. Continued this
     session's own Marriage/Festival/Infrastructure/Community-Goal
     sub-scope from epoch 17, picking Community Goal bundles next since
     Infrastructure costs and Festival dates were flagged as lower-value/
     higher-risk (test coupling) in that epoch's notes. -->

<task_item>
  <id>CONTENT-COMMUNITY-GOAL-BUNDLES</id>
  <status>DONE</status>
  <description>
    Added five new Community Goal bundles (orchard_bundle,
    deluxe_coop_bundle, night_anglers_bundle, forager_reserve_bundle,
    vault_bundle) reusing item_ids the concurrent session's Agriculture/
    Ranching/Fishing/Foraging pass (PR #56) and ENG-16 Mining's diamond
    added since the original five were written. Purely additive -- none
    of the original five bundles touched. PR:
    gritui/story-of-country-side#60 (base:
    claude/farming-game-pm-requirements-w9ugtk). 514/514 tests pass
    against the real Godot 4.3 engine headless (class-cache refresh
    needed first for FarmScene from the concurrently-merged PR #57).
    Self-merged per standing authorization.

    Still remaining in this sub-scope: Festival definitions (lower
    priority), Infrastructure tier/machine costs (still flagged as
    possibly crossing the Content lane's boundary since changing them
    means updating several hardcoded test assertions -- left for a
    dedicated pass or an Engineer-Squad judgment call).
  </description>
</task_item>

<!-- Epoch 21 (new Content-Squad session, dedicated to this lane since the
     prior PM/Backend session released its claim back to #53). Claimed the
     remaining sub-scope (Festival/Infrastructure/tool-costs/quest-content)
     via a comment on #53. -->

<task_item>
  <id>CONTENT-FESTIVAL-TOOL-BALANCE</id>
  <status>BLOCKED</status>
  <description>
    Real festival names (bloomtide_fair/sunfield_revel/harvest_moon_festival/
    hearthlight_festival, replacing the four placeholder ids+display names,
    dates/seasons unchanged) plus differentiated ToolManager per-tool
    upgrade costs (Hoe unchanged/tested baseline, WateringCan cheapest,
    Axe moderate, Pickaxe priciest -- AoE shape/stamina unchanged, only
    ore/gold cost differs). Reviewed Infrastructure tier/machine costs and
    their gating quest content too; found both already internally
    consistent and deliberately left alone rather than reshuffling numbers
    that already make sense. Value/string content only per SQUAD-SPLIT.md's
    Content lane. PR: gritui/story-of-country-side#61 (base:
    claude/farming-game-pm-requirements-w9ugtk) -- 514/514 tests pass
    (verified both pre- and post- merging latest base in, clean merge),
    clean smoke boot.

    Status BLOCKED, not DONE: this session's attempt to self-merge PR #61
    via the GitHub API was denied by this environment's own auto-mode
    permission classifier (a platform-level control, not a code or content
    issue). Per that denial's own instructions, did not attempt to route
    around it through another mechanism (e.g. pushing a merge commit
    straight to the base branch). PR #61 is open, green, and ready --
    needs a human, or a session with merge permission, to actually merge
    it. See squad-handshake-content.md's "Blockers & QA Failures" section
    for the full detail.
  </description>
</task_item>
