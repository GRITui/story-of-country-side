extends Node
## Autoload: RelationshipManager
##
## Owns per-NPC friendship points (ENG-19): talking and gifting raise points,
## hitting a heart threshold fires a heart-event trigger signal. Threshold
## crossings are tracked per NPC so a jump across more than one heart in a
## single gift (unlikely, but not impossible with a loved gift near a
## boundary) still fires once per newly-crossed heart, not once total.

signal points_changed(npc_name: String, points: int, hearts: int)
signal heart_event_triggered(npc_name: String, heart_level: int)

const POINTS_PER_HEART := 250
const MAX_HEARTS := 10
const MAX_POINTS := POINTS_PER_HEART * MAX_HEARTS
const TALK_POINTS := 20
const BIRTHDAY_GIFT_MULTIPLIER := 8
const BirthdayRegistryRef = preload("res://scripts/social/birthday_registry.gd")

## npc_name -> .tres path, one entry per shipped GiftPreferenceTable resource
## (scripts/social/gift_preferences/, PR #58's Content-lane drop). Flagged as
## a gap in that PR's own description: the resources existed with no runtime
## NPC-name lookup path. Kept as a plain const dictionary (not a subsystem)
## since it is just data — new NPCs get a new entry here alongside their
## MarriageManager.MARRIAGEABLE_NPCS addition, no other wiring required.
const GIFT_PREFERENCE_PATHS := {
	"Elena": "res://scripts/social/gift_preferences/elena.tres",
	"Marcus": "res://scripts/social/gift_preferences/marcus.tres",
	"Priya": "res://scripts/social/gift_preferences/priya.tres",
	"Tobias": "res://scripts/social/gift_preferences/tobias.tres",
	"Sana": "res://scripts/social/gift_preferences/sana.tres",
	"Colton": "res://scripts/social/gift_preferences/colton.tres",
}

var _points: Dictionary = {} ## npc_name -> int
var _highest_triggered_heart: Dictionary = {} ## npc_name -> int
var _talked_today: Dictionary = {} ## npc_name -> bool
var _gifted_today: Dictionary = {} ## npc_name -> bool

## npc_name -> {heart_level(int) -> dialogue text}. Registered content, same
## "dictionary of data, not a subsystem" treatment GIFT_PREFERENCE_PATHS gets
## above. Closes a real gap Writer/Dialogue-Squad flagged (#53): a heart
## event fires via heart_event_triggered with no dialogue behind it -- this
## is the lookup plumbing only, empty until Content/Writer-Squad registers
## real text per NPC/level.
var _heart_event_dialogue: Dictionary = {}

func _ready() -> void:
	_register_default_content()
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
	# Register heart event dialogue content (Squad Gamma, #53)
	var heart_script = load("res://scripts/social/heart_dialogue_content.gd")
	if heart_script != null:
		if heart_script.has_method("register_all"):
			heart_script.register_all(self)
		else:
			var tmp = heart_script.new()
			if tmp.has_method("register_all"):
				tmp.register_all(self)

