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
## - New Game: real. Calls SaveManager.new_game() ITSELF (fresh state +
##   immediate persist) -- exactly what scripts/story/main_controller.gd's
##   own docstring prescribed for this button -- then routes into
##   res://scenes/Main.tscn, whose MainController._ready() stays the
##   universal boot path (load-or-new, then intro-vs-HUD). Pre-staging the
##   fresh save here makes that load-or-new step an idempotent reload of
##   the same disk state, so Main.tscn keeps working unchanged as an
##   independently bootalable entry point (smoke boots,
##   superuser/autoplay/autoplay_driver.gd). NOTE: there is no confirmation
##   dialog yet, so New Game overwrites an existing save immediately --
##   flagged in the PR, not hidden. The spec's name-entry / mode-select /
##   challenge-toggle children are future scope (Decisions A/D unmade).
## - Continue: real. Enabled/disabled on _ready() from the public
##   SaveManager.has_save_file(). On press, SaveManager.load_game() runs
##   HERE first: a false return (missing/corrupt file -- possible despite
##   the enabled gate, since has_save_file() only checks existence) leaves
##   the player on the title screen instead of silently becoming a new
##   game; success routes into Main.tscn. All persisted systems come back
##   via apply_save_data(), i.e. "where the player was" for everything the
##   save model tracks. Two documented gaps, not faked: the spec's save
##   slot list (thumbnail/date/playtime) doesn't exist because SaveManager
##   is deliberately single-slot with no metadata-read API (see
##   save_manager.gd's own docstring), and the last world location isn't
##   persisted either (see main_controller.gd's travel_to docstring --
##   every boot lands at Farm regardless).
## - Settings: disabled "(not yet implemented)" placeholder -- no settings
##   system exists (same treatment as PauseMenu's Settings button).
## - Quit: real, get_tree().quit().
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

@onready var _continue_button: Button = $Root/MenuPanel/Margin/VBox/ContinueButton
@onready var _settings_button: Button = $Root/MenuPanel/Margin/VBox/SettingsButton

## Guards _enter_game() against a double activation (double-click, or New
## Game then Continue landing in the same frame before the scene swap) --
## change_scene_to_file() is already safe to call repeatedly, but the
## second prepare half would still run against the outgoing scene for no
## reason.
var _entering_game := false

func _ready() -> void:
	$Root/MenuPanel/Margin/VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	$Root/MenuPanel/Margin/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	# Settings has no destination yet -- disabled, not hidden, so the title
	# screen's shape still matches the spec's §1 tree even though one of
	# its four items isn't implemented (same reasoning as pause_menu.gd).
	_settings_button.disabled = true
	_refresh_continue_state()
	if TimeManager:
		TimeManager.freeze(TITLE_FREEZE_REASON)

func _exit_tree() -> void:
	if TimeManager:
		TimeManager.unfreeze(TITLE_FREEZE_REASON)

## Continue's enabled state is a point-in-time read of disk existence:
## SaveManager has no save-created/deleted signal (nothing else writes the
## file during a sitting on this screen), so a _ready()-time check is the
## whole contract, not a lazily-maintained mirror.
func _refresh_continue_state() -> void:
	_continue_button.disabled = not SaveManager.has_save_file()

func _on_new_game_pressed() -> void:
	prepare_new_game()
	_enter_game()

func _on_continue_pressed() -> void:
	# A failed load (no/corrupt file) keeps the player here -- falling
	# through to Main.tscn would let its load-or-new fallback silently turn
	# their Continue into a brand-new game overwriting nothing but their
	# expectation.
	var loaded := prepare_continue()
	if loaded:
		_enter_game()
	# Else stay on title screen (failed load)

## State-only half of New Game: reset every system to fresh-boot defaults
## and persist the fresh save, via SaveManager.new_game()'s public API.
func prepare_new_game() -> void:
	SaveManager.new_game()

## State-only half of Continue: load the save into every system. Returns
## false (leaving in-memory state untouched) when there's no readable
## save -- mirroring SaveManager.load_game()'s own return contract.
func prepare_continue() -> bool:
	return SaveManager.load_game()

func _enter_game() -> void:
	if _entering_game:
		return
	_entering_game = true
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()