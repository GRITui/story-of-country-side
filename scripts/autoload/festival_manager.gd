extends Node
## Autoload: FestivalManager — S-Tier P2 (Epsilon)
##
## Calendar per #115: exactly one festival per season (4 total), each with
## additive flavor_text. A second Winter entry point is left commented for
## Gamma/Content to activate if fiction wants it. Manager ownership stays
## with Epsilon; final prose ownership stays with Gamma — this file's
## flavor defaults are additive and safe for re-register overwrites.

signal festival_started(festival_id: String)
signal festival_ended(festival_id: String)
signal mini_game_result_submitted(festival_id: String, score: float, success: bool)

const MINI_GAME_PASS_THRESHOLD := 0.5
const FREEZE_REASON := "festival"

var _definitions: Dictionary = {} # festival_id -> FestivalDefinition
var _active_festival_id: String = ""

func _ready() -> void:
	_register_default_content()
	TimeManager.day_started.connect(_on_day_started)

func _register_default_content() -> void:
	register_festival(_make_festival(
		"bloomtide_fair", "Bloomtide Fair", "Spring", 13,
		"The valley bursts into color. Bring a spring crop to share and dance under the blossoms."
	))
	register_festival(_make_festival(
		"sunfield_revel", "Sunfield Revel", "Summer", 15,
		"Long sun, cold drinks, and a field of games. Prove your summer stamina."
	))
	register_festival(_make_festival(
		"harvest_moon_festival", "Harvest Moon Festival", "Fall", 16,
		"Tables groan with the year's work. Taste, judge, and give thanks."
	))
	register_festival(_make_festival(
		"hearthlight_festival", "Hearthlight Festival", "Winter", 21,
		"Snow quiets the valley. Gather at the hearth — stories, gifts, and a little midwinter magic."
	))

	# Optional second Winter festival entry point (commented).
	# Uncomment and adjust to add a late-winter capstone if narrative
	# wants two Winter beats (e.g. New Year's / Starlight analogue).
	# register_festival(_make_festival(
	# 	"starlight_veiling", "Starlight Veiling", "Winter", 28,
	# 	"The longest night. Lanterns on the snow, wishes on the wind."
	# ))

func _make_festival(festival_id: String, display_name: String, season: String, day_of_season: int, flavor_text: String = "") -> FestivalDefinition:
	var def := FestivalDefinition.new()
	def.festival_id = festival_id
	def.display_name = display_name
	def.season = season
	def.day_of_season = day_of_season
	def.flavor_text = flavor_text
	return def

func register_festival(def: FestivalDefinition) -> void:
	if def == null or def.festival_id.is_empty():
		return
	_definitions[def.festival_id] = def

func get_festival_definition(festival_id: String) -> FestivalDefinition:
	return _definitions.get(festival_id)

## Returns the festival matching season/day, or null.
func get_festival_for_date(season: String, day_of_season: int) -> FestivalDefinition:
	var ids := _definitions.keys()
	ids.sort()
	for festival_id: String in ids:
		var def: FestivalDefinition = _definitions[festival_id]
		if def.season == season and def.day_of_season == day_of_season:
			return def
	return null

func is_festival_day() -> bool:
	return get_festival_for_date(TimeManager.current_season(), TimeManager.day_in_season) != null

func get_active_festival() -> FestivalDefinition:
	if _active_festival_id.is_empty():
		return null
	return _definitions.get(_active_festival_id)

func is_festival_active() -> bool:
	return not _active_festival_id.is_empty()

## All registered festival ids sorted — useful for palette/calendar UIs.
func list_festival_ids() -> Array:
	var ids := _definitions.keys()
	ids.sort()
	return ids

## Returns a Dictionary season -> festival_id, enforcing the #115 invariant
## (exactly 1 festival per season). Useful as a calendar assertion.
func list_festivals_by_season() -> Dictionary:
	var by_season: Dictionary = {}
	for fid in _definitions.keys():
		var def: FestivalDefinition = _definitions[fid]
		if not by_season.has(def.season):
			by_season[def.season] = []
		by_season[def.season].append(fid)
	return by_season

func start_festival(festival_id: String) -> bool:
	if not _definitions.has(festival_id):
		return false
	if is_festival_active() and _active_festival_id != festival_id:
		return false
	if _active_festival_id == festival_id:
		return true
	_active_festival_id = festival_id
	TimeManager.freeze(FREEZE_REASON)
	festival_started.emit(festival_id)
	return true

func end_festival() -> void:
	if _active_festival_id.is_empty():
		return
	var festival_id := _active_festival_id
	_active_festival_id = ""
	TimeManager.unfreeze(FREEZE_REASON)
	festival_ended.emit(festival_id)

func submit_mini_game_result(festival_id: String, score: float) -> Dictionary:
	if not _definitions.has(festival_id):
		return {}
	var success := score >= MINI_GAME_PASS_THRESHOLD
	mini_game_result_submitted.emit(festival_id, score, success)
	return {"success": success, "festival_id": festival_id, "score": score}

func _on_day_started(day_in_season: int, season: String, _day_of_week: String) -> void:
	var def := get_festival_for_date(season, day_in_season)
	if def != null:
		start_festival(def.festival_id)