## Heart-event dialogue for the six GIFT_PREFERENCE_PATHS NPCs, at the same
## milestone levels the genre precedent uses (2/4/6/8/10 of MAX_HEARTS) --
## every heart level still fires heart_event_triggered per
## _check_heart_events(), but writing a distinct line for all ten levels per
## NPC would dilute rather than deepen the arc. Voice matches each NPC's
## established GiftPreferenceTable archetype (Colton = miner/blacksmith,
## Elena = gardener, Marcus = angler, Priya = farmer, Sana = rancher,
## Tobias = treasure hunter). Content lane per SQUAD-SPLIT.md -- registered
## via the plumbing PR #82 added, no logic touched here.
func _register_default_content() -> void:
	register_heart_event_dialogue("Colton", 2, "You've got dirt on your hands and you didn't complain once. I respect that more than you'd guess.")
	register_heart_event_dialogue("Colton", 4, "Most folks in town talk my ear off about nothing. You just talk. It's a nice change.")
	register_heart_event_dialogue("Colton", 6, "I don't say this to many people, but I look forward to you stopping by the forge. Don't let it go to your head.")
	register_heart_event_dialogue("Colton", 8, "Whatever you're carrying when you walk in, it feels lighter once you're standing here. That's not nothing.")
	register_heart_event_dialogue("Colton", 10, "I've spent my life around stone and iron because they don't change on you. Turns out you don't either. That's rarer than any ore I've dug up.")

	register_heart_event_dialogue("Elena", 2, "You brought me a flower without me asking. Not many people notice what I'd actually want.")
	register_heart_event_dialogue("Elena", 4, "I've started saving the prettiest blooms from my garden just to show you. I don't know why that feels important, but it does.")
	register_heart_event_dialogue("Elena", 6, "Talking to you feels like the first warm day after winter -- like something's finally allowed to grow.")
	register_heart_event_dialogue("Elena", 8, "I used to think I was happiest alone in the garden. Now I catch myself wishing you were the one standing beside me in it.")
	register_heart_event_dialogue("Elena", 10, "Whatever I plant from now on, I want you there to see it bloom. That's not a small thing for me to say.")

	register_heart_event_dialogue("Marcus", 2, "You didn't wince at the smell of my tackle box. That's more than most people manage.")
	register_heart_event_dialogue("Marcus", 4, "Caught something worth bragging about today, and the first person I wanted to tell was you.")
	register_heart_event_dialogue("Marcus", 6, "Fishing's always been the thing I do to get away from people. Lately I don't mind if you're the one sitting next to me on the dock.")
	register_heart_event_dialogue("Marcus", 8, "There's a spot down by the river I've never shown anyone. I keep meaning to take you there.")
	register_heart_event_dialogue("Marcus", 10, "I've hauled in a lot of things I thought I wanted, then let most of them go. You're not one I'm ever throwing back.")

	register_heart_event_dialogue("Priya", 2, "You actually asked how the cauliflower was doing this season. Nobody asks that.")
	register_heart_event_dialogue("Priya", 4, "I saved you the first ear of corn off the stalk. Figured you'd appreciate it more than most.")
	register_heart_event_dialogue("Priya", 6, "There's something steady about you. Around here, steady is worth more than exciting.")
	register_heart_event_dialogue("Priya", 8, "I've started planning next season's planting with you in mind -- what you'd like to see growing, not just what sells.")
	register_heart_event_dialogue("Priya", 10, "Farming taught me that the things worth keeping are the ones you tend to every single day. I'd like you to be one of those things.")

	register_heart_event_dialogue("Sana", 2, "The animals like you. They don't warm up to just anyone, so neither do I, usually.")
	register_heart_event_dialogue("Sana", 4, "I caught myself telling the goats about you this morning. They didn't have much to say back, but I did.")
	register_heart_event_dialogue("Sana", 6, "You don't need to bring me anything fancy. Just show up, same as always. That's worth more to me than gold.")
	register_heart_event_dialogue("Sana", 8, "Most people want to talk about themselves. You actually listen when I talk about the herd. That matters more than you know.")
	register_heart_event_dialogue("Sana", 10, "I've built a life around things that are simple and honest -- the animals, the land, the work. You fit right into that, and I don't say that lightly.")

	register_heart_event_dialogue("Tobias", 2, "You listened to the whole story about the sunken ship without your eyes glazing over. Rare find, that.")
	register_heart_event_dialogue("Tobias", 4, "I've got a theory about where the next dig site should be. Want to hear it, or are you just being polite?")
	register_heart_event_dialogue("Tobias", 6, "Most people think I chase treasure because I want the gold. Truth is, I just like finding things nobody else bothered to look for. Lately that includes you.")
	register_heart_event_dialogue("Tobias", 8, "I've traveled a long way looking for things worth keeping. Didn't expect to find one of them standing still, right here in town.")
	register_heart_event_dialogue("Tobias", 10, "I've held rubies and gold and things men would kill for, and none of it ever felt like this. You're the rarest thing I've found, and I'm done looking.")

func get_points(npc_name: String) -> int:
	return _points.get(npc_name, 0)

func get_hearts(npc_name: String) -> int:
	return get_points(npc_name) / POINTS_PER_HEART

func has_talked_today(npc_name: String) -> bool:
	return _talked_today.get(npc_name, false)

