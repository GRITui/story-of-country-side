extends Control
class_name TitleScreen
## Title screen (design/ui-flows/menu-hud-flow-spec.md §1) -- issue #92.
##
## Implements the spec's top-level menu shape against what actually exists
## today, with the same honesty rules as pause_menu.gd: real destinations
## are wired, missing ones are visibly disabled placeholders rather than
## faked screens or silently omitted items.
##
## Per-item status against the spec's §1 tree:
## - New Game: real. Per-slot: pressing New Game opens the slot picker
##   (3 slots), and picking one calls SaveManager.new_game_in_slot(n) --
##   fresh state + immediate persist into that slot -- then routes into
##   res://scenes/Main.tscn, whose MainController._ready() stays the
##   universal boot path (load-or-new, then intro-vs-HUD). Pre-staging the
##   fresh save here makes that load-or-new step an idempotent reload of
##   the same disk state, so Main.tscn keeps working unchanged as an
##   independently bootalable entry point (smoke boots,
##   superuser/autoplay/autoplay_driver.gd). NOTE: there is no confirmation
##   dialog yet, so picking a slot for New Game overwrites an existing save
##   in that slot immediately -- flagged in the PR, not hidden. The spec's
##   name-entry / mode-select / challenge-toggle children are future scope
##   (Decisions A/D unmade).
## - Continue: real. Enabled/disabled on _ready() from the public
##   SaveManager.has_any_save(). On press it opens the SAME slot picker in
##   Continue mode, listing each slot's metadata (day/season/year/gold) from
##   SaveManager.list_slots(); picking a slot runs SaveManager.load_game(n)
##   HERE first: a false return (missing/corrupt file -- possible despite
##   the gate, since has_any_save() only checks existence) keeps the player
##   on the title screen instead of silently becoming a new game; success
##   routes into Main.tscn. All persisted systems come back via
##   apply_save_data(), i.e. "where the player was" for everything the
##   save model tracks. Two documented gaps, not faked: the slot list shows
##   text metadata but NOT thumbnails (SaveManager.capture_thumbnail()
##   stamps them into each save's meta when a rendered viewport exists --
##   this screen has none, and decoding them here is UI-layer polish left to
##   the frontend lane), and the last world location isn't persisted either
##   (see main_controller.gd's travel_to docstring -- every boot lands at
##   Farm regardless).
## - Settings: disabled "(not yet implemented)" placeholder -- no settings
##   system exists (same treatment as PauseMenu's Settings button).
## - Quit: real, get_tree().quit().
##
## Slot picker mechanics: a single hidden SlotPanel (added to TitleScreen.tscn)
## is shown in either "new" or "continue" mode. Slot rows are built at open
## time from SaveManager.list_slots() so the screen always reflects the real
## disk state without maintaining its own mirror. The Back button closes the
## picker and returns to the main menu.
##
## While the title screen is up, TimeManager is frozen via
## freeze("title")/unfreeze("title") -- the same single reference-counted
## freeze mechanism the pause menu ("pause"), festivals, and the intro
## sequence ("intro") use, per the spec's own §1 one-time-freeze-mechanism
## rule. Unfrozen in _exit_tree() so the flag can't outlive the screen no
## matter how the scene exits.
##
## Testing seam: the button handlers are thin pairings of a state-only
## prepare_*() half and the _enter_game() navigation half. Headless tests
## call the prepare halves directly -- emitting a navigating button inside
## tests/TestRunner.tscn would change_scene away from the runner mid-suite
## (same reason pause_menu.gd's quit button is never emitted there).

const TITLE_FREEZE_REASON := "title"
const MAIN_SCENE_PATH := "res://scenes/Main.tscn"

const SLOT_MODE_NEW := "new"
const SLOT_MODE_CONTINUE := "continue"

@onready var _continue_button: Button = $Root/MenuPanel/Margin/VBox/ContinueButton
@onready var _settings_button: Button = $Root/MenuPanel/Margin/VBox/SettingsButton
@onready var _slot_panel: Control = $Root/SlotPanel
@onready var _slot_title: Label = $Root/SlotPanel/Margin/VBox/SlotTitle
@onready var _slots_vbox: VBoxContainer = $Root/SlotPanel/Margin/VBox/SlotsVBox
@onready var _back_button: Button = $Root/SlotPanel/Margin/VBox/BackButton

## Guards _enter_game() against a double activation (double-click, or New
## Game then Continue landing in the same frame before the scene swap) --
## change_scene_to_file() is already safe to call repeatedly, but the
## second prepare half would still run against the outgoing scene for no
## reason.
var _entering_game := false

