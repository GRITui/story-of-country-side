extends Node
## Autoload: FestivalManager
##
## Festivals (#21): 3-4 seasonal events, each pinned to a fixed
## season/day_of_season, that freeze normal time-of-day progression for
## their duration by reusing TimeManager's existing freeze("festival")/
## unfreeze("festival") mechanism -- the same reference-counted mechanism
## the pause menu (see squad-handshake-engineer.md) and ENG-26's intro
## sequence (scripts/story/intro_sequence.gd, FREEZE_REASON pattern) each
## use with their own reason string, so a festival freeze can overlap a
## menu freeze without either unfreezing the other early.
##
## Scope boundary, same reasoning ENG-15 (Fishing) used for its own
## undecided mini-game: #21's issue text calls each festival's mini-game
## "unique" but never specifies *what* it is -- no input/skill-check
## design exists anywhere in the design doc, and building one concrete
## implementation would both invent an undecided design and cross into
## Frontend/UI territory (scenes/input handling) per SQUAD-SPLIT.md. What
## ships here is the decidable half: is_festival_day()/get_active_festival()
## answer "is there a festival, and which one", start_festival()/
## end_festival() drive the freeze and lifecycle signals, and
## submit_mini_game_result(festival_id, score) is the pass/fail contract a
## future mini-game scene calls into -- mirroring FishingManager.
## attempt_catch's performance:float contract exactly. FestivalManager
## doesn't care how that score was produced, same as FishingManager
## doesn't care how a cast's performance score was computed.
##
## Auto-trigger integration point: _on_day_started() below fires
## start_festival() unconditionally the instant a registered festival's
## day/season arrives -- there's no "player location" concept anywhere in
## this repo yet (FishDefinition's valid_locations is the closest thing,
## and even that is just a free-form string with no map/zone system behind
## it), so "only start the festival once the player reaches the festival
## grounds" is a real future integration point, not something to fake here.
##
## No to_save_dict()/from_save_dict() -- same discipline ENG-15 documented
## for FishingManager. Every festival is purely date-driven: which
## festival is active on a given day is fully re-derivable from
## TimeManager's restored season/day_in_season, and _active_festival_id
## itself is transient session state, not save-worthy data. That
## re-derivation is NOT free at boot though -- #90: activation only fired
## on TimeManager.day_started's 2AM edge, so a quit+relaunch mid-festival
## never re-derived it. rederive_active_festival() below is the fix;
## SaveManager.apply_save_data()/new_game() call it after restoring the
## clock so the same date-derivation _on_day_started uses runs on every
## save-load path too. Wiring a
## hollow to_save_dict()/from_save_dict() pair that just round-trips
## _active_festival_id would be fabricating structure for state that's
## already reconstructed for free -- see SaveManager's own docstring for
## the same "don't add save wiring nothing needs" call on FishingManager.

signal festival_started(festival_id: String)
signal festival_ended(festival_id: String)
signal mini_game_result_submitted(festival_id: String, score: float, success: bool)

## Global pass/fail threshold for submit_mini_game_result, independent of
## any per-festival difficulty (no per-festival difficulty field exists
## yet -- placeholder single threshold, not final balance, same honesty
## as FishingManager's QUALITY_* thresholds).
const MINI_GAME_PASS_THRESHOLD := 0.5

const FREEZE_REASON := "festival"

var _definitions: Dictionary = {} # festival_id -> FestivalDefinition
var _active_festival_id: String = ""

func _ready() -> void:
	_register_default_content()
	TimeManager.day_started.connect(_on_day_started)

## One festival per season, spread through the season's day range. Named
## and dated by Content squad per SQUAD-SPLIT.md's Content lane -- no
## concrete festival list existed anywhere in the design doc, so these are
## this repo's real festival calendar, not a stand-in for one written
## elsewhere. festival_id strings stay internal identifiers (snake_case,
## stable independent of the display name players actually see).
func _register_default_content() -> void:
	register_festival(_make_festival("bloomtide_fair", "Bloomtide Fair", "Spring", 13,
		"Spring's first blush — petals on every doorstep, ribbons in the wind, and Elena's flower crowns for every child. Dance barefoot through the meadow at noon."))
	register_festival(_make_festival("sunfield_revel", "Sunfield Revel", "Summer", 15,
		"Summer at its golden peak — sunhats, iced tea, and Marcus's dockside fish fry. Stay for the sunset lantern release over the fields."))
	register_festival(_make_festival("harvest_moon_festival", "Harvest Moon Festival", "Fall", 16,
		"Autumn's bounty under a honeyed moon — Priya's harvest table groans with corn and pumpkin, and every scarecrow wears a smile."))
	register_festival(_make_festival("hearthlight_festival", "Hearthlight Festival", "Winter", 21,
		"Winter's cozy heart — hearth fires, wool blankets, and Tobias's spiced cider. The whole valley gathers to trade stories until the snow glows."))

