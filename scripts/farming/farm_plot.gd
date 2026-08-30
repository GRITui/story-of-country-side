class_name FarmPlot
extends RefCounted
## Per-tile planting state for one farmable grid position (see
## design/art/isometric-grid-spec.md for the (gx, gy) integer tile
## coordinate system this is keyed by in FarmPlotManager). Plain runtime
## state, not authored content -- CropDefinition is the content, this is
## one plot's progress against it.
##
## RefCounted, not a scene Node -- no tile-placement/rendering scene exists
## yet for Agriculture (isometric-grid-spec only unblocked the coordinate
## math), so this is logic-only state a future TileMap-driven scene layer
## can read/render from, matching how NPCSchedule/QuestDefinition are
## logic/content objects without their own scene presence.

var crop_id: String = ""
var days_grown: int = 0
var watered_today: bool = false
var harvest_ready: bool = false

## True once this plot has produced its first harvest of a regrowable
## crop -- subsequent growth uses CropDefinition.regrow_days instead of
## days_to_grow.
var is_regrowing: bool = false

# --- PO-16BIT-CORE-1: 16x16 soil-state extension (backward compat) ---
var soil_state: int = 0 # FarmPlotManager.SoilState.DRY_GRASS
var crop_type: String:
	get: return crop_id
	set(v): crop_id = v
var growth_stage: int:
	get: return days_grown
	set(v): days_grown = v
var days_watered: int = 0
var days_without_water: int = 0
var blocked_type: String = "" # "rock" / "wood" when soil_state is blocked

func is_empty() -> bool:
	return crop_id.is_empty()

func to_dict() -> Dictionary:
	return {
		"crop_id": crop_id,
		"days_grown": days_grown,
		"watered_today": watered_today,
		"harvest_ready": harvest_ready,
		"is_regrowing": is_regrowing,
		"soil_state": soil_state,
		"days_watered": days_watered,
		"days_without_water": days_without_water,
		"blocked_type": blocked_type,
	}

static func from_dict(data: Dictionary) -> FarmPlot:
	var plot := FarmPlot.new()
	plot.crop_id = data.get("crop_id", "")
	plot.days_grown = data.get("days_grown", 0)
	plot.watered_today = data.get("watered_today", false)
	plot.harvest_ready = data.get("harvest_ready", false)
	plot.is_regrowing = data.get("is_regrowing", false)
	plot.soil_state = int(data.get("soil_state", 0))
	plot.days_watered = int(data.get("days_watered", 0))
	plot.days_without_water = int(data.get("days_without_water", 0))
	plot.blocked_type = str(data.get("blocked_type", ""))
	return plot
