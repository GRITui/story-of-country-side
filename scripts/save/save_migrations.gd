class_name SaveMigrations
extends RefCounted
## Versioned migration pipeline for on-disk saves (save-hardening pass).
##
## A migration step moves a payload EXACTLY ONE version forward (from_version
## N -> N+1). Load-time behavior for any payload: walk the chain until
## CURRENT_SAVE_VERSION is reached, or refuse (null) when the chain can't get
## there -- either because the file is from a FUTURE version (newer build /
## tampered data) or because some historical fork slipped the chain. Refusal
## is always total: SaveManager never applies a partially migrated payload.
##
## Adding a new format version (for any squad):
##   1. Bump CURRENT_SAVE_VERSION (e.g. 2 -> 3).
##   2. Append one step: {"from_version": 2, "migrate": <Callable>}.
##   3. Write a headless test asserting OLD CONTENT SURVIVES the walk
##      (the v1->v2 test below shows the expected shape of that proof).
##
## What is NOT allowed here: dropping keys silently. A migration that removes
## player-visible state must record the removal in the step's own comment.

const CURRENT_SAVE_VERSION := 3

## Identical to SaveFile.LEGACY_VERSION -- declared locally so this file does
## NOT preload save_file.gd and create a circular preload (save_file.gd
## preloads THIS file for CURRENT_SAVE_VERSION). Kept in sync deliberately;
## both must stay `1` (the pre-envelope format's implicit version).
const LEGACY_VERSION := 1

## Season names used ONLY to derive slot metadata ("day/season/year/gold")
## for the v2->v3 step. Kept local so this file stays free of autoload
## dependencies (TimeManager.SEASONS is the same 4-string order; duplicated
## deliberately so the migration pipeline runs in isolation).
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Fall", "Winter"]

static func _steps() -> Array[Dictionary]:
	return [
		{
			"from_version": 1,
			## v1 -> v2: pure envelope re-key. The entire flat v1 payload
			## {"time":..., "stamina":..., ..., "intro_seen":bool} becomes
			## the "state" member of the v2 wrapper (SaveFile). Nothing is
			## renamed, dropped, added, or defaulted -- content survives
			## byte-for-byte, which the test asserts via hash equality.
			"migrate": func(data: Dictionary) -> Dictionary:
				return data,
		},
		{
			"from_version": 2,
			## v2 -> v3 (multi-slot): slot metadata. The multi-slot pass
			## (issue #170) adds a reserved "meta" member to state so the
			## slot-list UI (title screen) can show day/season/year/gold +
			## timestamp + thumbnail WITHOUT loading/deserializing every
			## manager. It is SaveManager-owned meta state, not owned by any
			## gameplay system, so it travels inside "state" exactly like
			## "intro_seen" already does -- that keeps the migration chain
			## (which walks the whole "state" dict) as the single source of
			## truth for format evolution. Fields are DERIVED from the v2
			## payload's own time/shipping_bin members so no player-visible
			## state is invented; thumbnail defaults to "" (no captured image
			## exists for pre-v3 saves), timestamp to now.
			"migrate": func(data: Dictionary) -> Dictionary:
				return ensure_meta(data),
		},
	]

## Guarantees a slot's "meta" block exists, deriving it from the payload's own
## time/shipping_bin members when absent (v2->v3 step body, also run by
## SaveSlots after any load so even a hand-crafted v3 file that skips meta
## still yields correct slot-list metadata). Idempotent: an already-present
## Dictionary "meta" is untouched.
static func ensure_meta(state: Dictionary) -> Dictionary:
	if state.has("meta") and typeof(state["meta"]) == TYPE_DICTIONARY:
		return state
	var time_dict: Dictionary = state.get("time", {})
	var shipping_dict: Dictionary = state.get("shipping_bin", {})
	var season_index := int(time_dict.get("season_index", 0))
	state["meta"] = {
		"day": int(time_dict.get("day_in_season", 1)),
		"season": SEASON_NAMES[season_index % SEASON_NAMES.size()],
		"year": int(time_dict.get("year", 1)),
		"gold": int(shipping_dict.get("gold", 500)),
		"timestamp": int(Time.get_unix_time_from_system()),
		"thumbnail": "",
	}
	return state

## Walks `state` from `file_version` up to CURRENT_SAVE_VERSION.
## Returns {"save_version": <int>, "state": <Dictionary>} on success, or
## null when the payload is unrecoverable (future version, unknown fork).
## Defensive copy of the input keeps caller-held dictionaries intact even
## though the v1->v2 step itself is identity-shaped.
static func migrate_to_current(file_version: int, state: Dictionary) -> Variant:
	if file_version > CURRENT_SAVE_VERSION:
		return null ## future version -- never guess-migrate downward
	if file_version < LEGACY_VERSION:
		return null ## version 0 / negative are not real historical formats
	var payload: Dictionary = state.duplicate(true)
	var version := file_version
	while version < CURRENT_SAVE_VERSION:
		var next_step: Dictionary = {}
		for step in _steps():
			if step["from_version"] == version:
				next_step = step
				break
		if next_step.is_empty():
			return null ## no registered path out of `version`: unknown fork
		var result: Variant = next_step["migrate"].call(payload)
		if typeof(result) != TYPE_DICTIONARY:
			return null ## a buggy step must fail closed, not half-write
		payload = result
		version += 1
	return {"save_version": version, "state": payload}
