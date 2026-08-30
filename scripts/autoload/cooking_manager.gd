extends Node
## Autoload: CookingManager
##
## Turns harvested produce into stamina-restoring food (ENG-109).
## Validates ingredients against InventoryManager, consumes them, restores
## stamina via StaminaManager, grants Cooking XP via SkillManager, and
## fires recipe_cooked on success.

signal recipe_cooked(recipe_id: String, stamina_restore: int)

var _recipes: Dictionary = {}  # recipe_id -> RecipeDefinition

func _ready() -> void:
	_register_default_recipes()

func register_recipe(recipe: RecipeDefinition) -> void:
	if recipe == null or recipe.recipe_id.is_empty():
		return
	_recipes[recipe.recipe_id] = recipe

func cook(recipe_id: String) -> bool:
	var recipe: RecipeDefinition = _recipes.get(recipe_id)
	if recipe == null:
		return false
	for i in range(recipe.ingredients.size()):
		var item_id: String = recipe.ingredients[i]
		var qty: int = recipe.ingredient_quantities[i]
		if not InventoryManager.has_item(item_id, qty):
			return false
	for i in range(recipe.ingredients.size()):
		InventoryManager.remove_item(recipe.ingredients[i], recipe.ingredient_quantities[i])
	StaminaManager.restore(recipe.stamina_restore)
	SkillManager.add_xp("Cooking", recipe.xp_granted)
	recipe_cooked.emit(recipe_id, recipe.stamina_restore)
	return true

func get_available_recipes() -> Array:
	var available: Array = []
	for recipe_id: String in _recipes:
		var recipe: RecipeDefinition = _recipes[recipe_id]
		var can_cook := true
		for i in range(recipe.ingredients.size()):
			if not InventoryManager.has_item(recipe.ingredients[i], recipe.ingredient_quantities[i]):
				can_cook = false
				break
		if can_cook:
			available.append(recipe)
	return available

func get_all_recipes() -> Array:
	var result: Array = []
	for recipe_id: String in _recipes:
		result.append(_recipes[recipe_id])
	return result

func _register_default_recipes() -> void:
	register_recipe(_make_recipe("parsnip_soup", "Parsnip Soup", ["parsnip"], [1], 30, 5))
	register_recipe(_make_recipe("veggie_medley", "Veggie Medley", ["tomato", "pumpkin"], [1, 1], 50, 10))
	register_recipe(_make_recipe("fish_stew", "Fish Stew", ["carp"], [1], 40, 8))
	register_recipe(_make_recipe("goldfish_sushi", "Goldfish Sushi", ["goldfish"], [1], 60, 12))

func _make_recipe(recipe_id: String, display_name: String, ingredients: Array[String], ingredient_quantities: Array[int], stamina_restore: int, xp_granted: int) -> RecipeDefinition:
	var r := RecipeDefinition.new()
	r.recipe_id = recipe_id
	r.display_name = display_name
	r.ingredients = ingredients
	r.ingredient_quantities = ingredient_quantities
	r.stamina_restore = stamina_restore
	r.xp_granted = xp_granted
	return r

func to_save_dict() -> Dictionary:
	return {}

func from_save_dict(_data: Dictionary) -> void:
	pass
