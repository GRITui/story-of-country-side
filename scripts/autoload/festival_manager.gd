extends Node
## Autoload: FestivalManager
## Updated to implement #115: Complete the festival calendar (Winter festival).

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
	# Milestone 3.0 Polish — JP seasonal quartet + legacy keeps
	register_festival(_make_festival("hanami_picnic", "Hanami — Cherry Blossom Picnic", "Spring", 15, "Gather under sakura — villagers share bentos, Elder Taro recites haiku."))
	register_festival(_make_festival("hanabi_taikai", "Hanabi Taikai — Summer Fireworks", "Summer", 20, "Evening fireworks over the river — lantern palette, yukata dialogue."))
	register_festival(_make_festival("harvest_contest", "Harvest Moon Cooking & Crop Contest", "Fall", 10, "Submit one crop — judges score quality tiers (normal/silver/gold)."))
	register_festival(_make_festival("winter_starlight", "Winter Starlight Gathering", "Winter", 24, "Lantern ambiance — warm indigo night, hot tea, village lights."))
	# Legacy hearth/starlight kept for save compat
	register_festival(_make_festival("bloomtide_fair", "Bloomtide Fair", "Spring", 13, "Spring blossoms!"))
	register_festival(_make_festival("sunfield_revel", "Sunfield Revel", "Summer", 15, "Summer sun!"))
	register_festival(_make_festival("harvest_moon_festival", "Harvest Moon Festival", "Fall", 16, "Fall harvest!"))
	register_festival(_make_festival("hearthlight_festival", "Hearthlight Festival", "Winter", 21, "Winter warmth!"))
	register_festival(_make_festival("starlight_veiling", "Starlight Veiling", "Winter", 28, "The longest night of the year."))

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

func start_festival(festival_id: String) -> void:
	_active_festival_id = festival_id
	TimeManager.freeze("festival")
	festival_started.emit(festival_id)

func end_festival() -> void:
	var id = _active_festival_id
	_active_festival_id = ""
	TimeManager.unfreeze("festival")
	festival_ended.emit(id)

func _on_day_started(_day: int, season: String, _dow: String) -> void:
	for id in _festivals:
		var def = _festivals[id]
		if def.season == season and def.day_of_season == TimeManager.day_in_season:
			start_festival(id)
			break
