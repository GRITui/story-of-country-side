class_name InfrastructureTier
extends Resource
## One upgrade tier's unlock condition + cost for a linear infrastructure
## track (house expansion, coop/barn capacity). .tres-authorable, same
## shape as ToolUpgradeTier (#23) but with one addition Decision C (#4)
## requires for #24 specifically: an unlock_flag gated through
## QuestManager.is_unlocked(), checked IN ADDITION TO the material+gold
## cost -- #23 deliberately skipped quest-gating (see tool_manager.gd's
## docstring), #24 is the tier that Decision C's quest-gating was aimed at.
##
## tier_index is 1-based per track (tier 0 is each track's free starting
## state and needs no definition, same convention as ToolUpgradeTier's
## Copper tier).

@export var tier_index: int = 1
@export var unlock_flag: String = ""
@export var gold_cost: int = 0
@export var material_item_id: String = ""
@export var material_quantity: int = 0

## Meaning is per-track, documented at each track's registration site in
## InfrastructureManager: for the house track, a nonzero value means
## cooking is unlocked at this tier; for the coop/barn track, this is the
## new cumulative max animal capacity once this tier is reached.
@export var payload_value: int = 0
