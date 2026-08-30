class_name SaveSlots
extends RefCounted
## Pure multi-slot disk layer for the save system (issue #170).
##
## Owns EVERYTHING about where a save physically lives and how it gets on
## and off the disk: per-slot paths (user://save_<n>.json, n in 0..SLOT_COUNT-1),
## the atomic write + verification + backup-rotation pipeline, the main->.bak
## fallback read with self-heal, slot listing metadata, slot deletion, and
## one-time adoption of the legacy single-slot file. It deliberately does NOT
## know how to aggregate/apply world state -- that is SaveManager's job, and
## keeping it out is what makes this class loadable and testable in isolated
## headless contexts even while the full autoload tree is broken on a branch.
##
## Design decisions inherited from the save-hardening pass (orch-006), applied
## per-slot:
##   - Atomic write: JSON lands in <slot>.tmp first, is read back and
##     validated through SaveFile.unwrap() BEFORE anything touches the main
##     slot; only then is .tmp promoted over main. A crash mid-write can only
##     ever leave: previous main intact, or main gone / .tmp orphaned.
##   - Backup rotation: overwriting an existing main copies it to .bak first,
##     so exactly one generation of history exists behind every current save.
##   - Recovery on load: unreadable/corrupt/unsupported main falls back to
##     .bak once; if .bak loads, its payload is ALSO copied back over the
##     dead main (self-heal), so the next cycle starts from a sane slot.
##   - Versioning: legacy unversioned files load as v1 and migrate forward via
##     SaveMigrations; files from FUTURE versions refuse cleanly.
##
## Legacy adoption: the pre-slot single file was user://savegame.json. To keep
## existing saves alive across the multi-slot switch, the first time this class
## is touched it renames savegame.json -> save_0.json (plus .bak/.tmp siblings)
## WHEN slot 0 does not already exist. Idempotent: after the rename the legacy
## path is gone, so the check is a no-op forever after. If save_0.json ALREADY
## exists alongside savegame.json the legacy file is left untouched (ambiguous
## overlap -- never guess).
##
## Slot metadata ("meta" member of state, see save_migrations.gd v2->v3):
##   day:int season:String year:int gold:int timestamp:int thumbnail:String
## read_slot()/list_slots() normalize a missing/partial meta block to
## DEFAULT_META so the slot-list UI never has to guard for it.

const SaveFile = preload("res://scripts/save/save_file.gd")
const SaveMigrations = preload("res://scripts/save/save_migrations.gd")

const SLOT_COUNT := 3

## Pre-slot single-save file (ENG-26 era). Adopted into slot 0 on first touch.
const LEGACY_SINGLE_PATH := "user://savegame.json"

## Fallback slot metadata for a save that carries no usable meta block (a
## pre-v3 file that somehow skipped migration, or partial data). Values match
## the game's own from-nothing defaults (day 1 / Spring / year 1 / 500 gold).
const DEFAULT_META := {
	"day": 1,
	"season": "Spring",
	"year": 1,
	"gold": 500,
	"timestamp": 0,
	"thumbnail": "",
}

static func slot_path(slot: int) -> String:
	return "user://save_%d.json" % slot

static func slot_backup_path(slot: int) -> String:
	return slot_path(slot) + ".bak"

static func slot_tmp_path(slot: int) -> String:
	return slot_path(slot) + ".tmp"

## One-time adoption of the legacy single-slot file (see header note).
## `_adopt_decided` pins the decision for the whole process: once we've looked
## at the disk we don't re-evaluate, so deleting slot 0 later in the same
## session cannot silently resurrect a still-present legacy file the adoption
## pass chose to leave alone (the ambiguous-overlap case).
static var _adopt_decided := false
static func _adopt_legacy_once() -> void:
	if _adopt_decided:
		return
	_adopt_decided = true
	if not FileAccess.file_exists(LEGACY_SINGLE_PATH):
		return
	if FileAccess.file_exists(slot_path(0)):
		return ## slot 0 already taken -- ambiguous overlap, never guess
	if DirAccess.rename_absolute(LEGACY_SINGLE_PATH, slot_path(0)) != OK:
		return
	var legacy_bak := LEGACY_SINGLE_PATH + ".bak"
	if FileAccess.file_exists(legacy_bak):
		DirAccess.rename_absolute(legacy_bak, slot_backup_path(0))
	var legacy_tmp := LEGACY_SINGLE_PATH + ".tmp"
	if FileAccess.file_exists(legacy_tmp):
		DirAccess.rename_absolute(legacy_tmp, slot_tmp_path(0))

