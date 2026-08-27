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
##
## S-Tier Zeta (QoL/Saves P0): multi-slot + versioning per #118. Single
## slot was the #1 anxiety source. Now slot 0 is the default (backward
## compat), slot path is user://savegame_%d.json, legacy
## user://savegame.json auto-migrates to slot 0 on first access.

const SAVE_VERSION := 1
const SAVE_PATH := "user://savegame.json"
const SAVE_SLOT_PATH := "user://savegame_%d.json"
const MAX_SLOTS := 3

## Whether the player has seen the opening-hook intro sequence (ENG-26) on
## this save. Not part of build_save_data()'s per-system dictionaries
## since it isn't owned by any gameplay system -- it's meta save state,
## same as SaveManager owning the file path itself.
var intro_seen: bool = false

func _slot_path(slot: int) -> String:
	return SAVE_SLOT_PATH % slot

func _migrate_legacy_if_needed() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(_slot_path(0)):
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if src == null:
			return
		var text := src.get_as_text()
		src.close()
		var dst := FileAccess.open(_slot_path(0), FileAccess.WRITE)
		if dst == null:
			return
		dst.store_string(text)
		dst.close()
		# Keep legacy file until first successful slot-0 load to avoid
		# data loss on crash mid-migration; remove after copy.
		DirAccess.remove_absolute(SAVE_PATH)

func _get_timestamp() -> int:
	return int(Time.get_unix_time_from_system())

func _get_playtime() -> int:
	# Approximate playtime as total in-game minutes (year/day/hour/minute).
	# Purely informational for slot listing; not used for game logic.
	var tm = TimeManager
	if tm == null:
		return 0
	var total_days: int = 0
	if "year" in tm and "season_index" in tm and "day_in_season" in tm:
		total_days = (tm.year - 1) * 112 + tm.season_index * 28 + (tm.day_in_season - 1)
	var playtime: int = total_days * 1440 + tm.hour * 60 + tm.minute
	return playtime

func build_save_data() -> Dictionary:
	var data := {
		"save_version": SAVE_VERSION,
		"timestamp": _get_timestamp(),
		"playtime": _get_playtime(),
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
		"infrastructure": InfrastructureManager.to_save_dict(),
		"marriage": MarriageManager.to_save_dict(),
		"mining": MiningManager.to_save_dict(),
		"community_goals": CommunityGoalManager.to_save_dict(),
		"weather": WeatherManager.to_save_dict(),
		"intro_seen": intro_seen,
	}
	return data

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
	if data.has("infrastructure"):
		InfrastructureManager.from_save_dict(data["infrastructure"])
	if data.has("marriage"):
		MarriageManager.from_save_dict(data["marriage"])
	if data.has("mining"):
		MiningManager.from_save_dict(data["mining"])
	if data.has("community_goals"):
		CommunityGoalManager.from_save_dict(data["community_goals"])
	if data.has("weather"):
		WeatherManager.from_save_dict(data["weather"])
	if data.has("intro_seen"):
		intro_seen = data["intro_seen"]
	# save_version is informational; older saves without it are treated as v0
	# and upgraded implicitly by apply_save_data filling missing keys with defaults.

## Resets every system to its fresh-boot defaults and starts a brand new
## save -- calling from_save_dict({}) directly (not via apply_save_data,
## which no-ops on missing keys) since each manager's from_save_dict
## already falls back to its own defaults when a key is absent. Starting
## gold (ShippingBinManager.STARTING_GOLD) and starting Copper-tier tools
## (ToolManager) come along for free this way, since those are already
## each manager's own from-nothing default -- see the PR description for
## why a fuller starting-inventory grant (seeds, a few crops) isn't part
## of this reset yet.
func new_game(slot: int = 0) -> void:
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
	InfrastructureManager.from_save_dict({})
	MarriageManager.from_save_dict({})
	MiningManager.from_save_dict({})
	CommunityGoalManager.from_save_dict({})
	WeatherManager.from_save_dict({})
	intro_seen = false
	save_game(slot)

func has_seen_intro() -> bool:
	return intro_seen

## Called once the intro sequence controller finishes; persists immediately
## so the flag survives even if the player quits before the next natural
## save point.
func mark_intro_seen() -> void:
	intro_seen = true
	save_game()

func save_game(slot: int = 0) -> void:
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: failed to open %s for writing" % path)
		return
	file.store_string(JSON.stringify(build_save_data()))
	file.close()

## Loads save data from disk into every system if a save file exists.
## Returns false (leaving current in-memory state untouched) when there's
## no save file yet or it's unreadable/corrupt -- the caller (main_controller)
## treats that as "start a new game" rather than crashing on a bad file.
func load_game(slot: int = 0) -> bool:
	_migrate_legacy_if_needed()
	var path := _slot_path(slot)
	# Fallback: if slot 0 has no file but legacy still exists (migration
	# failed or was interrupted), try legacy directly.
	if slot == 0 and not FileAccess.file_exists(path) and FileAccess.file_exists(SAVE_PATH):
		path = SAVE_PATH
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	apply_save_data(parsed)
	# If we loaded from legacy, also write to slot 0 for next boot
	if path == SAVE_PATH:
		save_game(0)
		DirAccess.remove_absolute(SAVE_PATH)
	return true

func has_save_file(slot: int = 0) -> bool:
	_migrate_legacy_if_needed()
	if slot == 0 and FileAccess.file_exists(SAVE_PATH):
		return true
	return FileAccess.file_exists(_slot_path(slot))

## Test-only helper (also handy for a future "delete save" UI action) so
## save/load tests don't depend on whatever a previous test run/session
## left on disk under user://.
func delete_save_file(slot: int = 0) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if slot == 0 and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func list_slots() -> Array:
	_migrate_legacy_if_needed()
	var result: Array = []
	for i in range(MAX_SLOTS):
		var path := _slot_path(i)
		var exists := FileAccess.file_exists(path)
		# Legacy counts as slot 0 existing
		if i == 0 and not exists and FileAccess.file_exists(SAVE_PATH):
			exists = true
			path = SAVE_PATH
		var entry := {
			"slot": i,
			"exists": exists,
			"timestamp": 0,
			"playtime": 0,
		}
		if exists:
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var text := file.get_as_text()
				file.close()
				var parsed: Variant = JSON.parse_string(text)
				if typeof(parsed) == TYPE_DICTIONARY:
					entry["timestamp"] = parsed.get("timestamp", 0)
					entry["playtime"] = parsed.get("playtime", 0)
		result.append(entry)
	return result
