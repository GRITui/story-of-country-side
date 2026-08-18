class_name Animal
extends RefCounted
## Per-instance livestock state, keyed by a unique animal_id in
## AnimalManager. RefCounted, not a scene Node, same reasoning as
## FarmPlot (#13) -- no barn/pasture scene layer exists yet, this is
## logic-only state a future scene can read/render from.

var species_id: String = ""
var happiness: int = 50 ## starts at the midpoint -- matches AnimalManager.HAPPINESS_DEFAULT
var fed_today: bool = false
var brushed_today: bool = false
var days_since_product: int = 0
var product_ready: bool = false

func to_dict() -> Dictionary:
	return {
		"species_id": species_id,
		"happiness": happiness,
		"fed_today": fed_today,
		"brushed_today": brushed_today,
		"days_since_product": days_since_product,
		"product_ready": product_ready,
	}

static func from_dict(data: Dictionary) -> Animal:
	var a := Animal.new()
	a.species_id = data.get("species_id", "")
	a.happiness = data.get("happiness", 50)
	a.fed_today = data.get("fed_today", false)
	a.brushed_today = data.get("brushed_today", false)
	a.days_since_product = data.get("days_since_product", 0)
	a.product_ready = data.get("product_ready", false)
	return a
