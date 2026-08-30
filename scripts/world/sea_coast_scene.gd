extends Node2D
class_name SeaCoastScene
## Implements #105: Sea Coast Map.
## Pier scene giving the existing ocean fish pools a home.

const GRID_WIDTH := 15
const GRID_HEIGHT := 5
const PIER_POSITION := Vector2i(0, 2)

func _ready() -> void:
	print("Entered Sea Coast")
	# Setup logic for pier and shoreline.

func _handle_tile_click(position: Vector2i) -> void:
	if position == PIER_POSITION:
		print("Fishing from the pier...")
		# Trigger FishingManager.attempt_catch()
	else:
		print("Walking on the shoreline at %s" % position)
