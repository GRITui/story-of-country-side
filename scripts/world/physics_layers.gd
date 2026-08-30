class_name PhysicsLayers
extends Object
## Single source of truth for world-scene collision layer assignment
## (world-scene structure pass). pairs with
## design/world/world-scene-structure-spec.md sections 3-5, which specify
## WHICH prefab gets which layer/mask and why.
##
## Convention: values are 1-based PROJECT PHYSICS LAYER indices (what you
## type into the editor's Layer name column), matching Godot's serialized
## project.godot [layer_names] convention. Bitmasks go through mask().
##
## STATUS (read me before wiring): nothing in the runtime consumes these
## yet. Today's PlayerAvatar/NPCController are script-built Node2D renders
## with zero physics presence (deliberate #100 scope cut), and SleepZone's
## Area2D hooks are provided-but-unwired. This class exists so the FIRST
## physics-enabled prefab PR lands against fixed names instead of inventing
## bit numbers per scene, which is how layer sprawl starts.
##
## Suggested project.godot names once wired (do NOT edit project.godot from
## a docs-only task):
##   1 TERRAIN_SOLID, 2 PROPS_SOLID, 3 INTERACTABLE, 4 WATER_BLOCKER,
##   5 DYNAMIC_BODY, 6 SCENE_TRANSITION

const TERRAIN_SOLID := 1      ## tilemap solids: rock walls, map borders
const PROPS_SOLID := 2        ## large solid props: shipping bin, buildings
const INTERACTABLE := 3       ## Area2D interactables: sleep zones, bins
const WATER_BLOCKER := 4      ## water edge tiles/ocean (coast scenes)
const DYNAMIC_BODY := 5       ## player + villager CharacterBody2D bodies
const SCENE_TRANSITION := 6   ## TravelZone Area2Ds calling travel_to()

## Composes a collision_mask/collision_layer bitmask out of 1-based ids:
## PhysicsLayers.mask([PhysicsLayers.DYNAMIC_BODY, PhysicsLayers.INTERACTABLE])
static func mask(layer_ids: Array[int]) -> int:
	var bits := 0
	for id in layer_ids:
		bits |= 1 << (id - 1)
	return bits
