extends Node
## Autoload: ForagingManager
##
## Foraging (#17): seasonal wild goods gatherable across the map -- unlike
## Agriculture (#13), nothing here is planted by the player. Instead the
## map carries a fixed set of gather spots (keyed by the same Vector2i
## tile-grid convention FarmPlotManager uses, see
## design/art/isometric-grid-spec.md); each spot either currently holds a
## season-appropriate ForageableDefinition and is available to gather, or
## is empty/on cooldown after a recent gather.
##
## Gathered items go into InventoryManager (#17 consumes the same general
## ledger #13 introduced, per squad-handshake-engineer.md's sequencing
## note -- no separate foraging ledger) and Foraging XP goes into
## SkillManager.add_xp("Foraging", ...) -- Foraging is its own skill, not
## folded into Farming (unlike Ranching, see SkillManager's docstring).
##
## No concrete forageable list, prices, or respawn timing exists anywhere
## in the design doc -- _register_default_content()'s four items below are
## placeholder balance, same honesty as ENG-13/ENG-23/ENG-25:
##   - wild_berries: Spring+Summer, sell 8, xp 3, respawn 2 days
##   - wild_flower:  Spring only,    sell 6, xp 2, respawn 2 days
##   - mushroom:     Fall only,      sell 12, xp 4, respawn 3 days
##   - snow_truffle: Winter only,    sell 20, xp 6, respawn 4 days (rarer/pricier)
## Every season has at least one available item; Spring has two so a
## reroll has real variety to pick from. Not final game balance -- see
## this file's own PR description.

signal forage_gathered(position: Vector2i, item_id: String, quantity: int)
signal forage_node_rerolled(position: Vector2i, item_id: String) ## item_id empty means the node went dormant (no season-valid content)

var _definitions: Dictionary = {} # item_id -> ForageableDefinition
var _nodes: Dictionary = {}       # Vector2i -> ForageNode
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

func _register_default_content() -> void:
	register_forageable(_make_forageable("wild_berries", "Wild Berries", ["Spring", "Summer"], 8, 3, 2))
	register_forageable(_make_forageable("wild_flower", "Wild Flower", ["Spring"], 6, 2, 2))
	register_forageable(_make_forageable("mushroom", "Mushroom", ["Fall"], 12, 4, 3))
	register_forageable(_make_forageable("snow_truffle", "Snow Truffle", ["Winter"], 20, 6, 4))

func _make_forageable(item_id: String, display_name: String, seasons: Array[String],
	sell_price: int, xp: int, respawn_days: int) -> ForageableDefinition:
	var def := ForageableDefinition.new()
	def.item_id = item_id
	def.display_name = display_name
	def.valid_seasons = seasons
	def.base_sell_price = sell_price
	def.xp_reward = xp
	def.respawn_days = respawn_days
	return def

## Re-registering the same item_id is a content overwrite (last write
## wins), same convention as FarmPlotManager.register_crop /
## ToolManager.register_tier.
func register_forageable(def: ForageableDefinition) -> void:
	if def == null or def.item_id.is_empty():
		return
	_definitions[def.item_id] = def

func get_forageable_definition(item_id: String) -> ForageableDefinition:
	return _definitions.get(item_id)

## Adds a gather spot to the map at `position` (a no-op if one already
## exists there) and immediately tries to seed it with a season-valid
## item, same as a fresh map placement would look on first load. Frontend
## (or a future map-population step) calls this once per spot; it is not
## implied by mere lookups the way FarmPlotManager's plots are implicitly
## created by plant().
func register_node(position: Vector2i) -> void:
	if _nodes.has(position):
		return
	var node := ForageNode.new()
	_nodes[position] = node
	_reroll_node(node, TimeManager.current_season())

func get_forage_node(position: Vector2i) -> ForageNode:
	return _nodes.get(position)

func is_available(position: Vector2i) -> bool:
	var node: ForageNode = _nodes.get(position)
	return node != null and node.is_available()

