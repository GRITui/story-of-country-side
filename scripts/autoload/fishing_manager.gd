extends Node
## Autoload: FishingManager
##
## Fishing (#15): seasonal/time/location fish pools + a minimal catch
## resolution contract. Depends on the Time & Stamina foundation (already
## merged) and consumes InventoryManager + SkillManager("Fishing") the
## same way FarmPlotManager/AnimalManager consume them for their own
## produce -- attempt_catch() never calls ShippingBinManager directly.
##
## Scope boundary: #15's own text calls the mini-game's "input/skill-check
## design TBD" -- building a concrete bar-timing/QTE minigame here would
## be inventing an undecided design, and the scene/input layer it needs is
## Frontend's territory per SQUAD-SPLIT.md, not this autoload's. What this
## ships instead is the decidable half of the issue: get_available_fish()
## answers "what can I catch here/now" (season + hour window + location),
## and attempt_catch(fish_id, performance) is the pass/fail contract a
## future mini-game scene calls into with whatever [0.0, 1.0] score it
## computes from player input -- FishingManager doesn't care how that
## score was produced.
##
## No to_save_dict()/from_save_dict() -- unlike FarmPlotManager's planted
## tiles or AnimalManager's owned animals, FishingManager holds no
## persistent per-player state of its own beyond registered content
## (every cast is a fresh, stateless attempt), so there's nothing to
## round-trip through a save file.
##
## Content pass (#53): expanded from 4 to 11 fish spanning all 4 locations
## (pond/river/lake/ocean) and all 4 seasons, including night-window
## catches (18:00-23:00) the original roster never used. carp/trout/
## salmon/tuna kept at their original ids/values -- CommunityGoalManager's
## fish_tank_bundle references carp/trout/salmon by id and quantity, and
## existing tests assert trout's exact sell price, so those four are
## additive-only; the sanity-check below is against the new fish only.
##
## Price scales with difficulty on roughly the same curve the original 4
## fish already established (price/difficulty ratio climbing from ~75 at
## difficulty 0.2 to ~125 at difficulty 0.8, i.e. harder fish are worth
## disproportionately more, not just linearly more) -- new fish extend
## that same curve rather than resetting it. sturgeon (difficulty 0.85,
## price 150) is the new top-end "legendary" catch, priced above tuna to
## keep the ceiling above the previous max.

signal fish_caught(fish_id: String, quality: String, quantity: int)
signal fish_escaped(fish_id: String)

const QUALITY_NORMAL := "normal"
const QUALITY_SILVER := "silver"
const QUALITY_GOLD := "gold"

## Global performance thresholds for quality, independent of a fish's own
## difficulty -- placeholder, not final balance.
const QUALITY_GOLD_PERFORMANCE := 0.9
const QUALITY_SILVER_PERFORMANCE := 0.6
const QUALITY_PRICE_MULTIPLIER := {
	QUALITY_NORMAL: 1.0,
	QUALITY_SILVER: 1.25,
	QUALITY_GOLD: 1.5,
}

var _definitions: Dictionary = {} # fish_id -> FishDefinition

func _ready() -> void:
	_register_default_content()

## Content pass (#53): original 4 (carp/trout/salmon/tuna) kept verbatim,
## 7 new fish added. New fish deliberately avoid the two location/season/
## hour combinations existing tests assert exact pools for (river+Spring+
## hour 8, ocean+Summer+hour 10) so those additive fish don't require
## rewriting a passing exact-match assertion into a weaker "has()" one.
func _register_default_content() -> void:
	register_fish(_make_fish("carp", "Carp", ["Spring", "Summer", "Fall", "Winter"],
		["pond", "river", "lake"], 0, 23, 0.2, 15, 2))
	register_fish(_make_fish("trout", "Trout", ["Spring", "Fall"],
		["river"], 6, 11, 0.5, 40, 5))
	register_fish(_make_fish("salmon", "Salmon", ["Fall"],
		["river"], 6, 19, 0.6, 60, 6))
	register_fish(_make_fish("tuna", "Tuna", ["Summer", "Winter"],
		["ocean"], 6, 19, 0.8, 100, 10))
	# New content-pass additions
	register_fish(_make_fish("bream", "Bream", ["Spring", "Summer"],
		["pond", "lake"], 0, 23, 0.3, 18, 3))
	register_fish(_make_fish("bass", "Bass", ["Summer", "Fall"],
		["lake"], 6, 19, 0.45, 35, 4))
	register_fish(_make_fish("sardine", "Sardine", ["Spring", "Fall", "Winter"],
		["ocean"], 6, 19, 0.25, 20, 3))
	register_fish(_make_fish("squid", "Squid", ["Winter"],
		["ocean"], 18, 23, 0.55, 55, 6))
	register_fish(_make_fish("pike", "Pike", ["Winter"],
		["river", "lake"], 0, 23, 0.5, 45, 5))
	register_fish(_make_fish("eel", "Eel", ["Summer", "Fall"],
		["river"], 18, 23, 0.7, 70, 7))
	register_fish(_make_fish("sturgeon", "Sturgeon", ["Fall", "Winter"],
		["lake"], 6, 11, 0.85, 150, 15))

