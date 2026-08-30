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
## file-backed home. Kept intentionally minimal at ENG-26 time: one JSON
## file, no save slots/thumbnails/versioning -- the menu-hud-flow-spec's
## save-slot list (design/ui-flows/menu-hud-flow-spec.md §1) is a future UI
## concern once a title screen actually exists.
##
## SAVE-HARDENING pass (orch-006 save-integrity branch): the minimal v1 disk
## format is superseded by a versioned envelope with crash-safety semantics,
## WITHOUT breaking the manager-facing API (build_save_data/apply_save_data/
## new_game contracts are untouched -- see scripts/save/save_file.gd for the
## envelope schema and scripts/save/save_migrations.gd for version policy):
##   - Atomic write: payload lands in .tmp first, is read back and validated
##     through SaveFile.unwrap() BEFORE anything touches the main slot; only
##     then is .tmp promoted over main. A crash mid-write can therefore only
##     ever leave: previous main intact, or main gone/.tmp orphaned.
##   - Backup rotation: overwriting an existing main copies it to .bak first,
##     so exactly one generation of history exists behind every current save.
##   - Recovery on load: unreadable/corrupt/unsupported main falls back to
##     .bak once; if .bak loads, its payload is ALSO copied back over the
##     dead main (self-heal), so the next cycle starts from a sane slot.
##   - Versioning: legacy unversioned files load as v1 and migrate forward;
##     files from FUTURE versions refuse cleanly (live state untouched,
##     caller gets false -> treated as "no usable save", never as new game).
##
## MULTI-SLOT pass (issue #170): three slots (user://save_<n>.json, n in 0..2),
## each running the FULL hardened pipeline above independently (per-slot .bak/
## .tmp, per-slot self-heal). All on-disk IO now lives in scripts/save/
## save_slots.gd -- this class keeps the world-state contract (build/apply/
## new_game), stamps slot metadata (day/season/year/gold/timestamp/thumbnail,
## the "meta" member of state), and tracks `current_slot` so the pre-slot
## no-argument calls (save_game()/load_game()/delete_save_file()) keep working
## against the active slot, defaulting to 0 for backward compatibility. The
## legacy single file user://savegame.json is adopted into slot 0 on first
## touch (see SaveSlots' header note). TitleScreen gained a per-slot picker for
## New Game / Continue (see title_screen.gd); PauseMenu's Save & Quit keeps
## calling the no-argument save_game() and so transparently saves to the
## active slot.
##
## Crash-window ledger for the write path (honest edges, not perfect-FS):
##   crash after copy-to-bak, before promote -> old main still present, .bak
##     duplicates it; next save rotates normally.
##   crash after remove(main), before rename -> no main; load() recovers via
##     .bak on the NEXT launch and self-heals the slot. Acceptable residual:
##     losing writes made after the last two saves' rotation boundary.

signal save_succeeded()
signal save_failed(reason: String)
signal load_succeeded(save_version: int)
signal load_failed(reason: String)

const SaveFile = preload("res://scripts/save/save_file.gd")
const SaveMigrations = preload("res://scripts/save/save_migrations.gd")
const SaveSlots = preload("res://scripts/save/save_slots.gd")

## MULTI-SLOT pass (issue #170): all on-disk IO now lives in scripts/save/
## save_slots.gd -- three slots (user://save_<n>.json, n in 0..2), each with
## its own .bak/.tmp sibling artifacts and the full save-hardening pipeline
## (atomic write + verify + rotate, main->.bak fallback read with self-heal).
## The legacy single file user://savegame.json is adopted into slot 0 on
## first touch (see SaveSlots' header note). These consts are kept ONLY as a
## backward-compatible mirror of the pre-slot contract (slot 0), since callers
## such as _p0_repro.gd and the autoplay drivers still reference
## delete_save_file()/save_game()/load_game() with no slot argument.
const SAVE_PATH := "user://save_0.json"
const BACKUP_PATH := "user://save_0.json.bak"
const TMP_PATH := "user://save_0.json.tmp"

## Version of the schema the most recent successful load actually applied --
## lets UI/debug report "loaded v2" vs "migrated a v1 legacy file".
var last_loaded_save_version: int = 0

