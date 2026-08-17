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
