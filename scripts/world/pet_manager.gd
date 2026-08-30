extends Node
## Implements #114: Pets (Dog/Cat companion).
## Handles pet AI, following behavior, and pet-player relationship.

signal pet_action(action: String)

var current_pet: String = "none" # "dog", "cat", "none"
var pet_position: Vector2 = Vector2.ZERO

func adopt_pet(pet_type: String) -> void:
	if pet_type == "dog" or pet_type == "cat":
		current_pet = pet_type
		print("Adopted a %s!" % pet_type)

func update_pet_position(player_pos: Vector2) -> void:
	if current_pet == "none": return
	
	# Simple "follow" logic: move towards player with slight offset
	var target_pos = player_pos + Vector2(16, 16)
	pet_position = pet_position.lerp(target_pos, 0.1)

func get_pet_sprite() -> String:
	if current_pet == "none": return ""
	return "res://assets/pixelart/pets/%s.png" % current_pet
