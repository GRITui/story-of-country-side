extends Node
## Autoload: SaveManager
##
## Per Decision D's build note: world state lives in one serializable save
## object instead of scattered globals, even though co-op sync isn't being
## built yet — that structure (not networking itself) is what's cheap to
## get right now and expensive to retrofit later.

func build_save_data() -> Dictionary:
	return {
		"time": TimeManager.to_save_dict(),
		"stamina": StaminaManager.to_save_dict(),
		"relationships": RelationshipManager.to_save_dict(),
	}

func apply_save_data(data: Dictionary) -> void:
	if data.has("time"):
		TimeManager.from_save_dict(data["time"])
	if data.has("stamina"):
		StaminaManager.from_save_dict(data["stamina"])
	if data.has("relationships"):
		RelationshipManager.from_save_dict(data["relationships"])
