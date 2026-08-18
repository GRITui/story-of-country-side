class_name FestivalDefinition
extends Resource
## One seasonal festival's fixed date. .tres-authorable content, same split
## as FishDefinition/CropDefinition/AnimalDefinition.
##
## No location field -- unlike FishDefinition's valid_locations, no
## "player location" concept exists anywhere in this repo yet (see
## FestivalManager's top-of-file docstring), so a festival firing is
## unconditional on the registered day/season, not location-gated.

@export var festival_id: String = ""
@export var display_name: String = ""

## SEASONS entries from TimeManager ("Spring"/"Summer"/"Fall"/"Winter").
@export var season: String = ""

## 1..TimeManager.DAYS_PER_SEASON.
@export var day_of_season: int = 1
