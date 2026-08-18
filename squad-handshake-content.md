# Squad Handshake — Content

<squad_metadata>
  <squad_name>Content-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>0</sprint_completion_percentage>
</squad_metadata>

## Current Focus
Newly split out — see SQUAD-SPLIT.md's "Content lane" section for scope
(value/string content only, never logic) and what it may/may not edit.
Nothing claimed yet. A non-exhaustive list of placeholder content flagged
across prior PRs, in rough priority order (most player-visible first):

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
