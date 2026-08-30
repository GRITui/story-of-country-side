class_name CookingRecipe
extends Resource
## One kitchen recipe: ingredients -> stamina food.
## Issue #109. Placeholder MVP balance — no final cooking design exists.
##
## .tres-authorable, same pattern as CropDefinition / FishDefinition.
## Ingredients are item_id -> quantity consumed via InventoryManager.
## The output is an item_id (also added to InventoryManager) plus a stamina
## restore amount (applied via StaminaManager).

@export var recipe_id: String = ""
@export var display_name: String = ""
## ingredients: Dictionary String -> int  e.g. {"parsnip": 2, "milk": 1}
@export var ingredients: Dictionary = {}
@export var output_item_id: String = ""
@export var output_quantity: int = 1
@export var stamina_restored: int = 20
## Optional: description for UI tooltip.
@export var description: String = ""
