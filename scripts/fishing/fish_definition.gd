class_name FishDefinition
extends Resource
## One fish species' pool conditions and catch economy. .tres-authorable
## content, same split as CropDefinition/AnimalDefinition.

@export var fish_id: String = ""
@export var display_name: String = ""

@export var valid_seasons: Array[String] = []

## Free-form location strings, same convention as NPCScheduleEntry's
## location_name -- no dedicated Location/map-zone system exists in this
## repo yet, so this just matches whatever string the (not-yet-built)
## fishing-spot scene passes in.
@export var valid_locations: Array[String] = []

## Inclusive hour window, e.g. 6..11 for a morning-only fish. No overnight
## wraparound support (end assumed >= start) -- simplification, not a
## genre requirement, revisit if a fish needs an overnight window.
@export var start_hour: int = 0
@export var end_hour: int = 23

## 0.0-1.0 -- the minimum mini-game "performance" score
## (FishingManager.attempt_catch's performance param) needed to land this
## fish. Higher = harder. The mini-game itself (input/skill-check design)
## is explicitly out of scope for #15 per the issue text ("TBD") and is a
## Frontend/UI concern (see SQUAD-SPLIT.md) -- this is only the pass/fail
## contract a future mini-game scene calls into.
@export var difficulty: float = 0.3

@export var base_sell_price: int = 0
@export var xp_reward: int = 0