func _make_festival(festival_id: String, display_name: String, season: String, day_of_season: int, flavor_text: String = "") -> FestivalDefinition:
	var def := FestivalDefinition.new()
	def.festival_id = festival_id
	def.display_name = display_name
	def.season = season
	def.day_of_season = day_of_season
	def.flavor_text = flavor_text
	return def

## Re-registering the same festival_id is a content overwrite (last write
## wins), same convention as every other *_manager's register_*.
func register_festival(def: FestivalDefinition) -> void:
	if def == null or def.festival_id.is_empty():
		return
	_definitions[def.festival_id] = def

func get_festival_definition(festival_id: String) -> FestivalDefinition:
	return _definitions.get(festival_id)

## Returns the registered festival whose season/day_of_season matches
## TimeManager's current date, or null if today isn't a festival day.
## Sorted by festival_id for a deterministic pick in the (should-never-
## happen) case two festivals share the same date.
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

## Starts a festival: freezes TimeManager (reference-counted, "festival"
## reason) and emits festival_started. No-ops (returns false) for an
## unregistered festival_id or while a different festival is already
## active -- ending the current one first is the caller's job, same
## "explicit over implicit" pattern as FarmPlotManager's plant() rejecting
## an already-occupied tile.
func start_festival(festival_id: String) -> bool:
	if not _definitions.has(festival_id):
		return false
	if is_festival_active() and _active_festival_id != festival_id:
		return false
	if _active_festival_id == festival_id:
		return true # already active, idempotent
	_active_festival_id = festival_id
	TimeManager.freeze(FREEZE_REASON)
	festival_started.emit(festival_id)
	return true

## Ends the active festival (no-op if none is active): unfreezes
## TimeManager and emits festival_ended.
func end_festival() -> void:
	if _active_festival_id.is_empty():
		return
	var festival_id := _active_festival_id
	_active_festival_id = ""
	TimeManager.unfreeze(FREEZE_REASON)
	festival_ended.emit(festival_id)

## Generic pass/fail contract a future mini-game scene calls into with
## whatever [0.0, 1.0] score it computes from player input -- mirrors
## FishingManager.attempt_catch's performance:float contract exactly.
## score is not clamped here (an out-of-range value is the caller's bug,
## not something to hide, same as attempt_catch). Returns {} only when
## festival_id isn't registered; a failed attempt is a valid, non-empty
## {"success": false, ...} result, not an empty dict.
func submit_mini_game_result(festival_id: String, score: float) -> Dictionary:
	if not _definitions.has(festival_id):
		return {}
	var success := score >= MINI_GAME_PASS_THRESHOLD
	mini_game_result_submitted.emit(festival_id, score, success)
	return {"success": success, "festival_id": festival_id, "score": score}

## Auto-trigger integration point: fires start_festival() unconditionally
## the instant a registered festival's day/season arrives. See this
## file's top-of-file docstring for why this is unconditional (no player
## location concept exists yet) rather than location-gated.
func _on_day_started(day_in_season: int, season: String, _day_of_week: String) -> void:
	var def := get_festival_for_date(season, day_in_season)
	if def != null:
		start_festival(def.festival_id)

## Re-runs the exact date-derivation _on_day_started uses against
## TimeManager's CURRENT date, without waiting for the next 2AM
## day_started edge (#90): SaveManager calls this after restoring the
## clock from a save, so a quit+relaunch mid-festival reloads with the
## festival still active. Also expires a stale active festival (one whose
## day has passed) via end_festival() rather than silently clearing it --
## leaving the "festival" freeze reason behind would keep the clock frozen
## forever. Returns whether a festival is active afterwards.
func rederive_active_festival() -> bool:
	var def := get_festival_for_date(TimeManager.current_season(), TimeManager.day_in_season)
	if def != null and _active_festival_id == def.festival_id:
		return true # already active, idempotent
	if is_festival_active():
		end_festival()
	if def == null:
		return false # not a festival day and nothing stale to expire
	return start_festival(def.festival_id)
