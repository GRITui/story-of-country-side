extends Node
## Simple validation that starter_content.gd registers quests correctly.
## Run headless to verify the three starter quests appear in QuestManager.

func _ready() -> void:
    _test_starter_quests_registered()
    print("✓ Starter quest test passed")

func _test_starter_quests_registered() -> void:
    var qm := QuestManager
    var expected := {
        "off_your_chest": "farm_unlocked",
        "first_coin": "ranch_unlocked", 
        "friendly_face": "forage_unlocked"
    }
    
    for quest_id in expected.keys():
        assert(qm.is_completed(quest_id) == false, "Quest " + quest_id + " should not be completed initially")
        assert(qm.is_unlocked(expected[quest_id]) == false, "Flag " + expected[quest_id] + " should not be unlocked initially")
    
    # Verify that QuestManager._quests dict contains the three starter quests
    var has_off = false
    var has_first = false
    var has_friendly = false
    
    for quest_id in qm._quests.keys():
        if quest_id == "off_your_chest":
            has_off = true
        elif quest_id == "first_coin":
            has_first = true
        elif quest_id == "friendly_face":
            has_friendly = true
    
    assert(has_off, "QuestManager should contain 'off_your_chest' quest")
    assert(has_first, "QuestManager should contain 'first_coin' quest")
    assert(has_friendly, "QuestManager should contain 'friendly_face' quest")
