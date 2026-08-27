class_name NPCRoster
## Frontend (#102): placeholder daily-routine content for the six villagers
## RelationshipManager/MarriageManager already track by name
## (RelationshipManager.GIFT_PREFERENCE_PATHS / MarriageManager.
## MARRIAGEABLE_NPCS) but that had no NPCSchedule data -- and no scene
## presence at all -- anywhere in the repo before this. NPCSchedule /
## NPCScheduleEntry (backend-owned data-model classes, scripts/npc/
## npc_schedule*.gd) support arbitrary hour/season/weather-gated entries;
## nothing had ever populated one for any of the six.
##
## This is Frontend's own placeholder content, not a designed schedule, per
## SQUAD-SPLIT.md's content-gap norm (documented as such rather than
## blocking on Content/Writer lane authoring real per-NPC routines): three
## fixed times of day per villager (morning/midday/evening), "Any"/"Any"
## season/weather on every entry -- no per-season variation authored yet.
##
## Each villager gets one "home" world scene, loosely matching the
## archetype relationship_manager.gd's own heart-event dialogue already
## establishes (Colton=miner/blacksmith, Elena=gardener, Priya=farmer,
## Sana=rancher, Marcus=angler, Tobias=treasure hunter). There is no
## dock/fishing world scene yet (FishingManager, #15, is overlay-only per
## #102's own issue text), so Marcus's placeholder home is ForageScene, the
## closest "outdoors" world scene that exists today.
##
## Positions are authored here as grid cells, not pixels -- each world
## scene converts them via its own TileMap.map_to_local() in build_schedule()
## below, so this roster stays agnostic to any particular scene's grid size
## (FarmScene/ForageScene's 8x8, RanchScene's 5x4, MineScene's
## MiningManager.get_floor_size() 5x5).

## npc_name -> home world scene name. Values match each world scene's own
## HOME_SCENE_NAME constant and become NPCScheduleEntry.location_name.
const NPC_HOME_SCENE := {
	"Elena": "Farm",
	"Priya": "Farm",
	"Sana": "Ranch",
	"Colton": "Mine",
	"Tobias": "Mine",
	"Marcus": "Forage",
}

## npc_name -> ordered list of {hour, minute, grid_pos} placeholder stops
## within that NPC's home scene grid. Three stops per NPC is enough to make
## the schedule's time-of-day movement actually observable in play (#102's
## own framing: "you can never walk somewhere and see Colton at the mine at
## 14:00") without pretending this is authored content.
const NPC_DAILY_STOPS := {
	"Elena": [
		{"hour": 6, "minute": 0, "grid_pos": Vector2i(1, 1)},
		{"hour": 12, "minute": 0, "grid_pos": Vector2i(4, 3)},
		{"hour": 20, "minute": 0, "grid_pos": Vector2i(1, 6)},
	],
	"Priya": [
		{"hour": 7, "minute": 0, "grid_pos": Vector2i(6, 1)},
		{"hour": 13, "minute": 0, "grid_pos": Vector2i(3, 5)},
		{"hour": 21, "minute": 0, "grid_pos": Vector2i(6, 6)},
	],
	"Sana": [
		{"hour": 6, "minute": 30, "grid_pos": Vector2i(0, 0)},
		{"hour": 14, "minute": 0, "grid_pos": Vector2i(3, 2)},
		{"hour": 21, "minute": 0, "grid_pos": Vector2i(0, 3)},
	],
	"Colton": [
		{"hour": 8, "minute": 0, "grid_pos": Vector2i(0, 0)},
		{"hour": 14, "minute": 0, "grid_pos": Vector2i(2, 2)},
		{"hour": 22, "minute": 0, "grid_pos": Vector2i(4, 0)},
	],
	"Tobias": [
		{"hour": 9, "minute": 0, "grid_pos": Vector2i(4, 4)},
		{"hour": 15, "minute": 0, "grid_pos": Vector2i(1, 3)},
		{"hour": 23, "minute": 0, "grid_pos": Vector2i(0, 4)},
	],
	"Marcus": [
		{"hour": 7, "minute": 0, "grid_pos": Vector2i(0, 4)},
		{"hour": 12, "minute": 30, "grid_pos": Vector2i(4, 0)},
		{"hour": 19, "minute": 0, "grid_pos": Vector2i(7, 7)},
	],
}

## Villager names whose home scene is `scene_name` -- a world scene iterates
## this to know which NPCControllers it should instantiate.
static func npcs_for_scene(scene_name: String) -> Array[String]:
	var result: Array[String] = []
	for npc_name in NPC_HOME_SCENE:
		if NPC_HOME_SCENE[npc_name] == scene_name:
			result.append(npc_name)
	return result

## Builds a real NPCSchedule for npc_name, converting each placeholder grid
## stop into `tilemap`'s own local pixel space via map_to_local() -- the
## same transform every world scene already uses for its own player avatar/
## tile-click placement, so an NPC lines up on the isometric grid exactly
## like everything else in that scene.
static func build_schedule(npc_name: String, tilemap: TileMap) -> NPCSchedule:
	var schedule := NPCSchedule.new()
	var stops: Array = NPC_DAILY_STOPS.get(npc_name, [])
	var location_name: String = NPC_HOME_SCENE.get(npc_name, "")
	for stop in stops:
		var entry := NPCScheduleEntry.new()
		entry.hour = stop["hour"]
		entry.minute = stop["minute"]
		entry.position = tilemap.map_to_local(stop["grid_pos"])
		entry.location_name = location_name
		schedule.entries.append(entry)
	return schedule
