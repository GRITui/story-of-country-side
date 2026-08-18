extends Node
## Autoload: InfrastructureManager
##
## Infrastructure Upgrades (ENG-24): house expansion, coop/barn capacity,
## and artisan processing machines -- the quest-gated automation tier
## Decision C (#4) described and ToolManager (#23) deliberately left
## ungated (see tool_manager.gd's docstring). Every unlock here checks
## BOTH QuestManager.is_unlocked(flag) AND a material+gold cost via
## InventoryManager/ShippingBinManager.spend(), same two-gate pattern
## across all three tracks.
##
## Three independent tracks:
## - House: a linear tier ladder (InfrastructureTier). Unlocking a tier
##   only flips a flag/tier number -- this issue's scope is the unlock
##   system, not cooking mechanics themselves (a separate future issue).
##   is_cooking_unlocked() is the one integration point a future cooking
##   system should read.
## - Coop/barn: also a linear tier ladder, but its payload is a capacity
##   number. AnimalManager (#14, already shipped) has NO capacity concept
##   today -- get_max_animal_capacity() is exposed here as the read-only
##   integration point; wiring AnimalManager.add_animal() to actually
##   enforce it against this value is left to whoever next touches
##   animal_manager.gd (out of this issue's core scope per the Backend/
##   Frontend split -- animal_manager.gd is just-landed code this issue
##   does not own).
## - Artisan machines: one-shot builds (not tiered), each with a single
##   raw-ingredient-in/processed-good-out recipe (ArtisanMachineRecipe).
##   Starting a job consumes the input via InventoryManager immediately;
##   the job then counts down process_days on TimeManager.day_started
##   ticks (mirrors AnimalManager/FarmPlotManager's day-driven progress)
##   until ready, at which point collect_job() credits the output via
##   InventoryManager.add_item -- explicit collection, not auto-credit,
##   matching AnimalManager.collect_product's "player pulls the finished
##   good" convention rather than ForagingManager's auto-credit-on-gather
##   one.
##
## Content-gap honesty: no concrete tier list, costs, capacity numbers, or
## machine recipes exist anywhere in the design doc or issue thread. The
## defaults registered below (2 house tiers, 2 coop/barn tiers, 3 artisan
## machines with one recipe each) are placeholder MVP balance, explicitly
## flagged as such -- same honesty as every other content table in this
## repo (#19/#23/#25/#31).

signal house_upgraded(new_tier: int)
signal coop_upgraded(new_tier: int)
signal machine_built(machine_type: String)
signal artisan_job_started(job_id: String, machine_type: String)
signal artisan_job_ready(job_id: String, machine_type: String)
signal artisan_job_collected(job_id: String, machine_type: String, output_item_id: String, quantity: int)

const HOUSE_TIER_START := 0
const COOP_TIER_START := 0
## Placeholder MVP balance -- no ranching-capacity number exists anywhere
## else in the repo yet (AnimalManager has no capacity concept, see this
## file's top-of-file docstring).
const BASE_ANIMAL_CAPACITY := 4

var _house_tier: int = HOUSE_TIER_START
var _coop_tier: int = COOP_TIER_START
var _house_tiers: Dictionary = {}   ## tier_index -> InfrastructureTier
var _coop_tiers: Dictionary = {}    ## tier_index -> InfrastructureTier
var _machines: Dictionary = {}      ## machine_type -> ArtisanMachineRecipe
var _built_machines: Dictionary = {} ## machine_type -> bool
var _jobs: Dictionary = {}          ## job_id -> {machine_type, days_remaining, ready, output_item_id, output_quantity}

func _ready() -> void:
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

## --- Content registration ---

## Re-registering the same tier_index is a content overwrite (last write
## wins), same convention as ToolManager.register_tier.
func register_house_tier(tier: InfrastructureTier) -> void:
	if tier == null:
		return
	_house_tiers[tier.tier_index] = tier

func register_coop_tier(tier: InfrastructureTier) -> void:
	if tier == null:
		return
	_coop_tiers[tier.tier_index] = tier

## Re-registering the same machine_type is a content overwrite, same
## convention as AnimalManager.register_species.
func register_machine(recipe: ArtisanMachineRecipe) -> void:
	if recipe == null or recipe.machine_type.is_empty():
		return
	_machines[recipe.machine_type] = recipe