## Which selection mode the slot picker is currently in -- one of
## SLOT_MODE_NEW / SLOT_MODE_CONTINUE. Drives what picking a row does.
var _slot_mode := SLOT_MODE_NEW

## Live references to the slot rows currently shown in _slots_vbox, so the
## picker can be rebuilt without leaking stale buttons.
var _slot_buttons: Array[Button] = []

func _ready() -> void:
	$Root/MenuPanel/Margin/VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	$Root/MenuPanel/Margin/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	# Settings has no destination yet -- disabled, not hidden, so the title
	# screen's shape still matches the spec's §1 tree even though one of
	# its four items isn't implemented (same reasoning as pause_menu.gd).
	_settings_button.disabled = true
	_slot_panel.visible = false
	_back_button.pressed.connect(_close_slot_panel)
	_refresh_continue_state()
	if TimeManager:
		TimeManager.freeze(TITLE_FREEZE_REASON)

func _exit_tree() -> void:
	if TimeManager:
		TimeManager.unfreeze(TITLE_FREEZE_REASON)

## Continue's enabled state is a point-in-time read of disk existence:
## SaveManager has no save-created/deleted signal (nothing else writes the
## files during a sitting on this screen), so a _ready()-time check is the
## whole contract, not a lazily-maintained mirror. Any of the three slots
## having a save enables Continue (it then opens the slot picker).
func _refresh_continue_state() -> void:
	_continue_button.disabled = not SaveManager.has_any_save()

func _on_new_game_pressed() -> void:
	_open_slot_panel(SLOT_MODE_NEW)

func _on_continue_pressed() -> void:
	_open_slot_panel(SLOT_MODE_CONTINUE)

## Shows the slot picker in the given mode and rebuilds its rows from the
## real disk state.
func _open_slot_panel(mode: String) -> void:
	_slot_mode = mode
	_slot_title.text = ("Choose a slot to Continue" if mode == SLOT_MODE_CONTINUE \
		else "Choose a slot for New Game")
	_rebuild_slot_buttons()
	$Root/MenuPanel.visible = false
	_slot_panel.visible = true

func _close_slot_panel() -> void:
	_slot_panel.visible = false
	$Root/MenuPanel.visible = true

func _rebuild_slot_buttons() -> void:
	for existing: Button in _slot_buttons:
		existing.queue_free()
	_slot_buttons.clear()
	for slot: Dictionary in SaveManager.list_slots():
		var row := Button.new()
		row.text = _slot_row_label(slot)
		row.pressed.connect(_on_slot_row_pressed.bind(slot["index"]))
		_slots_vbox.add_child(row)
		_slot_buttons.append(row)

func _slot_row_label(slot: Dictionary) -> String:
	if not slot["found"]:
		return "Slot %d - Empty" % (slot["index"] + 1)
	var meta: Dictionary = slot["meta"]
	return "Slot %d - Day %d, %s, Year %d | %dG" % [
		slot["index"] + 1,
		int(meta.get("day", 1)),
		str(meta.get("season", "Spring")),
		int(meta.get("year", 1)),
		int(meta.get("gold", 0)),
	]

func _on_slot_row_pressed(slot: int) -> void:
	if _slot_mode == SLOT_MODE_NEW:
		prepare_new_game_in_slot(slot)
	elif not prepare_continue_in_slot(slot):
		# A failed load (no/corrupt file) keeps the player here -- falling
		# through to Main.tscn would let its load-or-new fallback silently
		# turn their Continue into a brand-new game overwriting nothing but
		# their expectation.
		return
	_enter_game()

## State-only half of per-slot New Game: reset every system to fresh-boot
## defaults and persist the fresh save into `slot`.
func prepare_new_game_in_slot(slot: int) -> void:
	SaveManager.new_game_in_slot(slot)

## State-only half of per-slot Continue: load `slot` into every system.
## Returns false (leaving in-memory state untouched) when there's no
## readable save -- mirroring SaveManager.load_game()'s own return contract.
func prepare_continue_in_slot(slot: int) -> bool:
	return SaveManager.load_game(slot)

## State-only half of New Game: reset every system to fresh-boot defaults
## and persist the fresh save, via SaveManager.new_game()'s public API.
## Kept for backward compatibility (tests call the prepare halves directly);
## the picker routes through the per-slot variants above.
func prepare_new_game() -> void:
	SaveManager.new_game()

## State-only half of Continue: load the current slot into every system.
## Returns false (leaving in-memory state untouched) when there's no
## readable save -- mirroring SaveManager.load_game()'s own return contract.
func prepare_continue() -> bool:
	return SaveManager.load_game()

func _enter_game() -> void:
	if _entering_game:
		return
	_entering_game = true
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()