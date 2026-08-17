# Backlog Inbox

Append-only ledger for the multi-squad AI engineering loop. Sourced from
GitHub issues on `gritui/story-of-country-side` as of the seed epoch below.
Squads: Researcher, Engineer, QA-Tester, UX-UI-Designer. Do not delete or
rewrite closed items — append status changes as new entries reference the
same `<id>`.

<!-- Seed epoch: Researcher-Squad, run 1 -->

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
