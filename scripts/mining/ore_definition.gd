class_name OreDefinition
extends Resource
## One ore/gem type's rarity and reward, rolled by MiningManager when a
## rock tile turns out to carry something. .tres-authorable content, same
## split as CropDefinition/AnimalDefinition/FishDefinition.

@export var item_id: String = ""

## Floor 1-indexed -- this ore can't roll on a floor shallower than this.
@export var min_floor: int = 1

## Relative roll weight among ore types eligible for the current floor
## (see MiningManager._roll_ore) -- not a percentage, just a ratio.
@export var weight: float = 1.0

@export var xp_reward: int = 1
