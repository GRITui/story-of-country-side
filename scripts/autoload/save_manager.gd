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
		"shipping_bin": ShippingBinManager.to_save_dict(),
		"relationships": RelationshipManager.to_save_dict(),
		"quests": QuestManager.to_save_dict(),
		"skills": SkillManager.to_save_dict(),
		"tools": ToolManager.to_save_dict(),
		"inventory": InventoryManager.to_save_dict(),
		"farm_plots": FarmPlotManager.to_save_dict(),
	}

func apply_save_data(data: Dictionary) -> void:
	if data.has("time"):
		TimeManager.from_save_dict(data["time"])
	if data.has("stamina"):
		StaminaManager.from_save_dict(data["stamina"])
	if data.has("shipping_bin"):
		ShippingBinManager.from_save_dict(data["shipping_bin"])
	if data.has("relationships"):
		RelationshipManager.from_save_dict(data["relationships"])
	if data.has("quests"):
		QuestManager.from_save_dict(data["quests"])
	if data.has("skills"):
		SkillManager.from_save_dict(data["skills"])
	if data.has("tools"):
		ToolManager.from_save_dict(data["tools"])
	if data.has("inventory"):
		InventoryManager.from_save_dict(data["inventory"])
	if data.has("farm_plots"):
		FarmPlotManager.from_save_dict(data["farm_plots"])
