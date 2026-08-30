extends Node
## Autoload: FestivalManager — S-Tier P2 (Epsilon + Gamma)
##
## Festivals (#21): 3-4 seasonal events, each pinned to a fixed
## season/day_of_season, that freeze normal time-of-day progression.
##
## Calendar per #115: exactly one festival per season (4 total).
## Prose ownership stays with Gamma — these defaults are additive.
##
## Auto-trigger integration point: _on_day_started() fires
## start_festival() unconditionally when the date arrives.
##
## No to_save_dict()/from_save_dict() — festivals are date-driven.
## rederive_active_festival() is the fix for save-load mid-festival.

signal festival_started(festival_id: String)
signal festival_ended(festival_id: String)

class FestivalDefinition:
	var festival_id: String
	var display_name: String
	var season: String
	var day_of_season: int
	var flavor_text: String

var _festivals: Dictionary = {}
var _active_festival_id: String = ""

func _ready() -> void:
	_register_default_content()
	TimeManager.day_started.connect(_on_day_started)

func _register_default_content() -> void:
	register_festival(_make_festival("bloomtide_fair", "Bloomtide Fair", "Spring", 13,
		"The valley bursts into color. Bring a spring crop to share and dance under the blossoms."))
	register_festival(_make_festival("sunfield_revel", "Sunfield Revel", "Summer", 15,
		"Long sun, cold drinks, and a field of games. Prove your summer stamina."))
	register_festival(_make_festival("harvest_moon_festival", "Harvest Moon Festival", "Fall", 16,
		"Tables groan with the year's work. Taste, judge, and give thanks."))
	register_festival(_make_festival("hearthlight_festival", "Hearthlight Festival", "Winter", 21,
		"Snow quiets the valley. Gather at the hearth — stories, gifts, and a little midwinter magic."))

func _make_festival(festival_id: String, display_name: String, season: String, day_of_season: int, flavor_text: String = "") -> FestivalDefinition:
	var def := FestivalDefinition.new()
	def.festival_id = festival_id
	def.display_name = display_name
	def.season = season
	def.day_of_season = day_of_season
	def.flavor_text = flavor_text
	return def

func register_festival(def: FestivalDefinition) -> void:
	_festivals[def.festival_id] = def

func get_festival_definition(festival_id: String) -> FestivalDefinition:
	return _festivals.get(festival_id)

func is_festival_day() -> bool:
	return _active_festival_id != ""

func get_active_festival() -> String:
	return _active_festival_id

func start_festival(festival_id: String) -> void:
	if not _festivals.has(festival_id):
		return
	_active_festival_id = festival_id
	TimeManager.freeze("festival")
	festival_started.emit(festival_id)

func end_festival() -> void:
	if _active_festival_id == "":
		return
	var id = _active_festival_id
	_active_festival_id = ""
	TimeManager.unfreeze("festival")
	festival_ended.emit(id)

func submit_mini_game_result(festival_id: String, score: float) -> void:
	# Pass/fail contract for future mini-game scenes.
	if _active_festival_id != festival_id:
		return
	# Logic for rewards would go here.
	end_festival()

func rederive_active_festival() -> void:
	if not TimeManager: return
	var s = TimeManager.current_season()
	var d = TimeManager.day_in_season
	for id in _festivals:
		var def = _festivals[id]
		if def.season == s and def.day_of_season == d:
			start_festival(id)
			return

func _on_day_started(_day: int, season: String, _dow: String) -> void:
	# Trigger festivals based on date.
	for id in _festivals:
		var def = _festivals[id]
		if def.season == season and def.day_of_season == TimeManager.day_in_season:
			start_festival(id)
			break