## Full end-to-end read of one slot. Tries main then .bak; on a successful
## .bak fallback it self-heals (copies bak back over the dead main) so the
## following save cycle doesn't keep rotating around a corpse. Returns:
##   {found: bool, save_version: int, state: Dictionary, meta: Dictionary,
##    used_backup: bool, reason: String}
## found=false means NO candidate applied (missing, corrupt, future version) --
## callers treat that as "no usable save", never as a new game.
static func read_slot(slot: int) -> Dictionary:
	_adopt_legacy_once()
	var result := {
		"found": false,
		"save_version": 0,
		"state": {},
		"meta": DEFAULT_META.duplicate(),
		"used_backup": false,
		"reason": "",
	}
	for candidate in [
		{"path": slot_path(slot), "used_backup": false},
		{"path": slot_backup_path(slot), "used_backup": true},
	]:
		var err := _read_candidate(candidate["path"], result)
		if err.is_empty():
			result["found"] = true
			result["used_backup"] = candidate["used_backup"]
			if candidate["used_backup"]:
				# Self-heal the dead main from the good backup.
				if FileAccess.file_exists(slot_path(slot)):
					DirAccess.remove_absolute(slot_path(slot))
				DirAccess.copy_absolute(slot_backup_path(slot), slot_path(slot))
			return result
		if result["reason"].is_empty():
			result["reason"] = "%s:%s" % [candidate["path"].get_file(), err]
		else:
			result["reason"] = "%s; %s:%s" % [result["reason"], candidate["path"].get_file(), err]
	return result

## Attempts one file path end-to-end, writing its result into `result`.
## Returns "" on success, else a short reason token for diagnostics.
static func _read_candidate(path: String, result: Dictionary) -> String:
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
	result["save_version"] = migrated["save_version"]
	result["state"] = SaveMigrations.ensure_meta(migrated["state"])
	result["meta"] = _normalize_meta(result["state"].get("meta", {}))
	return ""

## Merges a slot's stored meta block over DEFAULT_META so a missing/incomplete
## block still yields every key the slot-list UI expects.
static func _normalize_meta(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return DEFAULT_META.duplicate()
	var meta := DEFAULT_META.duplicate()
	for key: String in raw:
		if raw[key] != null:
			meta[key] = raw[key]
	return meta

## The only code path allowed to write a slot's main file (staging, verify,
## rotate, promote -- see header note). json_text must already be the JSON
## serialization of a complete SaveFile envelope.
static func write_slot_json(slot: int, json_text: String) -> bool:
	_adopt_legacy_once()
	var main := slot_path(slot)
	var bak := slot_backup_path(slot)
	var tmp := slot_tmp_path(slot)
	var staging := FileAccess.open(tmp, FileAccess.WRITE)
	if staging == null:
		return false
	staging.store_string(json_text)
	staging.flush()
	staging.close()
	# Read .tmp back and validate through the same envelope gate callers load
	# with -- guards against truncated/disk-full stores AND serializer bugs.
	var verify_text := _read_text(tmp)
	if verify_text != json_text or SaveFile.unwrap(JSON.parse_string(verify_text)) == null:
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(main):
		if DirAccess.copy_absolute(main, bak) != OK:
			DirAccess.remove_absolute(tmp)
			return false
	if FileAccess.file_exists(main):
		DirAccess.remove_absolute(main)
	if DirAccess.rename_absolute(tmp, main) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true

static func delete_slot(slot: int) -> void:
	for path: String in [slot_path(slot), slot_backup_path(slot), slot_tmp_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

static func slot_exists(slot: int) -> bool:
	_adopt_legacy_once()
	return FileAccess.file_exists(slot_path(slot))

## True when a rotated previous-generation save exists for a slot (UI/debug
## telemetry -- a corrupt main with a healthy .bak still reads via read_slot).
static func slot_has_backup(slot: int) -> bool:
	return FileAccess.file_exists(slot_backup_path(slot))

static func has_any_save() -> bool:
	_adopt_legacy_once()
	for n in range(SLOT_COUNT):
		if FileAccess.file_exists(slot_path(n)):
			return true
	return false

## Per-slot summary for the title-screen slot list. One entry per slot index,
## even empty ones, so the UI can render "Empty" rows without index math:
##   {index: int, found: bool, save_version: int, meta: Dictionary}
static func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for n in range(SLOT_COUNT):
		var r := read_slot(n)
		slots.append({
			"index": n,
			"found": r["found"],
			"save_version": r["save_version"],
			"meta": r["meta"],
		})
	return slots

static func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text