extends Node
## Autoload: SocialManager
## Implements #111 Marriage Loop & #110 Birthdays.

signal marriage_proposed(npc_name: String)
signal wedding_started(npc_name: String)
signal birthday_triggered(npc_name: String)

var _marriage_status: Dictionary = {} ## npc_name -> "single" | "engaged" | "married"
var _pendant_obtained: bool = false

func check_marriage_eligibility(npc_name: String) -> bool:
	var hearts = RelationshipManager.get_hearts(npc_name)
	return hearts >= 8 and _pendant_obtained

func propose_to(npc_name: String) -> bool:
	if not check_marriage_eligibility(npc_name):
		return false
	_marriage_status[npc_name] = "engaged"
	marriage_proposed.emit(npc_name)
	return true

func perform_wedding(npc_name: String) -> void:
	if _marriage_status.get(npc_name) == "engaged":
		_marriage_status[npc_name] = "married"
		wedding_started.emit(npc_name)

func trigger_birthday(npc_name: String) -> void:
	birthday_triggered.emit(npc_name)

func obtain_mermaid_pendant() -> void:
	_pendant_obtained = true
