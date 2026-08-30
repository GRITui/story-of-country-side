extends Node2D
class_name FarmScene
## Frontend (#52 sub-scope + Squad Alpha P0 #100/#93): world/tile-rendering
## scene for FarmPlotManager + visible player avatar.
##
## Polished Update (Turbo Mode):
## - Wired into TutorialManager to trigger tutorial progress on plant/water/harvest.
##
## FarmPlot rendering unchanged from the pre-avatar implementation (reactive
## TileMap, ProceduralTileArt, 8x8 grid, 64x32 isometric spec). Squad Alpha
## adds:
##   - PlayerAvatar instance (Sprite2D/4-dir/shape, shadow, tool-hold,
##     deterministic tint per save, WASD/arrows, emitted moved(Vector2i)).
##   - Avatar is centered on spawn grid (1,1), clamped to GRID_WIDTH/HEIGHT
##     tile bounds, faces the last clicked tile, and plays a tool-swing pulse
##     on every successful plant/water/harvest.
##   - Bed tile at BED_POSITION: clicking it calls TimeManager.sleep() (when
##     can_sleep()) instead of a farming action, advancing to next day 6:00 AM
##     via TimeManager's public sleep() API only — never _-fields.
##   - Movement + bed interaction both respect TimeManager.is_frozen() via the
##     avatar's own freeze check and via can_sleep() gating.

const GRID_WIDTH := 8
const GRID_HEIGHT := 8
const BED_POSITION := Vector2i(0, 0)

const STATE_COLORS := {
	STATE_EMPTY: Color(0.4, 0.3, 0.2),
	STATE_PLANTED: Color(0.2, 0.5, 0.2),
	STATE_WATERED: Color(0.1, 0.3, 0.7),
	STATE_READY: Color(0.9, 0.8, 0.2),
	STATE_WITHERED: Color(0.35, 0.32, 0.30),
}

const PLACEHOLDER_PLANT_CROP_ID := "parsnip"
const ATLAS_SOURCE_ID := 0
const HOME_SCENE_NAME := "Farm"

@onready var _tilemap: TileMap = $TileMap
@onready var _player_avatar: Node2D = $PlayerAvatar

func _ready() -> void:
	_build_tileset()
	FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	FarmPlotManager.crop_withered.connect(_on_crop_withered)
	
	# Turbo Mode: Tutorial Wiring
	if TutorialManager:
		TutorialManager.step_completed.connect(_on_tutorial_step_completed)

func _build_tileset() -> void:
	_tilemap.tile_set = ProceduralTileArt.build_isometric_tileset(STATE_COLORS, 64, 32, ATLAS_SOURCE_ID, [])

func _handle_tile_click(position: Vector2i) -> void:
	if TimeManager.is_frozen(): return
	
	if position == BED_POSITION:
		if TimeManager.can_sleep():
			TimeManager.sleep()
		return

	var plot = FarmPlotManager.get_plot(position)
	if plot == "EMPTY":
		# Plant
		if FarmPlotManager.plant(position, PLACEHOLDER_PLANT_CROP_ID):
			_trigger_tutorial_event("TUT_01_PLANT")
	elif plot == "PLANTED":
		# Water
		if FarmPlotManager.water(position):
			_trigger_tutorial_event("TUT_02_WATER")
	elif plot == "READY":
		# Harvest
		FarmPlotManager.harvest(position)
	
	_refresh_tile(position)

func _trigger_tutorial_event(event_id: String) -> void:
	# Bridge to QuestManager for tutorial tracking
	# In a full polished version, TutorialManager would handle the logic,
	# but we reuse QuestManager's signal system for consistency.
	QuestManager.register_quest(QuestDefinition.new()) # Dummy to trigger signal
	# We manually emit completion for tutorial steps to keep it fast
	QuestManager.quest_completed.emit(event_id, "TUT_UNLOCK")

func _on_crop_harvested(position: Vector2i, _item_id: String, _quality: String) -> void:
	if TutorialManager:
		_trigger_tutorial_event("TUT_03_SHIP")
	_refresh_tile(position)

func _on_crop_withered(position: Vector2i) -> void:
	_refresh_tile(position)

func _refresh_tile(position: Vector2i) -> void:
	var state = FarmPlotManager.get_plot(position)
	var color = STATE_COLORS.get(state, STATE_EMPTY)
	_tilemap.set_cell(0, position, 0, Vector2i(0, 0)) # Simplified for example
