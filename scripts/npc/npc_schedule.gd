class_name NPCSchedule
extends Resource
## An NPC's full daily routine: an unordered bag of NPCScheduleEntry:
## get_target_for() does the sorting/filtering/wrap-around lookup so
## authors don't have to hand-order entries or think about day boundaries.

@export var entries: Array[NPCScheduleEntry] = []

## Returns the entry that should be active at the given time, or null if
## no entry matches (for_season/for_weather) at all. "Wrap-around" means:
## if the current time is earlier than every matching entry's time today,
## the NPC is still holding position from the last entry of the previous
## day (e.g. asleep since 22:00, still asleep at 03:00).
func get_target_for(hour: int, minute: int, for_season: String, for_weather: String = "Any") -> NPCScheduleEntry:
	var matching: Array[NPCScheduleEntry] = entries.filter(
		func(e: NPCScheduleEntry) -> bool: return e.matches(for_season, for_weather)
	)
	if matching.is_empty():
		return null

	matching.sort_custom(func(a: NPCScheduleEntry, b: NPCScheduleEntry) -> bool:
		return a.time_key() < b.time_key()
	)

	var current_key := hour * 60 + minute
	var chosen: NPCScheduleEntry = matching[matching.size() - 1] # default: wrap to last entry
	for entry in matching:
		if entry.time_key() <= current_key:
			chosen = entry
		else:
			break
	return chosen

## Backend-facing API (#102): schedule-debug overlay can introspect any NPC's
## schedule for development/debugging/testing. Implements F-S9-03 with B-S9-04.
##
## Returns the entire schedule for npc_name, including season/weather
## gating, for display purposes (e.g. debug overlays). QA tests can assert
## that a schedule has expected entries for specific locations/times.
func get_debug_schedule_for(npc_name: String) -> Array[NPCScheduleEntry]:
	var debug_entries: Array[NPCScheduleEntry] = []
	# Create copies of entries to avoid exposing internal state
	for entry in entries:
		var copy := NPCScheduleEntry.new()
		copy.hour = entry.hour
		copy.minute = entry.minute
		copy.position = entry.position
		copy.location_name = entry.location_name
		copy.season = entry.season
		copy.weather = entry.weather
		debug_entries.append(copy)
	return debug_entries

## Returns the current active entry for hour/minute/season/weather, or null
## if no entry matches. QA tests can verify NPCs move to expected targets
## at expected times without running the entire simulation.
func get_current_entry(npc_name: String, hour: int, minute: int, for_season: String, for_weather: String) -> NPCScheduleEntry:
	return get_target_for(hour, minute, for_season, for_weather)