## The slot the no-argument save_game()/load_game()/delete_save_file() calls
## operate on. Defaults to 0 (the old single-slot behavior) and is advanced by
## every slot-explicit call, so PauseMenu's plain save_game() and
## MainController's plain load_game() keep working against whatever slot the
## player is actually playing.
var current_slot: int = 0

## Whether the player has seen the opening-hook intro sequence (ENG-26) on
## this save. Not part of build_save_data()'s per-system dictionaries
## since it isn't owned by any gameplay system -- it's meta save state,
## same as SaveManager owning the file path itself.
var intro_seen: bool = false

func build_save_data() -> Dictionary:
	var active_festival_id: String = ""
	if FestivalManager.has_method("get_active_festival"):
		active_festival_id = FestivalManager.get_active_festival()
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
		"infrastructure": InfrastructureManager.to_save_dict(),
		"marriage": MarriageManager.to_save_dict(),
		"mining": MiningManager.to_save_dict(),
		"community_goals": CommunityGoalManager.to_save_dict(),
		"weather": WeatherManager.to_save_dict(),
		"journal": JournalManager.to_save_dict(),
		"intro_seen": intro_seen,
		"active_festival_id": active_festival_id,
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
	if data.has("journal"):
		JournalManager.from_save_dict(data["journal"])
	if data.has("intro_seen"):
		intro_seen = data["intro_seen"]
	if data.has("active_festival_id"):
		FestivalManager._active_festival_id = data["active_festival_id"]
	# Issue #90: restore active festival ID from save; fall back to date-derivation
	# if the ID is empty or invalid (e.g. old save format).
	if not FestivalManager.is_festival_day():
		FestivalManager.rederive_active_festival()

## Resets every system to its fresh-boot defaults and starts a brand new
## save -- calling from_save_dict({}) directly (not via apply_save_data,
## which no-ops on missing keys) since each manager's from_save_dict
## already falls back to its own defaults when a key is absent. Starting
## gold (ShippingBinManager.STARTING_GOLD) and starting Copper-tier tools
## (ToolManager) come along for free this way, since those are already
## each manager's own from-nothing default. Starting seeds (#91) are the
## one grant that isn't a manager's own from-nothing default -- it's
## InventoryManager state granted on FarmPlotManager's behalf -- so it's
## called out explicitly below via grant_starting_seeds() instead.
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
	InfrastructureManager.from_save_dict({})
	MarriageManager.from_save_dict({})
	MiningManager.from_save_dict({})
	CommunityGoalManager.from_save_dict({})
	WeatherManager.from_save_dict({})
	JournalManager.from_save_dict({})
	intro_seen = false
	# #90: clear any festival state from previous game before granting starting seeds
	FestivalManager._active_festival_id = ""
	FestivalManager.rederive_active_festival() # expire any live festival against the reset date
	FarmPlotManager.grant_starting_seeds() # #91: seed economy starting grant
	save_game()

func has_seen_intro() -> bool:
	return intro_seen

## Called once the intro sequence controller finishes; persists immediately
## so the flag survives even if the player quits before the next natural
## save point.
func mark_intro_seen() -> void:
	intro_seen = true
	save_game()

## Persists the current world state to a slot. With no argument (the
## pre-slot contract) it writes to `current_slot`, defaulting to slot 0, so
## every existing caller (PauseMenu's Save & Quit, the autoplay drivers,
## MainController's mark_intro_seen path) keeps working unchanged. With an
## explicit slot >= 0 it ALSO advances `current_slot`, making that slot the
## active one for subsequent no-argument calls. Emits save_succeeded() on
## success or save_failed(reason) exactly once on failure -- a failed write
## leaves the previous good save in that slot untouched.
func save_game(slot: int = -1) -> void:
	if slot >= 0:
		current_slot = slot
	var snapshot: Variant = SaveFile.wrap(_build_slot_state())
	if snapshot == null:
		push_warning("SaveManager: failed to wrap aggregate into SaveFile envelope")
		save_failed.emit("wrap_failed")
		return
	if not SaveSlots.write_slot_json(current_slot, JSON.stringify(snapshot.to_json_dict())):
		push_warning("SaveManager: atomic write to slot %d failed -- previous save preserved" % current_slot)
		save_failed.emit("write_failed")
		return
	save_succeeded.emit()

