extends Node
## Autoload: CookingManager
##
## Implements #109: Turn produce into stamina food via kitchen recipes.
## laizes a recipe ledger and handles the cooking process.
##
## Polished: emits signals for the UI to show "Cooking..." and "Meal Ready!".

signal cooking_started(recipe_id: String)
signal meal_ready(item_id: String, display_name: String, stamina: int)

var _recipes: Dictionary = {} ## recipe_id -> CookingRecipe

func _ready() -> void:
	_register_default_recipes()

func _register_default_recipes() -> void:
	# Default "Cozy" recipes
	var soup = CookingRecipe.new()
	soup.recipe_id = "parsnip_soup"
	soup.display_name = "Hearty Parsnip Soup"
	soup.ingredients = {"parsnip": 2}
	soup.stamina_restore = 30
	soup.description = "A warm, comforting soup. Restores some stamina."
	register_recipe(soup)

	var salad = CookingRecipe.new()
	salad.recipe_id = "garden_salad"
	salad.display_name = "Fresh Garden Salad"
	salad.ingredients = {"tomato": 1, "cauliflower": 1}
	salad.stamina_restore = 20
	salad.description = "Crisp and refreshing. A light stamina boost."
	register_recipe(salad)

func register_recipe(recipe: CookingRecipe) -> void:
	if recipe == null or recipe.recipe_id.is_empty():
		return
	_recipes[recipe.recipe_id] = recipe

func can_cook(recipe_id: String) -> bool:
	if not _recipes.has(recipe_id):
		return false
	var recipe = _recipes[recipe_id]
	for item_id in recipe.ingredients:
		if InventoryManager.get_item_count(item_id) < recipe.ingredients[item_id]:
			return false
	return true

func cook(recipe_id: String) -> void:
	if not can_cook(recipe_id):
		return
	
	var recipe = _recipes[recipe_id]
	
	# Consume ingredients
	for item_id in recipe.ingredients:
		InventoryManager.remove_item(item_id, recipe.ingredients[item_id])
	
	cooking_started.emit(recipe_id)
	
	# Simulate cooking time
	await get_tree().create_timer(2.0).timeout
	
	# In a real polished version, we'd add the cooked meal to inventory.
	# For now, we provide the stamina restore immediately.
	StaminaManager.restore(recipe.stamina_restore)
	meal_ready.emit(recipe.recipe_id, recipe.display_name, recipe.stamina_restore)

func get_recipe(recipe_id: String) -> CookingRecipe:
	return _recipes.get(recipe_id)

func get_all_recipes() -> Array:
	return _recipes.values()