## Placeholder MVP balance -- see this file's top-of-file docstring.
## Also registers one DELIVER_ITEM QuestDefinition per unlock_flag used
## below with QuestManager, so every gate here is actually reachable (an
## unlock_flag with no quest driving it would never flip).
func _register_default_content() -> void:
	register_house_tier(_make_tier(1, "house_tier_1_unlocked", 1000, "wood", 50, 1))
	register_house_tier(_make_tier(2, "house_tier_2_unlocked", 3000, "stone", 100, 1))

	register_coop_tier(_make_tier(1, "coop_tier_1_unlocked", 800, "wood", 40, 8))
	register_coop_tier(_make_tier(2, "coop_tier_2_unlocked", 2000, "wood", 80, 12))

	register_machine(_make_machine("keg", "keg_unlocked", 300, "wood", 20,
		"fruit", 1, "wine", 1, 3))
	register_machine(_make_machine("preserves_jar", "preserves_jar_unlocked", 250, "stone", 15,
		"vegetable", 1, "pickle", 1, 2))
	register_machine(_make_machine("mayo_machine", "mayo_machine_unlocked", 200, "wood", 10,
		"egg", 1, "mayonnaise", 1, 1))

	if QuestManager:
		QuestManager.register_quest(_make_deliver_quest("infra_house_tier_1", "wood", 10, "house_tier_1_unlocked"))
		QuestManager.register_quest(_make_deliver_quest("infra_house_tier_2", "stone", 20, "house_tier_2_unlocked"))
		QuestManager.register_quest(_make_deliver_quest("infra_coop_tier_1", "wood", 15, "coop_tier_1_unlocked"))
		QuestManager.register_quest(_make_deliver_quest("infra_coop_tier_2", "wood", 30, "coop_tier_2_unlocked"))
		QuestManager.register_quest(_make_deliver_quest("infra_keg", "wood", 5, "keg_unlocked"))
		QuestManager.register_quest(_make_deliver_quest("infra_preserves_jar", "stone", 5, "preserves_jar_unlocked"))
		QuestManager.register_quest(_make_deliver_quest("infra_mayo_machine", "wool", 3, "mayo_machine_unlocked"))

func _make_tier(tier_index: int, unlock_flag: String, gold_cost: int,
	material_item_id: String, material_quantity: int, payload_value: int) -> InfrastructureTier:
	var t := InfrastructureTier.new()
	t.tier_index = tier_index
	t.unlock_flag = unlock_flag
	t.gold_cost = gold_cost
	t.material_item_id = material_item_id
	t.material_quantity = material_quantity
	t.payload_value = payload_value
	return t

func _make_machine(machine_type: String, unlock_flag: String, gold_cost: int,
	material_item_id: String, material_quantity: int,
	input_item_id: String, input_quantity: int,
	output_item_id: String, output_quantity: int, process_days: int) -> ArtisanMachineRecipe:
	var r := ArtisanMachineRecipe.new()
	r.machine_type = machine_type
	r.unlock_flag = unlock_flag
	r.gold_cost = gold_cost
	r.material_item_id = material_item_id
	r.material_quantity = material_quantity
	r.input_item_id = input_item_id
	r.input_quantity = input_quantity
	r.output_item_id = output_item_id
	r.output_quantity = output_quantity
	r.process_days = process_days
	return r

func _make_deliver_quest(quest_id: String, item_id: String, target_quantity: int, unlock_flag: String) -> QuestDefinition:
	var cond := QuestCondition.new()
	cond.type = QuestCondition.ConditionType.DELIVER_ITEM
	cond.item_id = item_id
	cond.target_quantity = target_quantity
	var q := QuestDefinition.new()
	q.quest_id = quest_id
	q.condition = cond
	q.unlock_flag = unlock_flag
	return q

## --- House track ---

func get_house_tier() -> int:
	return _house_tier

## Cooking mechanics themselves are out of scope for #24 -- this is only
## the unlock flag a future cooking system should read.
func is_cooking_unlocked() -> bool:
	return _house_tier >= 1

func can_upgrade_house() -> bool:
	return _can_upgrade_track(_next_house_def())

func upgrade_house() -> bool:
	var def := _next_house_def()
	if not _can_upgrade_track(def):
		return false
	if not _pay_tier(def):
		return false
	_house_tier = def.tier_index
	house_upgraded.emit(_house_tier)
	return true

func _next_house_def() -> InfrastructureTier:
	return _house_tiers.get(_house_tier + 1)

## --- Coop/barn track ---

func get_coop_tier() -> int:
	return _coop_tier

## Read-only integration point for AnimalManager (see this file's
## top-of-file docstring) -- AnimalManager.add_animal() does not call
## this today; nothing in this repo enforces it yet.
func get_max_animal_capacity() -> int:
	var def: InfrastructureTier = _coop_tiers.get(_coop_tier)
	return def.payload_value if def else BASE_ANIMAL_CAPACITY

func can_upgrade_coop() -> bool:
	return _can_upgrade_track(_next_coop_def())

func upgrade_coop() -> bool:
	var def := _next_coop_def()
	if not _can_upgrade_track(def):
		return false
	if not _pay_tier(def):
		return false
	_coop_tier = def.tier_index
	coop_upgraded.emit(_coop_tier)
	return true

func _next_coop_def() -> InfrastructureTier:
	return _coop_tiers.get(_coop_tier + 1)

## Shared by both linear tracks: no further tier defined, or the quest
## unlock flag for it isn't unlocked yet, or material/gold isn't enough.
func _can_upgrade_track(def: InfrastructureTier) -> bool:
	if def == null:
		return false
	if QuestManager and not QuestManager.is_unlocked(def.unlock_flag):
		return false
	if not InventoryManager.has_item(def.material_item_id, def.material_quantity):
		return false
	return ShippingBinManager.gold >= def.gold_cost

