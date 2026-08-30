class_name SaveFile
extends Resource
## Versioned schema envelope for one on-disk save file (save-hardening pass).
##
## History of the on-disk format:
##   v1 (ENG-26): a flat JSON object -- {"time": ..., "stamina": ..., ...,
##     "intro_seen": bool} -- one key per manager, no version marker, no
##     metadata. Every SaveManager consumer still speaks this exact payload
##     shape via build_save_data()/apply_save_data(), and that stays true:
##     v2 WRAPS the v1 payload under "state" instead of reshaping it.
##   v2 (this branch): envelope object --
##     {
##       "schema":       "story_of_country_side_save",
##       "save_version": <int>,
##       "saved_at_utc": "<ISO-ish timestamp>",
##       "state":        { ...the entire v1 payload, unchanged semantics... }
##     }
##
## Division of labor -- one responsibility per layer:
##   - THIS class owns ENVELOPE RECOGNITION only: it accepts either the v2
##     wrapper or a legacy bare-v1 root and hands callers a uniform
##     {save_version, state} view. It never translates field content.
##   - SaveMigrations owns VERSION TRANSLATION (vN -> current).
##   - SaveManager owns DISK IO, atomicity, backup rotation, recovery.
## Future format changes: append one step in save_migrations.gd and bump
## SaveMigrations.CURRENT_SAVE_VERSION -- no edits needed here.
##
## Legacy detection note: a bare root that is not a wrapper is assumed to be
## a v1-era file, which is sound because v1 was the ONLY unwrapped format
## ever written to user:// (see ENG-26's SaveManager docstring).

## Marker stored on disk so a reader can prove the file is OURS before
## trusting anything inside it.
const SCHEMA_ID := "story_of_country_side_save"

## The pre-envelope format's implicit version (unversioned v1 files).
const LEGACY_VERSION := 1

const SaveMigrations = preload("res://scripts/save/save_migrations.gd")

@export var save_version: int = 0
@export var saved_at_utc: String = ""
@export var state: Dictionary = {}

## Builds a fully-formed envelope around a per-manager aggregate produced by
## SaveManager.build_save_data(). Stamped with the wall-clock UTC timestamp
## so support/debug tooling can tell saves apart even before slots exist.
## NOTE: the return type is deliberately NOT annotated `-> SaveFile` -- a
## self-referencing class_name annotation makes this file refuse to load in
## isolated `--script` test contexts (where class_names aren't registered
## yet), which would break every standalone save test. Behavior is unchanged;
## callers already receive the value as Variant/untyped.
static func wrap(state: Dictionary):
	var snapshot := new()
	snapshot.save_version = SaveMigrations.CURRENT_SAVE_VERSION
	snapshot.saved_at_utc = Time.get_datetime_string_from_system(true)
	snapshot.state = state
	return snapshot

## Serializes to exactly the four documented keys -- no Resource property
## inference on disk, so adding engine-side exports later cannot silently
## change the file contract.
func to_json_dict() -> Dictionary:
	return {
		"schema": SCHEMA_ID,
		"save_version": save_version,
		"saved_at_utc": saved_at_utc,
		"state": state,
	}

## True when a parsed JSON root carries the v2 (or later) wrapper markers.
static func looks_like_wrapper(root: Dictionary) -> bool:
	return root.has("schema") and root.get("schema") == SCHEMA_ID \
		and root.has("state") and root.has("save_version")

## Uniform parse front door for every load path. Accepts:
##   - a parsed v2+ wrapper root -> validated envelope with its own version;
##   - ANY bare Dictionary root  -> legacy v1 envelope (LEGACY_VERSION);
## Returns null for every malformed input shape (non-Dictionaries, wrong
## schema id, missing/non-Dictionary state, missing or insane versions) so
## callers have exactly one failure mode to handle.
static func unwrap(parsed: Variant) -> Variant:
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var root: Dictionary = parsed
	if looks_like_wrapper(root):
		# JSON turns every number into a float on parse, so a strict
		# TYPE_INT check here would reject OUR OWN correctly-written files.
		var raw_version: Variant = root["save_version"]
		if typeof(raw_version) != TYPE_INT and typeof(raw_version) != TYPE_FLOAT:
			return null
		var version := int(raw_version)
		if version < 1:
			return null
		var state_variant: Variant = root["state"]
		if typeof(state_variant) != TYPE_DICTIONARY:
			return null
		var envelope := new()
		envelope.save_version = version
		envelope.saved_at_utc = str(root.get("saved_at_utc", ""))
		envelope.state = state_variant
		return envelope
	# Bare root => legacy v1 payload, whatever keys it happens to carry.
	return _legacy_envelope(root)

static func _legacy_envelope(root: Dictionary):
	var envelope := new()
	envelope.save_version = LEGACY_VERSION
	envelope.saved_at_utc = "" ## v1 never carried timestamps
	envelope.state = root.duplicate(true)
	return envelope
