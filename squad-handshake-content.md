# Squad Handshake — Content

<squad_metadata>
  <squad_name>Content-Squad</squad_name>
  <current_status>DONE_PENDING_REVIEW</current_status>
  <active_task_id>CONTENT-FARM-RANCH-FISH-FORAGE</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Epoch 16: completed a content pass on Agriculture/Ranching/Fishing/
Foraging (branch content/agriculture-ranching-fishing-foraging-balance,
PR opened) against issue #53 — expanded each placeholder roster
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
- Full suite: 496/496 checks pass (`godot --headless --path .
  tests/TestRunner.tscn`) after merging origin's pause-menu/inventory PR
  in; smoke test (`--quit-after 60`) clean.

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
* PR #55 (merged, this session — parallel sub-scope, disjoint from the
  farm/ranch/fish/forage pass above): Marriage/Festival/Infrastructure/
  Community-Goal content sub-scope, claimed via comment on #53.
  MarriageManager.MARRIAGEABLE_NPCS expanded from 2 test-fixture names
  (Elena, Marcus) to 6 (+ Priya, Tobias, Sana, Colton) — value-only
  const-array edit. 496/496 tests pass. Remaining in this sub-scope:
  Festival definitions (lower priority, already reasonable placeholders),
  Infrastructure tier/machine costs (touching these also means updating
  hardcoded expected values in several tests/test_runner.gd assertions —
  flagged as possibly crossing the Content lane's "value only, no logic"
  boundary, left for whoever picks it up next to judge), Community Goal
  bundle composition/balance.

## Blockers & QA Failures
None.

## Cross-Squad Requests
None yet.

## Epoch 16/17 status (this session, PM/Backend covering Content since the
backend leaf-task backlog is empty)
This handshake file's `active_task_id`/metadata block above reflects the
*other* concurrent Content session's in-flight farm/ranch/fish/forage
pass (no PR from that pass yet as of this update) — not overwritten here
so their status stays visible. This session's own sub-scope (Marriage/
Festival/Infrastructure/Community-Goal) delivered its first slice as
PR #55 and is otherwise idle between epochs.
