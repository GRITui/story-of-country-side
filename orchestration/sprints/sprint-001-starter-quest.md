# Sprint 001 — "First Days in the Valley" starter quest chain (#108)

PO sprint plan. Target: origin default (`claude/farming-game-pm-requirements-w9ugtk` @ e0e7078).

## Why this sprint
#108 is the only clearly unclaimed, unblocked, non-epic P2 leaf in the open backlog
(all other open items are covered by merged #137/#138 or open #133-#136 PRs, are epics,
or blocked by needs-decision #120). The quest engine exists; zero day-one quests exist.

## Scope (owner lanes per SQUAD-SPLIT.md)
| Step | Backend | Content | Frontend |
|------|---------|---------|----------|
| "Off Your Chest" — ship any 3 items (DELIVER_ITEM w/ count) | (exists) | starter_content.gd | \n| "First Coin" — earn first gold (EARN_GOLD condition) | quest_condition.gd enum + quest_manager.gd _on_payout_processed | starter_content.gd | |
| "A Friendly Face" — 1 heart (FRIENDSHIP_LEVEL) | (exists) | starter_content.gd | |
| "Something From Everywhere" (stretch, deferred) | | | |
| HUD: one active-quest line | | | hud.gd |
| Tests | QA | | |

## Definition of done
- `scripts/quests/starter_content.gd` registers 3 quests via existing public QuestManager API.
- EARN_GOLD condition added following existing condition pattern; complete via payout_processed.
- HUD shows ONE active quest line (no full quest-log UI).
- Headless suite green (run via godot --headless --path . --scene res://tests/TestRunner.tscn).
- PR opened into origin default; links "Closes #108".
