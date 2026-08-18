extends Node
## Autoload: SaveManager
##
## Per Decision D's build note: world state lives in one serializable save
## object instead of scattered globals, even though co-op sync isn't being
## built yet — that structure (not networking itself) is what's cheap to
## get right now and expensive to retrofit later.
##
## ENG-26 (Opening hook) adds the actual new_game()/save_game()/load_game()
## entry points -- nothing in the repo persisted to disk before this, so
## "intro flagged as seen, persisted so it doesn't replay" needed a real
## file-backed home. Kept intentionally minimal: one JSON file, no save
## slots/thumbnails/versioning -- the menu-hud-flow-spec's save-slot list
## (design/ui-flows/menu-hud-flow-spec.md §1) is a future UI concern once
## a title screen actually exists, not blocking this issue's scope.

const SAVE_PATH := "user://savegame.json"

## Whether the player has seen the opening-hook intro sequence (ENG-26) on
## this save. Not part of build_save_data()'s per-system dictionaries
## since it isn't owned by any gameplay system -- it's meta save state,
## same as SaveManager owning the file path itself.
var intro_seen: bool = false

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
		"foraging": ForagingManager.to_save_dict(),
		"animals": AnimalManager.to_save_dict(),
		"mining": MiningManager.to_save_dict(),
		"intro_seen": intro_seen,
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
	if data.has("foraging"):
		ForagingManager.from_save_dict(data["foraging"])
	if data.has("animals"):
		AnimalManager.from_save_dict(data["animals"])
	if data.has("mining"):
		MiningManager.from_save_dict(data["mining"])
	if data.has("intro_seen"):
		intro_seen = data["intro_seen"]

## Resets every system to its fresh-boot defaults and starts a brand new
## save -- calling from_save_dict({}) directly (not via apply_save_data,
## which no-ops on missing keys) since each manager's from_save_dict
## already falls back to its own defaults when a key is absent. Starting
## gold (ShippingBinManager.STARTING_GOLD) and starting Copper-tier tools
## (ToolManager) come along for free this way, since those are already
## each manager's own from-nothing default -- see the PR description for
## why a fuller starting-inventory grant (seeds, a few crops) isn't part
## of this reset yet.
func new_game() -> void:
	TimeManager.from_save_dict({})
	StaminaManager.from_save_dict({})
	ShippingBinManager.from_save_dict({})
	RelationshipManager.from_save_dict({})
	QuestManager.from_save_dict({})
	SkillManager.from_save_dict({})
	ToolManager.from_save_dict({})
	InventoryManager.from_save_dict({})
	FarmPlotManager.from_save_dict({})
	ForagingManager.from_save_dict({})
	AnimalManager.from_save_dict({})
	MiningManager.from_save_dict({})
	intro_seen = false
	save_game()

func has_seen_intro() -> bool:
	return intro_seen

## Called once the intro sequence controller finishes; persists immediately
## so the flag survives even if the player quits before the next natural
## save point.
func mark_intro_seen() -> void:
	intro_seen = true
	save_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: failed to open %s for writing" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(build_save_data()))
	file.close()

## Loads save data from disk into every system if a save file exists.
## Returns false (leaving current in-memory state untouched) when there's
## no save file yet or it's unreadable/corrupt -- the caller (main_controller)
## treats that as "start a new game" rather than crashing on a bad file.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	apply_save_data(parsed)
	return true

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Test-only helper (also handy for a future "delete save" UI action) so
## save/load tests don't depend on whatever a previous test run/session
## left on disk under user://.
func delete_save_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
