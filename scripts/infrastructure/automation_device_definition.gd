class_name AutomationDeviceDefinition
extends Resource
## One late-game automation device's build cost (Decision C's #4
## resolution: automation as a late-game unlock path, tool/infrastructure
## upgrade tier). One-shot build, same convention as
## ArtisanMachineRecipe/InfrastructureManager.build_machine -- not a
## tiered track like House/Coop, since there's nothing to tier: a device
## is either built or not.
##
## Deliberately no recipe/input/output fields (unlike
## ArtisanMachineRecipe) -- these devices don't process items, they
## automate an existing daily action (water/feed/collect) that already
## exists on FarmPlotManager/AnimalManager.

@export var device_type: String = ""
@export var unlock_flag: String = ""
@export var gold_cost: int = 0
@export var material_item_id: String = ""
@export var material_quantity: int = 0
