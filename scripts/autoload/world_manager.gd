extends Node
## Autoload: WorldManager
##
## Implements #106: World Expansion.
## Manages the transition between the three main biomes.

signal location_changed(new_location: String)

const LOCATIONS = {
	"VALLEY": "FarmScene",
	"MOUNTAIN": "MountainScene",
	"SEA_COAST": "SeaCoastScene"
}

var current_location: String = "VALLEY"

func travel_to(location_id: String) -> void:
	if not LOCATIONS.has(location_id):
		return
	
	current_location = location_id
	location_changed.emit(location_id)
	
	# Logic for scene swapping would be handled by a MainController
	# but the state is tracked here.
	print("Traveling to %s..." % location_id)

func get_scene_for_location(location_id: String) -> String:
	return LOCATIONS.get(location_id, "FarmScene")
