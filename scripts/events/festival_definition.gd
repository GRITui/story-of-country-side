class_name FestivalDefinition
extends Resource
## One seasonal festival's fixed date. .tres-authorable content, same split
## as FishDefinition/CropDefinition/AnimalDefinition.
##
## S-Tier P2 (Epsilon) retains additive flavor_text defaults so every
## festival reads coherently even before Gamma's writer pass lands.

@export var festival_id: String = ""
@export var display_name: String = ""

## SEASONS entries from TimeManager ("Spring"/"Summer"/"Fall"/"Winter").
@export var season: String = ""

## 1..TimeManager.DAYS_PER_SEASON.
@export var day_of_season: int = 1

## Short narrative blurb shown alongside the festival.
## Epsilon owns the manager and additive copy here; Gamma owns the
## final polished text — additive, not competitive.
@export var flavor_text: String = ""
