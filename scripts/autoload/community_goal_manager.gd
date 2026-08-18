extends Node
## Autoload: CommunityGoalManager
##
## The ultimate-goal structure (ENG-27), per Decision A's resolution
## (open-ended/SDV model with an optional Homestead Challenge toggle):
## a Community-Center-style bundle/collection goal, plus a year-3
## evaluation that's a non-terminal narrative beat by default and only
## becomes pass/fail when challenge_mode is on.
##
## Bundles deliberately pull from every activity system that exists
## (crops, animal products, fish, ore, forageables) rather than inventing
## new content -- the "collect from the whole game" shape genre precedent
## calls for, using real item_ids already registered elsewhere instead of
## fabricating new ones.

signal bundle_contribution_added(bundle_id: String, item_id: String, quantity: int)
signal bundle_completed(bundle_id: String)
signal year_three_evaluation(challenge_mode: bool, bundles_completed: int, bundles_total: int, passed: bool)
signal game_over(reason: String)

## Set at new-game creation (no title screen exists yet to call this from
## per ENG-26's own scope note -- future UI concern, same pattern as the
## save-slot list). Defaults to false: open-ended, no fail state.
var challenge_mode: bool = false

var _bundles: Dictionary = {}       ## bundle_id -> BundleDefinition
var _contributions: Dictionary = {} ## bundle_id -> Dictionary(item_id -> quantity contributed)
var _completed: Dictionary = {}     ## bundle_id -> bool
var _evaluation_fired: bool = false
var _is_game_over: bool = false

func _ready() -> void:
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

## MVP placeholder bundle set, not final content -- same honesty as every
## other content table in this repo. One bundle per activity system.
func _register_default_content() -> void:
	register_bundle(_make_bundle("pantry_bundle", "Pantry Bundle",
		{"parsnip": 3, "tomato": 2, "pumpkin": 1}))
	register_bundle(_make_bundle("coop_bundle", "Coop Bundle",
		{"egg": 3, "milk": 2, "wool": 2}))
	register_bundle(_make_bundle("fish_tank_bundle", "Fish Tank Bundle",
		{"carp": 2, "trout": 1, "salmon": 1}))
	register_bundle(_make_bundle("boiler_room_bundle", "Boiler Room Bundle",
		{"copper_ore": 5, "iron_ore": 3, "gold_ore": 1}))
	register_bundle(_make_bundle("forager_bundle", "Forager's Bundle",
		{"wild_berries": 3, "mushroom": 2, "snow_truffle": 1}))

func _make_bundle(bundle_id: String, title: String, required_items: Dictionary) -> BundleDefinition:
	var b := BundleDefinition.new()
	b.bundle_id = bundle_id
	b.title = title
	b.required_items = required_items
	return b

## Re-registering an already-known bundle_id is a content overwrite for
## its definition but never touches contribution/completion progress --
## same "content reloads every boot, progress shouldn't reset" pattern as
## QuestManager/ToolManager.
func register_bundle(bundle: BundleDefinition) -> void:
	if bundle == null or bundle.bundle_id.is_empty():
		return
	_bundles[bundle.bundle_id] = bundle
	if not _contributions.has(bundle.bundle_id):
		_contributions[bundle.bundle_id] = {}
	if not _completed.has(bundle.bundle_id):
		_completed[bundle.bundle_id] = false

func is_bundle_complete(bundle_id: String) -> bool:
	return _completed.get(bundle_id, false)

func contributed_count(bundle_id: String, item_id: String) -> int:
	var contribs: Dictionary = _contributions.get(bundle_id, {})
	return contribs.get(item_id, 0)

func bundles_completed_count() -> int:
	var count := 0
	for bundle_id in _completed.keys():
		if _completed[bundle_id]:
			count += 1
	return count

func bundles_total_count() -> int:
	return _bundles.size()

func all_bundles_completed() -> bool:
	return bundles_total_count() > 0 and bundles_completed_count() == bundles_total_count()

## Removes up to `quantity` of item_id from InventoryManager and credits
## it toward bundle_id, clamped to what the bundle still needs (never
## accepts more than required, never removes more from inventory than
## actually gets credited). Returns false on: unknown bundle, already-
## complete bundle, item_id not part of the bundle, or InventoryManager
## not having enough stock (which itself guarantees no partial removal).
func contribute_item(bundle_id: String, item_id: String, quantity: int) -> bool:
	if quantity <= 0 or not _bundles.has(bundle_id) or is_bundle_complete(bundle_id):
		return false
	var bundle: BundleDefinition = _bundles[bundle_id]
	if not bundle.required_items.has(item_id):
		return false

	var required: int = bundle.required_items[item_id]
	var already: int = contributed_count(bundle_id, item_id)
	var remaining := required - already
	if remaining <= 0:
		return false
	var actual_qty := mini(quantity, remaining)

	if not InventoryManager.remove_item(item_id, actual_qty):
		return false

	var contribs: Dictionary = _contributions[bundle_id]
	contribs[item_id] = already + actual_qty
	bundle_contribution_added.emit(bundle_id, item_id, actual_qty)

	if _is_bundle_now_complete(bundle):
		_completed[bundle_id] = true
		bundle_completed.emit(bundle_id)

	return true

func _is_bundle_now_complete(bundle: BundleDefinition) -> bool:
	for item_id in bundle.required_items.keys():
		var required: int = bundle.required_items[item_id]
		if contributed_count(bundle.bundle_id, item_id) < required:
			return false
	return true

func _on_day_started(day_in_season: int, season: String, _day_of_week: String) -> void:
	if _evaluation_fired:
		return
	if TimeManager.year == 3 and season == "Spring" and day_in_season == 1:
		_fire_year_three_evaluation()

func _fire_year_three_evaluation() -> void:
	_evaluation_fired = true
	var passed := true
	if challenge_mode:
		passed = all_bundles_completed()
		if not passed:
			_is_game_over = true

	year_three_evaluation.emit(challenge_mode, bundles_completed_count(), bundles_total_count(), passed)

	if _is_game_over:
		game_over.emit("Homestead Challenge: town evaluation failed at year 3 with %d/%d bundles complete"
			% [bundles_completed_count(), bundles_total_count()])

func is_game_over() -> bool:
	return _is_game_over

func to_save_dict() -> Dictionary:
	return {
		"challenge_mode": challenge_mode,
		"contributions": _contributions.duplicate(true),
		"completed": _completed.duplicate(),
		"evaluation_fired": _evaluation_fired,
		"is_game_over": _is_game_over,
	}

func from_save_dict(data: Dictionary) -> void:
	challenge_mode = data.get("challenge_mode", false)
	_contributions = (data.get("contributions", {}) as Dictionary).duplicate(true)
	_completed = (data.get("completed", {}) as Dictionary).duplicate()
	_evaluation_fired = data.get("evaluation_fired", false)
	_is_game_over = data.get("is_game_over", false)
