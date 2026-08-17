class_name ToolUpgradeTier
extends Resource
## One upgrade tier's cost and payoff for one tool. .tres-authorable, same
## pattern as NPCSchedule/QuestDefinition — content, not hardcoded logic.
## tier_index 1 = Iron, 2 = Gold. Tier 0 (Copper) is the free starting
## tier every tool has and needs no definition.

@export var tier_index: int = 1
@export var ore_item_id: String = ""
@export var ore_quantity: int = 0
@export var gold_cost: int = 0

## Grid offsets (from UX-GRID's coordinate system, design/art/isometric-grid-spec.md)
## relative to the target tile — what tiles a tool-use action reaches at
## this tier. Translating these into absolute tiles (accounting for player
## facing) is the consuming activity's job (#13/#16/#17 etc.), not this
## system's — ToolManager only owns the upgrade economy and reports the
## pattern, it doesn't know about player position or facing direction.
@export var aoe_offsets: Array[Vector2i] = [Vector2i.ZERO]

@export var stamina_cost: int = 5