func has_gifted_today(npc_name: String) -> bool:
	return _gifted_today.get(npc_name, false)

## Returns false (no-op) if this NPC has already been talked to today —
## matches the once-per-day pattern established for stamina/time resets.
func talk_to(npc_name: String) -> bool:
	if has_talked_today(npc_name):
		return false
	_talked_today[npc_name] = true
	_add_points(npc_name, TALK_POINTS)
	return true

## Returns false (no-op) if this NPC has already received a gift today.
## `preferences` is that NPC's GiftPreferenceTable; passed in rather than
## looked up here since this system doesn't own NPC-to-preference wiring
## (that's the caller's/data layer's job, same separation StaminaManager
## keeps from the Shipping Bin economy).
func give_gift(npc_name: String, item_id: String, preferences: GiftPreferenceTable) -> bool:
	if has_gifted_today(npc_name):
		return false
	_gifted_today[npc_name] = true
	var delta: int = preferences.point_delta_for(item_id) if preferences else 0
	if delta > 0 and BirthdayRegistryRef.is_birthday_today(npc_name): # BirthdayRegistry class_name
		delta *= BIRTHDAY_GIFT_MULTIPLIER
	_add_points(npc_name, delta)
	return true

## Looks up npc_name's GiftPreferenceTable via GIFT_PREFERENCE_PATHS and
## calls through to give_gift(). Graceful fallback for an NPC with no known
## preference table (not yet in GIFT_PREFERENCE_PATHS -- e.g. a non-
## marriageable NPC nobody's written preferences for): no-op, returns false,
## same "rejected" shape has_gifted_today()-gated give_gift() already uses,
## rather than crashing or silently treating every item as neutral.
func give_gift_by_npc_name(npc_name: String, item_id: String) -> bool:
	if not GIFT_PREFERENCE_PATHS.has(npc_name):
		return false
	var preferences: GiftPreferenceTable = load(GIFT_PREFERENCE_PATHS[npc_name])
	return give_gift(npc_name, item_id, preferences)

func _add_points(npc_name: String, delta: int) -> void:
	var new_points: int = clampi(get_points(npc_name) + delta, 0, MAX_POINTS)
	_points[npc_name] = new_points
	var hearts := new_points / POINTS_PER_HEART
	points_changed.emit(npc_name, new_points, hearts)
	_check_heart_events(npc_name, hearts)

## Registers the dialogue line shown for npc_name's heart_level heart event.
## Re-registering the same (npc_name, heart_level) pair overwrites it, same
## "last write wins" convention every other manager's register_* follows.
func register_heart_event_dialogue(npc_name: String, heart_level: int, text: String) -> void:
	if npc_name.is_empty():
		return
	if not _heart_event_dialogue.has(npc_name):
		_heart_event_dialogue[npc_name] = {}
	_heart_event_dialogue[npc_name][heart_level] = text

## Returns the registered dialogue for npc_name's heart_level heart event, or
## "" if nothing has been registered for that pair -- fail-quiet, same
## convention as get_current_music()/is_sfx_registered() elsewhere, so a
## caller can always safely display the result without a null check.
func get_heart_event_dialogue(npc_name: String, heart_level: int) -> String:
	var by_level: Dictionary = _heart_event_dialogue.get(npc_name, {})
	return by_level.get(heart_level, "")

func _check_heart_events(npc_name: String, hearts: int) -> void:
	var highest: int = _highest_triggered_heart.get(npc_name, 0)
	while highest < hearts:
		highest += 1
		heart_event_triggered.emit(npc_name, highest)
	_highest_triggered_heart[npc_name] = highest

func _on_day_started(_day_in_season: int, _season: String, _day_of_week: String) -> void:
	_talked_today.clear()
	_gifted_today.clear()

func to_save_dict() -> Dictionary:
	return {
		"points": _points.duplicate(),
		"highest_triggered_heart": _highest_triggered_heart.duplicate(),
	}

func from_save_dict(data: Dictionary) -> void:
	_points = (data.get("points", {}) as Dictionary).duplicate()
	_highest_triggered_heart = (data.get("highest_triggered_heart", {}) as Dictionary).duplicate()
	_talked_today.clear()
	_gifted_today.clear()