func _make_fish(fish_id: String, display_name: String, seasons: Array[String],
	locations: Array[String], start_hour: int, end_hour: int, difficulty: float,
	base_sell_price: int, xp_reward: int) -> FishDefinition:
	var def := FishDefinition.new()
	def.fish_id = fish_id
	def.display_name = display_name
	def.valid_seasons = seasons
	def.valid_locations = locations
	def.start_hour = start_hour
	def.end_hour = end_hour
	def.difficulty = difficulty
	def.base_sell_price = base_sell_price
	def.xp_reward = xp_reward
	return def

## Re-registering the same fish_id is a content overwrite (last write
## wins), same convention as every other *_manager's register_*.
func register_fish(def: FishDefinition) -> void:
	if def == null or def.fish_id.is_empty():
		return
	_definitions[def.fish_id] = def

func get_fish_definition(fish_id: String) -> FishDefinition:
	return _definitions.get(fish_id)

## Returns the fish_ids catchable at this location/season/hour, sorted
## alphabetically for a deterministic, testable order (registration order
## isn't guaranteed by Dictionary.keys()).
func get_available_fish(location: String, season: String, hour: int) -> Array[String]:
	var available: Array[String] = []
	for fish_id: String in _definitions.keys():
		var def: FishDefinition = _definitions[fish_id]
		if not def.valid_locations.has(location):
			continue
		if not def.valid_seasons.has(season):
			continue
		if hour < def.start_hour or hour > def.end_hour:
			continue
		available.append(fish_id)
	available.sort()
	return available

## Resolves one cast against a specific fish. performance is a [0.0, 1.0]
## score supplied by the caller's mini-game -- not clamped here, an
## out-of-range value is the caller's bug to fix, not something to hide.
## Returns {} only when fish_id isn't registered; a failed catch (fish
## escapes) is a valid, non-empty {"success": false, ...} result, not an
## empty dict, so callers can tell "no such fish" from "it got away."
func attempt_catch(fish_id: String, performance: float) -> Dictionary:
	var def: FishDefinition = _definitions.get(fish_id)
	if def == null:
		return {}

	if performance < def.difficulty:
		fish_escaped.emit(fish_id)
		return {"success": false, "fish_id": fish_id}

	var quality := _quality_for_performance(performance)
	var item_id := get_item_id(fish_id, quality)
	var quantity := 1

	InventoryManager.add_item(item_id, quantity)
	SkillManager.add_xp("Fishing", def.xp_reward)

	fish_caught.emit(fish_id, quality, quantity)
	return {"success": true, "fish_id": fish_id, "item_id": item_id, "quality": quality, "quantity": quantity}

## Quality tiers are encoded into the inventory item_id itself (e.g.
## "trout" vs. "trout_gold"), same convention as FarmPlotManager/
## AnimalManager's get_item_id.
func get_item_id(fish_id: String, quality: String) -> String:
	if quality == QUALITY_NORMAL or quality.is_empty():
		return fish_id
	return "%s_%s" % [fish_id, quality]

func get_sell_price(fish_id: String, quality: String) -> int:
	var def: FishDefinition = _definitions.get(fish_id)
	if def == null:
		return 0
	var mult: float = QUALITY_PRICE_MULTIPLIER.get(quality, 1.0)
	return int(round(def.base_sell_price * mult))

func _quality_for_performance(performance: float) -> String:
	if performance >= QUALITY_GOLD_PERFORMANCE:
		return QUALITY_GOLD
	if performance >= QUALITY_SILVER_PERFORMANCE:
		return QUALITY_SILVER
	return QUALITY_NORMAL
