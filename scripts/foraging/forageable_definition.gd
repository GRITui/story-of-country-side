class_name ForageableDefinition
extends Resource
## One wild-gatherable item's content: which season(s) it can be found in,
## its base (single-quantity) sell price, the Foraging XP it awards on
## gather, and how many in-game days a spot holding it stays on cooldown
## after being gathered. .tres-authorable, same pattern as
## CropDefinition/QuestDefinition/ToolUpgradeTier/NPCSchedule -- content,
## not hardcoded logic.
##
## No concrete forageable list, prices, or respawn timing exists anywhere
## in the design doc -- ForagingManager registers a small placeholder set
## at boot, documented as placeholders in #17's PR, not final game balance
## (same gap pattern as #13/#23/#25).
##
## Unlike CropDefinition, there is no days_to_grow/regrowable pair here --
## Foraging (#17) is explicitly "wild goods across the map", not planted by
## the player, so a node either holds an available forageable or it
## doesn't; respawn_days is the only timing knob.

@export var item_id: String = ""
@export var display_name: String = ""

## Seasons this item can spawn in. A node currently holding an item whose
## season has just ended clears/rerolls rather than sitting stale -- see
## ForagingManager._on_day_started.
@export var valid_seasons: Array[String] = []

## Sell price for one unit at InventoryManager.sell_item's unit_price arg.
## No quality-tier system here (unlike Agriculture's normal/silver/gold) --
## nothing in #17's scope calls for one.
@export var base_sell_price: int = 5

## Foraging XP awarded per gather via SkillManager.add_xp("Foraging", ...).
@export var xp_reward: int = 3

## In-game days a node stays on cooldown after being gathered before it
## can become available again.
@export var respawn_days: int = 3
