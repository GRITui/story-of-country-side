class_name ArtisanMachineRecipe
extends Resource
## One artisan processing machine's build cost + its (single, in this
## placeholder scope) recipe: raw ingredient in, processed good out, after
## a TimeManager-day-counted delay. .tres-authorable content, same
## "content, not hardcoded logic" spirit as ToolUpgradeTier/QuestDefinition.
##
## Machine build gating follows the same Decision C (#4) shape as
## InfrastructureTier: quest unlock_flag (via QuestManager.is_unlocked)
## PLUS material+gold cost. Each machine_type is its own one-shot build
## (not a tiered track) -- once built via
## InfrastructureManager.build_machine(machine_type) it stays built.
##
## Real games in this genre (Stardew Valley's keg/preserves jar/cheese
## press) support many recipes per machine (any fruit -> that fruit's
## wine, etc.) with per-ingredient output items and prices. That richer
## recipe table isn't built here -- no ingredient/pricing data exists in
## this repo to draw from, and the issue's own comment thread flags no
## concrete recipe list. This resource intentionally models ONE fixed
## input_item_id -> output_item_id recipe per machine as an honest
## placeholder; swapping to a per-input recipe table is a natural follow-up
## once real ingredient content exists.

@export var machine_type: String = ""
@export var unlock_flag: String = ""
@export var gold_cost: int = 0
@export var material_item_id: String = ""
@export var material_quantity: int = 0

@export var input_item_id: String = ""
@export var input_quantity: int = 1
@export var output_item_id: String = ""
@export var output_quantity: int = 1

## Whole in-game days (counted on TimeManager.day_started ticks) the job
## takes from start_job() to becoming ready for collect_job().
@export var process_days: int = 1
