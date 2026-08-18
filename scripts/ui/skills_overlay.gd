extends CanvasLayer
class_name SkillsOverlay
## Full-screen Skills / Progression overlay (design/ui-flows/menu-hud-flow-spec.md
## §1/§3), reachable from the pause menu (§1) -- fills the "Skills" gap
## PauseMenu's own docstring flagged as a disabled "(not yet implemented)"
## button pending a real destination.
##
## Same chrome/structure as InventoryOverlay (§3's "consistent screen
## chrome: title top-left, close/back control top-right" rule) and the
## same pure-display discipline as HUD/InventoryOverlay: every row reads
## from SkillManager at scene-ready time and stays in sync via its
## xp_gained/level_changed signals -- no SkillsOverlay-local duplicate XP
## state.
##
## SkillManager itself has no "list every skill" getter -- it's a bare
## skill_name -> xp Dictionary with skill names supplied ad-hoc by
## whichever activity manager calls add_xp() (its own docstring confirms
## this: "Recipe/crafting unlocks... have no concrete content anywhere in
## the design doc"). The four real skill names actually in play --
## Farming, Fishing, Mining, Foraging -- are established content, not
## invented here: every activity manager already calls
## SkillManager.add_xp() with exactly one of these four (Ranching feeds
## Farming per SkillManager's own docstring; Combat is excluded per
## Decision B). Hardcoding that same four-item list here is reading
## existing content, the same way HUD hardcodes its hotbar slot count as
## a documented placeholder -- not fabricating new backend state.
##
## No perk/recipe-unlock UI -- SkillManager's own docstring says that
## content doesn't exist anywhere yet, so there is nothing to render for
## it. Each row shows level + XP only.

signal closed

const SKILL_NAMES := ["Farming", "Fishing", "Mining", "Foraging"]

@onready var _list: VBoxContainer = $Root/Panel/Margin/VBox/SkillList
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Header/CloseButton

var _rows: Dictionary = {} # skill_name -> Label

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	SkillManager.xp_gained.connect(_on_xp_gained)
	SkillManager.level_changed.connect(_on_level_changed)
	_prime_from_current_state()

func _prime_from_current_state() -> void:
	for skill_name in SKILL_NAMES:
		_refresh_row(skill_name)

func _on_xp_gained(skill_name: String, _amount: int, _total_xp: int) -> void:
	_refresh_row(skill_name)

func _on_level_changed(skill_name: String, _new_level: int, _old_level: int) -> void:
	_refresh_row(skill_name)

func _refresh_row(skill_name: String) -> void:
	var label: Label = _rows.get(skill_name)
	if label == null:
		label = Label.new()
		label.name = "Skill_%s" % skill_name
		_list.add_child(label)
		_rows[skill_name] = label
	label.text = "%s  Lv %d  (%d XP)" % [skill_name, SkillManager.get_level(skill_name), SkillManager.get_xp(skill_name)]

func _on_close_pressed() -> void:
	closed.emit()

func _exit_tree() -> void:
	if SkillManager.xp_gained.is_connected(_on_xp_gained):
		SkillManager.xp_gained.disconnect(_on_xp_gained)
	if SkillManager.level_changed.is_connected(_on_level_changed):
		SkillManager.level_changed.disconnect(_on_level_changed)