## build_save_data() + the slot's "meta" member (day/season/year/gold/
## timestamp/thumbnail). Meta is SaveManager-owned (not a gameplay system's),
## so it is stamped at persist time rather than living inside any manager.
func _build_slot_state() -> Dictionary:
	var data := build_save_data()
	data["meta"] = _build_meta()
	return data

func _build_meta() -> Dictionary:
	var gold := 500
	if ShippingBinManager:
		gold = ShippingBinManager.gold
	return {
		"day": TimeManager.day_in_season,
		"season": TimeManager.current_season(),
		"year": TimeManager.year,
		"gold": gold,
		"timestamp": int(Time.get_unix_time_from_system()),
		"thumbnail": capture_thumbnail(),
	}

## Captures the current viewport as a small base64 PNG thumbnail for the
## slot-list UI, or "" when no rendered viewport is available (headless boots,
## title screen). UI-coupled -- the slot list degrades to text-only cleanly.
func capture_thumbnail() -> String:
	var viewport := get_viewport()
	if viewport == null:
		return ""
	var texture := viewport.get_texture()
	if texture == null:
		return ""
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return ""
	image.resize(64, 64, Image.INTERPOLATE_BILINEAR)
	var bytes := image.save_png_to_buffer()
	if bytes.is_empty():
		return ""
	return "data:image/png;base64," + Marshalls.raw_to_base64(bytes)

## Loads save data from a slot into every system. With no argument (the
## pre-slot contract) it reads `current_slot`, defaulting to slot 0. An
## explicit slot >= 0 advances `current_slot`. Per-slot recovery semantics:
## unreadable/corrupt/unsupported main falls back to .bak once and self-heals
## the dead main. Emits load_succeeded(version) on any applied path; emits
## load_failed(reason) exactly once when nothing recoverable was found.
## Returns false only when NO candidate applied -- callers treat that as
## "start a new game".
func load_game(slot: int = -1) -> bool:
	if slot >= 0:
		current_slot = slot
	last_loaded_save_version = 0
	var result := SaveSlots.read_slot(current_slot)
	if not result["found"]:
		load_failed.emit(str(result["reason"]))
		return false
	apply_save_data(result["state"])
	last_loaded_save_version = result["save_version"]
	load_succeeded.emit(last_loaded_save_version)
	return true

## Like new_game(), but in an explicit slot: advances `current_slot`, resets
## every system, and persists the fresh save there. The title screen's
## per-slot New Game picker routes here.
func new_game_in_slot(slot: int) -> void:
	current_slot = slot
	new_game()

func slot_count() -> int:
	return SaveSlots.SLOT_COUNT

## Per-slot summaries for the title-screen slot list (see SaveSlots.list_slots
## for the entry shape -- one row per slot, empty slots included, meta already
## normalized so the UI needs no guards).
func list_slots() -> Array[Dictionary]:
	return SaveSlots.list_slots()

## Convenience for the slot list / hover text: the metadata block of one slot
## without touching any live system.
func get_slot_metadata(slot: int) -> Dictionary:
	return SaveSlots.read_slot(slot)["meta"]

func delete_slot(slot: int) -> void:
	SaveSlots.delete_slot(slot)

func has_save_in_slot(slot: int) -> bool:
	return SaveSlots.slot_exists(slot)

func has_backup_in_slot(slot: int) -> bool:
	return SaveSlots.slot_has_backup(slot)

func has_save_file() -> bool:
	return SaveSlots.slot_exists(current_slot)

## True when ANY of the three slots holds a save -- the gate for the title
## screen's Continue entry (which then opens the slot list).
func has_any_save() -> bool:
	return SaveSlots.has_any_save()

## Backward-compatible alias: the current slot's rotated-backup existence
## (UI/debug telemetry). Multi-slot callers should prefer has_backup_in_slot().
func has_backup_file() -> bool:
	return SaveSlots.slot_has_backup(current_slot)

## Backward-compatible alias: deletes the current slot's main, rotation
## backup, and any orphaned staging temp. Multi-slot callers should prefer
## delete_slot(slot).
func delete_save_file() -> void:
	SaveSlots.delete_slot(current_slot)
