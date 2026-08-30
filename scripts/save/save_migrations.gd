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

const CURRENT_SAVE_VERSION := 2

## Identical to SaveFile.LEGACY_VERSION -- declared locally so this file does
## NOT preload save_file.gd and create a circular preload (save_file.gd
## preloads THIS file for CURRENT_SAVE_VERSION). Kept in sync deliberately;
## both must stay `1` (the pre-envelope format's implicit version).
const LEGACY_VERSION := 1

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
	]

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
