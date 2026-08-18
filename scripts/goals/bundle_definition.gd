class_name BundleDefinition
extends Resource
## One collection bundle for the Community-Center-style ultimate goal
## (ENG-27) -- a set of items the player contributes from their inventory.
## .tres-authorable like every other content type in this repo
## (CropDefinition, QuestDefinition, etc.).

@export var bundle_id: String = ""
@export var title: String = ""

## item_id -> quantity required. Contributing removes the item from
## InventoryManager, same "pull from inventory, don't invent a second
## ledger" pattern InventoryManager.sell_item() already established.
@export var required_items: Dictionary = {}
