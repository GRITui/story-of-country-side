extends CanvasLayer
class_name KitchenOverlay

@onready var _recipe_list: VBoxContainer = $Margin/Panel/VBox/RecipeList
@onready var _status_label: Label = $Margin/Panel/VBox/Status

func _ready() -> void:
	_refresh_recipes()
	CookingManager.meal_ready.connect(_on_meal_ready)

func _refresh_recipes() -> void:
	# Clear existing
	for child in _recipe_list.get_children():
		child.queue_free()
	
	for recipe in CookingManager.get_all_recipes():
		var btn := Button.new()
		btn.text = "%s (Stamina: %d)" % [recipe.display_name, recipe.stamina_restore]
		btn.pressed.connect(_on_recipe_selected.bind(recipe.recipe_id))
		_recipe_list.add_child(btn)

func _on_recipe_selected(recipe_id: String) -> void:
	if CookingManager.can_cook(recipe_id):
		_status_label.text = "Cooking..."
		CookingManager.cook(recipe_id)
	else:
		_status_label.text = "Missing ingredients!"

func _on_meal_ready(_id: String, name: String, stamina: int) -> void:
	_status_label.text = "Delicious! %s restored %d stamina." % [name, stamina]
	await get_tree().create_timer(3.0).timeout
	_status_label.text = "Select a recipe to cook!"
