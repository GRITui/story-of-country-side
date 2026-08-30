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

const SAVE_PATH := "user://savegame.json"

## Sibling artifacts of the hardened write/load pipeline (see header notes):
## .bak holds the previous good save (rotation copy, NOT a second slot),
## .tmp is the staging target every write lands in before being verified
## and promoted over the main file.
const BACKUP_PATH := SAVE_PATH + ".bak"
const TMP_PATH := SAVE_PATH + ".tmp"

## Version of the schema the most recent successful load actually applied --
## lets UI/debug report "loaded v2" vs "migrated a v1 legacy file".
var last_loaded_save_version: int = 0

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
		"infrastructure": InfrastructureManager.to_save_dict(),
		"marriage": MarriageManager.to_save_dict(),
		"mining": MiningManager.to_save_dict(),
		"community_goals": CommunityGoalManager.to_save_dict(),
		"weather": WeatherManager.to_save_dict(),
		"cooking": CookingManager.to_save_dict(),
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
	if data.has("cooking"):
		CookingManager.from_save_dict(data["cooking"])
	if data.has("intro_seen"):
		intro_seen = data["intro_seen"]
	# Issue #90: the clock above is restored without firing day_started
	# (that only fires at the 2AM rollover), so any day-edge-derived state
	# must be re-derived here explicitly or a mid-festival save reloads
	# with no festival.
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
	CookingManager.from_save_dict({})
	intro_seen = false
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

func save_game() -> void:
	var snapshot: Variant = SaveFile.wrap(build_save_data())
	if snapshot == null:
		push_warning("SaveManager: failed to wrap aggregate into SaveFile envelope")
		save_failed.emit("wrap_failed")
		return
	if not _atomic_write(JSON.stringify(snapshot.to_json_dict())):
		push_warning("SaveManager: atomic write to %s failed -- previous save preserved" % SAVE_PATH)
		save_failed.emit("write_failed")
		return
	save_succeeded.emit()

## Loads save data from disk into every system. Falls back to the rotated
## .bak copy when the main file is missing, unreadable, corrupt-json, an
## unusable envelope, or from an unsupported schema version; a successful
## fallback ALSO self-heals the dead main slot (copy bak -> main). Emits
## load_succeeded(version) on any applied path; emits load_failed(reason)
## exactly once when nothing recoverable was found. Returns false only when
## NO candidate applied -- callers treat that as "start a new game".
func load_game() -> bool:
	last_loaded_save_version = 0
	var reasons := PackedStringArray()
	for candidate_path: String in [SAVE_PATH, BACKUP_PATH]:
		var error := _load_candidate(candidate_path)
		if error.is_empty():
			load_succeeded.emit(last_loaded_save_version)
			if candidate_path == BACKUP_PATH:
				# Self-heal: whichever way the main slot died (absent or
				# rejected content), re-stamp it from the good backup so the
				# following save cycle doesn't keep rotating around a corpse.
				DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
			return true
		reasons.append(candidate_path.get_file() + ":" + error)
	load_failed.emit("; ".join(reasons))
	return false

## Attempts one file path end-to-end. Returns "" on success (state already
## applied to live managers), else a short reason token for diagnostics.
func _load_candidate(path: String) -> String:
	var text := _read_text(path)
	if text.is_empty():
		return "unreadable_or_empty"
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return "corrupt_json"
	var wrapped: Variant = SaveFile.unwrap(parsed)
	if wrapped == null:
		return "malformed_envelope"
	var migrated: Variant = SaveMigrations.migrate_to_current(wrapped.save_version, wrapped.state)
	if migrated == null:
		return "unsupported_version_%d" % wrapped.save_version
	apply_save_data(migrated["state"])
	last_loaded_save_version = migrated["save_version"]
	return ""

static func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text

## The only code path allowed to write the main save slot. Sequence (all
## steps leave prior-good state intact until final promotion):
##   1. stage JSON into .tmp,
##   2. read .tmp back and validate via SaveFile.unwrap (guards against
##      truncated/disk-full stores AND catches serializer bugs),
##   3. rotate current main -> .bak when one exists,
##   4. promote .tmp -> main (rename).
static func _atomic_write(json_text: String) -> bool:
	var staging := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if staging == null:
		return false
	staging.store_string(json_text)
	staging.flush()
	staging.close()
	var verify_text := _read_text(TMP_PATH)
	if verify_text != json_text or SaveFile.unwrap(JSON.parse_string(verify_text)) == null:
		DirAccess.remove_absolute(TMP_PATH)
		return false
	if FileAccess.file_exists(SAVE_PATH):
		var copied := DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		if copied != OK:
			DirAccess.remove_absolute(TMP_PATH)
			return false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if DirAccess.rename_absolute(TMP_PATH, SAVE_PATH) != OK:
		DirAccess.remove_absolute(TMP_PATH)
		return false
	return true

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## True when a rotated previous-generation save exists (UI/debug telemetry;
## NOT wired into TitleScreen's Continue gate this pass -- enabling
## continue-from-backup there belongs to the frontend lane's overlay work).
func has_backup_file() -> bool:
	return FileAccess.file_exists(BACKUP_PATH)

## Test-only helper (also handy for a future "delete save" UI action) so
## save/load tests don't depend on whatever a previous test run/session
## left on disk under user://. Clears ALL artifacts of the hardened
## pipeline -- main, rotation backup, and any orphaned staging temp --
## because a test asserting cleanliness must not fight leftovers from a
## mid-pipeline kill that no longer participates in normal flow anyway.
func delete_save_file() -> void:
	for path: String in [SAVE_PATH, BACKUP_PATH, TMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
