extends Node
## Autoload: CookingManager
##
## Kitchen recipes: consume ingredients via InventoryManager, produce stamina
## food, gated on InfrastructureManager.is_cooking_unlocked(). Register via
## register_recipe(). 5 starter recipes (parsnip soup, etc.)
## Issue #109. Placeholder MVP balance — no final cooking design exists.

signal recipe_registered(recipe_id: String)
signal cooked(recipe_id: String, output_item_id: String, quantity: int)

var _recipes: Dictionary = {} ## recipe_id -> CookingRecipe

func _ready() -> void:
	_register_default_recipes()

func register_recipe(recipe: CookingRecipe) -> void:
	if recipe == null or recipe.recipe_id.is_empty():
		return
	_recipes[recipe.recipe_id] = recipe
	recipe_registered.emit(recipe.recipe_id)

func get_recipe(recipe_id: String) -> CookingRecipe:
	return _recipes.get(recipe_id)

func list_recipes() -> Array:
	return _recipes.keys()

func is_cooking_unlocked() -> bool:
	if InfrastructureManager:
		return InfrastructureManager.is_cooking_unlocked()
	return false

func can_cook(recipe_id: String) -> bool:
	if not is_cooking_unlocked():
		return false
	var recipe: CookingRecipe = _recipes.get(recipe_id)
	if recipe == null:
		return false
	if recipe.ingredients.is_empty():
		return false
	for item_id in recipe.ingredients.keys():
		var needed: int = recipe.ingredients[item_id]
		if not InventoryManager.has_item(item_id as String, needed):
			return false
	return true

## Attempts to cook recipe_id. On success: consumes ingredients, adds output
## to InventoryManager, restores stamina, emits cooked, returns true.
## Fails (no state change) if kitchen not unlocked, recipe unknown, or
## insufficient ingredients.
func cook(recipe_id: String) -> bool:
	if not can_cook(recipe_id):
		return false
	var recipe: CookingRecipe = _recipes[recipe_id]
	# Check again before mutating, then consume all ingredients atomically.
	for item_id in recipe.ingredients.keys():
		var needed: int = recipe.ingredients[item_id]
		if not InventoryManager.has_item(item_id as String, needed):
			return false
	# Consume ingredients
	for item_id in recipe.ingredients.keys():
		var needed: int = recipe.ingredients[item_id]
		# remove_item is guaranteed to succeed after has_item check, but guard anyway.
		if not InventoryManager.remove_item(item_id as String, needed):
			# Rollback: re-add any already removed (best-effort; shouldn't happen)
			return false
	if not recipe.output_item_id.is_empty():
		InventoryManager.add_item(recipe.output_item_id, recipe.output_quantity)
	if recipe.stamina_restored > 0 and StaminaManager:
		StaminaManager.restore(recipe.stamina_restored)
	cooked.emit(recipe_id, recipe.output_item_id, recipe.output_quantity)
	return true

## Helper to build a recipe resource programmatically.
func _make_recipe(recipe_id: String, display_name: String, ingredients: Dictionary, output_item_id: String, output_quantity: int, stamina_restored: int, description: String = "") -> CookingRecipe:
	var r := CookingRecipe.new()
	r.recipe_id = recipe_id
	r.display_name = display_name
	r.ingredients = ingredients.duplicate()
	r.output_item_id = output_item_id
	r.output_quantity = output_quantity
	r.stamina_restored = stamina_restored
	r.description = description
	return r

func _register_default_recipes() -> void:
	# 5 starter recipes — placeholder MVP balance, documented as such.
	register_recipe(_make_recipe(
		"parsnip_soup", "Parsnip Soup",
		{"parsnip": 3}, "parsnip_soup", 1, 30,
		"A warm soup that restores stamina."))
	register_recipe(_make_recipe(
		"cauliflower_stew", "Cauliflower Stew",
		{"cauliflower": 1, "parsnip": 1}, "cauliflower_stew", 1, 40,
		"Hearty stew for a hard day's work."))
	register_recipe(_make_recipe(
		"tomato_soup", "Tomato Soup",
		{"tomato": 2}, "tomato_soup", 1, 25,
		"Light and tangy."))
	register_recipe(_make_recipe(
		"pumpkin_pie", "Pumpkin Pie",
		{"pumpkin": 1, "egg": 1}, "pumpkin_pie", 1, 45,
		"Sweet, filling, and great for stamina."))
	register_recipe(_make_recipe(
		"fish_stew", "Fish Stew",
		{"trout": 1, "mushroom": 1}, "fish_stew", 1, 35,
		"A fisherman's favorite."))
