class_name JournalEntry
extends Resource
## JournalEntry (#117): one discovered-item record for the collection journal.
##
## Not a Node, not an autoload -- plain Resource so it can be constructed
## in journal_manager.gd and serialized via to_dict/from_dict. Each entry
## captures the normalized item_id (stripped of quality suffix), its
## category ("fish"/"crop"/"ore"/"forage"), and the day it was first seen.

@export var item_id: String = ""
@export var category: String = ""
@export var discovered_day: int = 0
@export var display_name: String = ""

func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"category": category,
		"discovered_day": discovered_day,
		"display_name": display_name,
	}

static func from_dict(data: Dictionary) -> JournalEntry:
	var e := JournalEntry.new()
	e.item_id = data.get("item_id", "")
	e.category = data.get("category", "")
	e.discovered_day = data.get("discovered_day", 0)
	e.display_name = data.get("display_name", "")
	return e
