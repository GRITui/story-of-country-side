class_name SeedDefinition
extends Resource
## One purchasable seed's content: which crop it grows, what it costs at
## the seed shop, and which season it belongs to. .tres-authorable, same
## split as CropDefinition/FestivalDefinition/FishDefinition -- data, not
## logic.
##
## Introduced by ENG-91 (seed economy): before this there were no seed
## items in the codebase and FarmPlotManager.plant() was free, making
## farming an infinite money printer (sprint-002 P1).
##
## Item-id convention: a seed's inventory item_id is "<crop_id>_seed"
## (e.g. "parsnip_seed"), mirroring how FarmPlotManager encodes quality
## tiers into harvested-item ids ("parsnip_gold"). The crop itself keeps
## its plain id ("parsnip") for its harvested-item ids. One convention,
## documented here and consumed by FarmPlotManager.get_seed_id() /
## ShopManager.
##
## Prices shipped here are PLACEHOLDERS pending the ORCH-002 content
## balance pass -- same placeholder honesty as every other price table in
## this repo (crop sell prices #53, tool costs #23, machine costs).

@export var seed_id: String = ""

## Display string for shop/UI listing; Content lane's to tune.
@export var display_name: String = ""

## The registered FarmPlotManager crop this seed grows. plant() consumes
## one of these seeds to place that crop on a plot.
@export var crop_id: String = ""

## Gold cost per seed at the shop, paid through ShippingBinManager.spend().
## PLACEHOLDER value pending ORCH-002 balance pass.
@export var price: int = 10

## Season this seed is intended for. Primarily informational for shop
## UI filtering; the actual planting gate is CropDefinition.valid_seasons
## checked at plant() time, not here.
@export var season: String = ""
