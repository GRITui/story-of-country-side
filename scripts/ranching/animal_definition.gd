class_name AnimalDefinition
extends Resource
## One livestock species' product economy. .tres-authorable content, same
## split as CropDefinition/ToolUpgradeTier/NPCSchedule.

@export var species_id: String = ""
@export var display_name: String = ""

## Item added to InventoryManager on collect_product() (before any
## quality-tier suffix -- see AnimalManager.get_item_id).
@export var product_item_id: String = ""

## Fed days needed between products -- 1 for a daily producer (chicken,
## cow), more for a slower one (sheep's wool, matching the genre's own
## "shear every few days" precedent named in #14).
@export var days_between_products: int = 1

@export var base_sell_price: int = 0
@export var xp_reward: int = 0
