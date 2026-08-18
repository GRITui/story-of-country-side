class_name ForageNode
extends RefCounted
## Per-tile gathering state for one forage spot on the map grid (see
## design/art/isometric-grid-spec.md for the (gx, gy) integer tile
## coordinate system this is keyed by in ForagingManager, matching
## FarmPlotManager's Vector2i convention). Plain runtime state, not
## authored content -- ForageableDefinition is the content, this is one
## spot's current holding + cooldown progress against it.
##
## RefCounted, not a scene Node -- same reasoning as FarmPlot: no
## tile-placement/rendering scene exists yet for Foraging, this is
## logic-only state a future scene layer can read/render from.

var item_id: String = "" ## empty when the node holds nothing (on cooldown or never seeded)
var cooldown_days_remaining: int = 0

func is_available() -> bool:
	return not item_id.is_empty() and cooldown_days_remaining <= 0

func is_empty() -> bool:
	return item_id.is_empty()

func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"cooldown_days_remaining": cooldown_days_remaining,
	}

static func from_dict(data: Dictionary) -> ForageNode:
	var node := ForageNode.new()
	node.item_id = data.get("item_id", "")
	node.cooldown_days_remaining = data.get("cooldown_days_remaining", 0)
	return node
