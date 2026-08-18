class_name CropDefinition
extends Resource
## One plantable crop's content: which season(s) it can be planted in, how
## long it takes to grow, whether it regrows after harvest, and its base
## (normal-quality) sell price. .tres-authorable, same pattern as
## NPCSchedule/QuestDefinition/ToolUpgradeTier — content, not hardcoded
## logic.
##
## No concrete crop list exists anywhere in the design doc (same gap
## pattern as quest content #31, gift preferences #19, tool costs #23) —
## FarmPlotManager registers a small placeholder set at boot, documented
## as placeholders in #13's PR, not final game balance.

@export var crop_id: String = ""
@export var display_name: String = ""

## Seasons this crop can be planted/grown in. A planted crop whose current
## season falls outside this list withers (see FarmPlotManager._on_day_started).
@export var valid_seasons: Array[String] = []

## Days of being watered (not calendar days) to reach first harvest.
@export var days_to_grow: int = 4

## Regrowable crops (e.g. tomatoes) keep producing from the same plot
## instead of clearing on harvest -- regrow_days governs the shorter cycle
## between harvests after the first.
@export var regrowable: bool = false
@export var regrow_days: int = 3

## Normal-quality (1x multiplier) sell price; silver/gold multiply this,
## see FarmPlotManager.QUALITY_PRICE_MULTIPLIER.
@export var base_sell_price: int = 10

## Farming XP awarded per harvest via SkillManager.add_xp("Farming", ...).
@export var xp_reward: int = 4
