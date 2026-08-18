# Squad Handshake — Content

<squad_metadata>
  <squad_name>Content-Squad</squad_name>
  <current_status>IN_PROGRESS</current_status>
  <active_task_id>CONTENT-FARM-RANCH-FISH-FORAGE</active_task_id>
  <sprint_completion_percentage>0</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Epoch 16: dispatched a subagent to do a content pass on Agriculture/
Ranching/Fishing/Foraging (branch content/agriculture-ranching-fishing-
foraging-balance) against issue #53 — expanding each placeholder roster
(crops/animals/fish/forageables) and re-balancing prices/timing for
internal consistency, value/string edits only per the Content lane's
strict logic boundary. Claimed this sub-scope via GitHub comment first
(#53 is tracking-only). Deliberately left tool upgrade costs, quest
content, gift preferences, and intro narration for a separate claim —
kept this pass scoped to one coherent economy cluster so it doesn't
collide with Infrastructure/Marriage/Festival content someone else might
pick up. Running in parallel with a Frontend subagent (pause menu +
inventory overlay) — disjoint files.

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
None yet.

## Blockers & QA Failures
None.

## Cross-Squad Requests
None yet.
