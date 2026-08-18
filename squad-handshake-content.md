# Squad Handshake — Content

<squad_metadata>
  <squad_name>Content-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Epoch 18: shipped gift preferences + intro narration via PR opened from
branch `content/gift-preferences-intro-copy` (see "Recent Commits / PRs"
below) — the other disjoint sub-scope of #53 claimed alongside the
Marriage/Festival/Infrastructure/Community-Goal pass. Six
`GiftPreferenceTable` .tres resources (one per `MarriageManager.
MARRIAGEABLE_NPCS` name: Elena, Marcus, Priya, Tobias, Sana, Colton)
under `scripts/social/gift_preferences/`, each with a distinct
personality expressed through loved/liked/disliked/hated item_ids drawn
from the real Agriculture/Ranching/Fishing/Foraging/Mining rosters (PR
#56). Rewrote `IntroSequence.DEFAULT_LINES` (scripts/story/
intro_sequence.gd) with more specific, characterful prose, same 6-line
beat structure and roughly the same length -- pure string content, no
logic touched. **Flagged gap (not Content lane's to fix):**
`RelationshipManager.give_gift()` takes a `GiftPreferenceTable` passed in
by the caller -- there is no runtime lookup path from an NPC name to
their `GiftPreferenceTable`/.tres resource anywhere yet, so these six
.tres files aren't wired to anything until a Backend task adds that
lookup (e.g. an NPC-name -> resource-path dictionary or a
`_register_default_content()`-style loader in RelationshipManager or a
new NPC data layer).

Epoch 16: shipped a content pass on Agriculture/Ranching/Fishing/
Foraging via PR #56 (squash-merged), verified independently at 499/499
checks passing (after also merging in the concurrent session's PR #55
Marriage-roster expansion — clean merge, no conflict). Against issue
#53 — expanded each placeholder roster
(crops/animals/fish/forageables) and re-balanced prices/timing for
internal consistency, value/string edits only per the Content lane's
strict logic boundary. Claimed this sub-scope via GitHub comment first
(#53 is tracking-only). Deliberately left tool upgrade costs, quest
content, gift preferences, and intro narration for a separate claim —
kept this pass scoped to one coherent economy cluster so it doesn't
collide with Infrastructure/Marriage/Festival content someone else might
pick up. Ran in parallel with a Frontend subagent (pause menu +
inventory overlay) — disjoint files, merged cleanly (pure-append conflict
in tests/test_runner.gd, both sides kept).

- Agriculture: 3 -> 7 crops (parsnip/tomato/pumpkin kept verbatim since
  CommunityGoalManager's pantry_bundle references them by id; added
  cauliflower/melon/corn plus frost_kale as the first Winter-viable crop).
- Ranching: 3 -> 5 species (added duck/goat); retuned sheep's wool price
  60 -> 75 so a 3-day producer isn't paying the same per-fed-day rate as
  a 1-day producer.
- Fishing: 4 -> 11 fish across all 4 locations and all 4 seasons,
  including new night-window (18:00-23:00) catches; carp/trout/salmon/
  tuna kept verbatim (CommunityGoalManager's fish_tank_bundle + an
  existing exact-price test reference them).
- Foraging: 4 -> 9 forageables, at least 2 per season plus a rare
  all-season "four_leaf_clover" bonus drop; wild_berries/wild_flower/
  mushroom/snow_truffle kept verbatim (CommunityGoalManager's
  forager_bundle references them).
- Full suite: 499/499 checks pass (`godot --headless --path .
  tests/TestRunner.tscn`) after merging origin's pause-menu/inventory PR
  (#54) and the Marriage-roster PR (#55) in; smoke test (`--quit-after
  60`) clean.

## Prior state
A non-exhaustive list of placeholder content flagged across prior PRs,
in rough priority order (most player-visible first) — items above this
line (Agriculture/Ranching/Fishing/Foraging) are now in flight:

- Intro narration (scripts/story/intro_sequence.gd's DEFAULT_LINES) —
  explicitly marked "PLACEHOLDER COPY" in its own docstring.
- Crop names/balance (scripts/autoload/farm_plot_manager.gd): Parsnip,
  Tomato, Pumpkin — 3 crops across 3 seasons, placeholder prices/growth
  days.
- Animal names/balance (scripts/autoload/animal_manager.gd).
- Fish names/balance (scripts/autoload/fishing_manager.gd).
- Forageable names/balance (scripts/autoload/foraging_manager.gd):
  wild_berries, wild_flower, mushroom, snow_truffle.
- Gift preferences (scripts/social/gift_preference_table.gd usage) — no
  actual NPC roster or per-NPC preference content exists yet, only the
  data structure.
- Tool upgrade costs (scripts/autoload/tool_manager.gd's
  _register_default_content()) — same cost structure across all 4 tools,
  flagged as not final balance.
- Quest content (scripts/autoload/quest_manager.gd consumers, once #24
  Infrastructure Upgrades defines its quest-gated unlocks).

## Recent Commits / PRs
* PR (this session, branch `content/gift-preferences-intro-copy`): gift
  preferences (6 `GiftPreferenceTable` .tres resources under
  `scripts/social/gift_preferences/`) + intro narration rewrite
  (`IntroSequence.DEFAULT_LINES`). 496/496 checks pass, clean smoke boot.
  Flags the RelationshipManager wiring gap noted above.
* PR #56 (merged, this session): Agriculture/Ranching/Fishing/Foraging
  content pass — see "Current Focus" above for the full breakdown.
* PR #55 (merged, concurrent session — parallel sub-scope, disjoint from
  the farm/ranch/fish/forage pass above): Marriage/Festival/Infrastructure/
  Community-Goal content sub-scope, claimed via comment on #53.
  MarriageManager.MARRIAGEABLE_NPCS expanded from 2 test-fixture names
  (Elena, Marcus) to 6 (+ Priya, Tobias, Sana, Colton) — value-only
  const-array edit. Remaining in this sub-scope: Festival definitions
  (lower priority, already reasonable placeholders), Infrastructure
  tier/machine costs (touching these also means updating hardcoded
  expected values in several tests/test_runner.gd assertions — flagged
  as possibly crossing the Content lane's "value only, no logic"
  boundary, left for whoever picks it up next to judge), Community Goal
  bundle composition/balance.

## Blockers & QA Failures
None.

## Cross-Squad Requests
None yet.

## Epoch 16/17 note
This session (PM/Backend orchestrator covering the Content lane since
the backend leaf-task backlog is empty) dispatched the farm/ranch/fish/
forage sub-scope as a subagent; it hit an infra-level API session-limit
error mid-task twice (unrelated to the code), so this session took over
directly to finish verification, resolve the concurrent PR #55 merge,
and open/merge PR #56 itself. Remaining known content gaps: tool upgrade
costs, quest content, gift preferences, intro narration, plus the
Festival/Infrastructure/Community-Goal remainder PR #55 flagged.