## Material is checked (not spent) before gold is spent, so a failed gold
## spend never leaves material partially consumed -- same ordering
## ToolManager.upgrade_tool uses for ore vs. gold.
func _pay_tier(def: InfrastructureTier) -> bool:
	if not InventoryManager.has_item(def.material_item_id, def.material_quantity):
		return false
	if not ShippingBinManager.spend(def.gold_cost):
		return false
	InventoryManager.remove_item(def.material_item_id, def.material_quantity)
	return true

## --- Artisan machines ---

func is_machine_built(machine_type: String) -> bool:
	return _built_machines.get(machine_type, false)

func can_build_machine(machine_type: String) -> bool:
	if is_machine_built(machine_type):
		return false
	var recipe: ArtisanMachineRecipe = _machines.get(machine_type)
	if recipe == null:
		return false
	if QuestManager and not QuestManager.is_unlocked(recipe.unlock_flag):
		return false
	if not InventoryManager.has_item(recipe.material_item_id, recipe.material_quantity):
		return false
	return ShippingBinManager.gold >= recipe.gold_cost

func build_machine(machine_type: String) -> bool:
	if not can_build_machine(machine_type):
		return false
	var recipe: ArtisanMachineRecipe = _machines.get(machine_type)
	if not ShippingBinManager.spend(recipe.gold_cost):
		return false
	InventoryManager.remove_item(recipe.material_item_id, recipe.material_quantity)
	_built_machines[machine_type] = true
	machine_built.emit(machine_type)
	return true

## Consumes the recipe's input ingredient immediately and creates a new
## active job counted down on day rollover. Fails (no state change) if the
## machine isn't built, the job_id is already active, or there isn't
## enough input on hand -- same "check before mutate" pattern as
## InventoryManager.remove_item.
func start_job(job_id: String, machine_type: String) -> bool:
	if job_id.is_empty() or _jobs.has(job_id):
		return false
	if not is_machine_built(machine_type):
		return false
	var recipe: ArtisanMachineRecipe = _machines.get(machine_type)
	if recipe == null:
		return false
	if not InventoryManager.has_item(recipe.input_item_id, recipe.input_quantity):
		return false
	if not InventoryManager.remove_item(recipe.input_item_id, recipe.input_quantity):
		return false
	_jobs[job_id] = {
		"machine_type": machine_type,
		"days_remaining": recipe.process_days,
		"ready": false,
		"output_item_id": recipe.output_item_id,
		"output_quantity": recipe.output_quantity,
	}
	artisan_job_started.emit(job_id, machine_type)
	return true

func get_job(job_id: String) -> Dictionary:
	return _jobs.get(job_id, {})

func is_job_ready(job_id: String) -> bool:
	var job: Dictionary = _jobs.get(job_id, {})
	return job.get("ready", false)

func list_job_ids() -> Array:
	return _jobs.keys()

## Credits the output to InventoryManager and removes the job. Fails
## (returns {}, no inventory change) if the job doesn't exist or isn't
## ready yet -- explicit collection, not auto-credit, see this file's
## top-of-file docstring.
func collect_job(job_id: String) -> Dictionary:
	var job: Dictionary = _jobs.get(job_id, {})
	if job.is_empty() or not job.get("ready", false):
		return {}
	var machine_type: String = job["machine_type"]
	var output_item_id: String = job["output_item_id"]
	var output_quantity: int = job["output_quantity"]
	InventoryManager.add_item(output_item_id, output_quantity)
	_jobs.erase(job_id)
	artisan_job_collected.emit(job_id, machine_type, output_item_id, output_quantity)
	return {"machine_type": machine_type, "output_item_id": output_item_id, "output_quantity": output_quantity}

## Daily tick: every active (not-yet-ready) job counts down by one day,
## becoming ready once it hits zero -- mirrors AnimalManager's day-driven
## progress toward product_ready.
func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	for job_id in _jobs.keys():
		var job: Dictionary = _jobs[job_id]
		if job.get("ready", false):
			continue
		job["days_remaining"] = int(job.get("days_remaining", 0)) - 1
		if job["days_remaining"] <= 0:
			job["ready"] = true
			artisan_job_ready.emit(job_id, job["machine_type"])

## --- Save/load ---

func to_save_dict() -> Dictionary:
	return {
		"house_tier": _house_tier,
		"coop_tier": _coop_tier,
		"built_machines": _built_machines.duplicate(),
		"jobs": _jobs.duplicate(true),
	}

func from_save_dict(data: Dictionary) -> void:
	_house_tier = data.get("house_tier", HOUSE_TIER_START)
	_coop_tier = data.get("coop_tier", COOP_TIER_START)
	_built_machines = (data.get("built_machines", {}) as Dictionary).duplicate()
	_jobs = (data.get("jobs", {}) as Dictionary).duplicate(true)
