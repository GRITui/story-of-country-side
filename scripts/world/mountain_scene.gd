extends Node2D
class_name MountainScene
## Implements #107: Mountain Region Map.
## A mountainside home for the mine entrance.

const GRID_WIDTH := 10
const GRID_HEIGHT := 10
const MINE_ENTRANCE := Vector2i(5, 5)

func _ready() -> void:
	print("Entered Mountain Region")
	# Setup logic for mountain tiles, mine entrance interaction
	# similar to FarmScene's grid but with mountain-themed assets.

func _handle_tile_click(position: Vector2i) -> void:
	if position == MINE_ENTRANCE:
		print("Entering the Mine...")
		# Transition to MineScene
	else:
		print("Interacting with mountain terrain at %s" % position)