## Gathers an available node: credits InventoryManager and Foraging XP,
## then puts the node on cooldown for its item's respawn_days. Returns {}
## on any failure (no node, empty, still on cooldown, unknown item) so
## callers can check for an empty Dictionary instead of a sentinel value
## -- mirrors FarmPlotManager.harvest's contract.
func gather(position: Vector2i) -> Dictionary:
	var node: ForageNode = _nodes.get(position)
	if node == null or not node.is_available():
		return {}
	var def: ForageableDefinition = _definitions.get(node.item_id)
	if def == null:
		return {}

	var item_id := node.item_id
	var quantity := 1

	InventoryManager.add_item(item_id, quantity)
	SkillManager.add_xp("Foraging", def.xp_reward)

	node.cooldown_days_remaining = def.respawn_days

	forage_gathered.emit(position, item_id, quantity)
	return {"item_id": item_id, "quantity": quantity, "xp_reward": def.xp_reward}

## Picks a ForageableDefinition valid for `season` and assigns it to
## `node`, resetting its cooldown to 0 (immediately available). If nothing
## is valid for that season, the node goes dormant (empty item_id) rather
## than holding stale out-of-season content.
##
## Takes `season` explicitly rather than reading TimeManager.current_season()
## itself -- _on_day_started already receives the authoritative season for
## the day that just started as an argument (same reasoning as
## FarmPlotManager._on_day_started's wither check), and using that instead
## keeps this method callable/testable independent of TimeManager's own
## internal state.
func _reroll_node(node: ForageNode, season: String) -> void:
	var candidates: Array[ForageableDefinition] = []
	for def in _definitions.values():
		if (def as ForageableDefinition).valid_seasons.has(season):
			candidates.append(def)

	if candidates.is_empty():
		node.item_id = ""
		node.cooldown_days_remaining = 0
	else:
		var chosen: ForageableDefinition = candidates[_rng.randi() % candidates.size()]
		node.item_id = chosen.item_id
		node.cooldown_days_remaining = 0

## Day-tick hook (#17): nodes on cooldown count down and reroll once the
## cooldown expires; a node that's already available but whose current
## item's season just ended clears/rerolls too rather than sitting stale
## with out-of-season content -- mirrors FarmPlotManager's wither-on-
## season-end handling for planted crops.
func _on_day_started(_day_in_season: int, season: String, _day_of_week: String) -> void:
	for position in _nodes.keys():
		var node: ForageNode = _nodes[position]
		if node.cooldown_days_remaining > 0:
			node.cooldown_days_remaining -= 1
			if node.cooldown_days_remaining <= 0:
				_reroll_node(node, season)
				forage_node_rerolled.emit(position, node.item_id)
			continue

		if node.is_empty():
			_reroll_node(node, season)
			if not node.is_empty():
				forage_node_rerolled.emit(position, node.item_id)
			continue

		var def: ForageableDefinition = _definitions.get(node.item_id)
		if def == null or not def.valid_seasons.has(season):
			_reroll_node(node, season)
			forage_node_rerolled.emit(position, node.item_id)

func get_sell_price(item_id: String) -> int:
	var def: ForageableDefinition = _definitions.get(item_id)
	return def.base_sell_price if def != null else 0

func to_save_dict() -> Dictionary:
	var nodes_data := {}
	for position in _nodes.keys():
		nodes_data["%d,%d" % [position.x, position.y]] = _nodes[position].to_dict()
	return {"nodes": nodes_data}

func from_save_dict(data: Dictionary) -> void:
	_nodes.clear()
	var nodes_data: Dictionary = data.get("nodes", {})
	for key in nodes_data.keys():
		var parts: PackedStringArray = (key as String).split(",")
		if parts.size() != 2:
			continue
		var position := Vector2i(int(parts[0]), int(parts[1]))
		_nodes[position] = ForageNode.from_dict(nodes_data[key])
