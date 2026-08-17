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
