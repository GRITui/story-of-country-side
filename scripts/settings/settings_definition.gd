extends RefCounted
class_name SettingsDefinition
## Default settings values (Settings backend, blocked #52 gap).
## Pure data holder — no I/O, fully headless-testable.

const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_SFX_VOLUME := 0.9
const DEFAULT_FULLSCREEN := false
const DEFAULT_KEY_REBINDS := {}

## Valid volume range
static func clamp_volume(v: float) -> float:
	return clampf(v, 0.0, 1.0)

## Returns a fresh defaults dictionary (deep copy so callers can mutate).
static func default_settings() -> Dictionary:
	return {
		"master_volume": DEFAULT_MASTER_VOLUME,
		"music_volume": DEFAULT_MUSIC_VOLUME,
		"sfx_volume": DEFAULT_SFX_VOLUME,
		"fullscreen": DEFAULT_FULLSCREEN,
		"key_rebinds": DEFAULT_KEY_REBINDS.duplicate(true),
	}
