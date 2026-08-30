class_name CookingRecipe
extends Resource
## A recipe that turns a list of ingredients into a stamina-restoring meal.
## Sized for #109: simple ingredient list + stamina yield.

@export var recipe_id: String = ""
@export var display_name: String = ""
@export var ingredients: Dictionary = {} ## item_id -> quantity
@export var stamina_restore: int = 0
@export var description: String = ""
