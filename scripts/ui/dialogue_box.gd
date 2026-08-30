extends CanvasLayer
class_name DialogueBox
## PO-16BIT-HCI-3: Diegetic retro dialogue — wood-bordered bottom frame, portrait left,
## typewriter + blip, manga emotes over head (sweatdrop 3x5, anger 4x4, heart, !).
##
## Responsive Control: anchored bottom full-width, fixed height 148px, scales with viewport.
## Usage:
##   var box := load("res://scenes/ui/DialogueBox.tscn").instantiate()
##   add_child(box)
##   box.show_dialogue("Elena", "res://assets/16bit/characters/elena_idle.png", "Hello, farmer!")
##   box.show_dialogue("Elena", portrait, "Second line", "sweatdrop") # with emote
##   box.advance() — if typing, skip; else close/next
##
## Audio blip via AudioManager.play_sfx("dialogue_blip") if registered; falls back to no crash.

signal dialogue_finished
signal dialogue_advanced

const TYPEWRITER_CPS := 32.0 # characters per second
const BLIP_EVERY_N_CHARS := 2
const EMOTE_DURATION := 1.2

const EMOTE_PATHS := {
	"sweatdrop": "res://assets/16bit/ui/emote_sweatdrop.png",
	"anger": "res://assets/16bit/ui/emote_anger.png",
	"surprise": "res://assets/16bit/ui/emote_surprise.png",
	"heart": "res://assets/16bit/ui/icon_heart.png",
	"!": "res://assets/16bit/ui/emote_surprise.png",
	"exclamation": "res://assets/16bit/ui/emote_surprise.png",
}

@onready var _panel: PanelContainer = $Root/Frame
@onready var _portrait_rect: TextureRect = $Root/Frame/HBox/Portrait
@onready var _name_label: Label = $Root/Frame/HBox/TextVBox/NameLabel
@onready var _dialog_label: RichTextLabel = $Root/Frame/HBox/TextVBox/DialogLabel
@onready var _next_hint: Label = $Root/Frame/HBox/TextVBox/NextHint
@onready var _emote_rect: TextureRect = $Root/Frame/HBox/Portrait/Emote

var _full_text: String = ""
var _visible_count: int = 0
var _is_typing: bool = false
var _char_timer: float = 0.0
var _blip_counter: int = 0
var _emote_timer: float = 0.0

func _ready() -> void:
	layer = 20
	_style_wood_frame()
	if not AudioManager.is_sfx_registered("dialogue_blip"):
		AudioManager.register_sfx("dialogue_blip", 880.0, 0.06)
	visible = false
	_next_hint.visible = false
	if _emote_rect:
		_emote_rect.visible = false
	set_process(true)
	# Ensure canvas focus so Space/J advances without extra click (InputMapManager helper)
	if has_node("/root/InputMapManager"):
		var imm: Node = get_node("/root/InputMapManager")
		if imm.has_method("ensure_canvas_focus"):
			imm.ensure_canvas_focus()

func _style_wood_frame() -> void:
	if _panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.26, 0.18, 0.10) # dark wood inside
	sb.border_color = Color(0.52, 0.36, 0.18) # light wood border
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)

const PORTRAIT_MAP := {
	NPCConstants.NPC_TOBY: "res://assets/16bit/characters/portrait_toby.png",
	NPCConstants.NPC_HANNA: "res://assets/16bit/characters/portrait_hanna.png",
	NPCConstants.NPC_CLIFF: "res://assets/16bit/characters/portrait_cliff.png",
	NPCConstants.NPC_NINA: "res://assets/16bit/characters/portrait_nina.png",
	NPCConstants.NPC_CID: "res://assets/16bit/characters/portrait_cid.png",
	NPCConstants.NPC_KAI: "res://assets/16bit/characters/portrait_kai.png",
	NPCConstants.NPC_LEO: "res://assets/16bit/characters/portrait_leo.png",
}
const PORTRAIT_ALIASES := {
	"portrait_oldman.png": "res://assets/16bit/characters/portrait_toby.png",
	"portrait_shopkeeper.png": "res://assets/16bit/characters/portrait_hanna.png",
	"portrait_blacksmith.png": "res://assets/16bit/characters/portrait_cliff.png",
	"portrait_barkeeper.png": "res://assets/16bit/characters/portrait_nina.png",
	"portrait_carpenter.png": "res://assets/16bit/characters/portrait_cid.png",
	"portrait_fisherman.png": "res://assets/16bit/characters/portrait_kai.png",
	"portrait_boy1.png": "res://assets/16bit/characters/portrait_leo.png",
}
const FALLBACK_PORTRAIT := "res://assets/16bit/characters/portrait_player.png"

func _portrait_for(speaker: String) -> String:
	var cn := NPCConstants.canonical(speaker)
	if PORTRAIT_MAP.has(cn): return PORTRAIT_MAP[cn]
	if PORTRAIT_MAP.has(speaker): return PORTRAIT_MAP[speaker]
	# legacy alias lookup
	var legacy := "portrait_%s.png" % speaker.to_lower()
	if PORTRAIT_ALIASES.has(legacy): return PORTRAIT_ALIASES[legacy]
	return ""

func show_dialogue(speaker: String, portrait_path: String, text: String, emote: String = "") -> void:
	_full_text = text
	_visible_count = 0
	_is_typing = true
	_char_timer = 0.0
	_blip_counter = 0
	visible = true
	var cn := NPCConstants.canonical(speaker)
	var display := cn if NPCConstants.is_canonical(cn) else speaker
	var kata := NPCConstants.katakana(cn)
	_name_label.text = "【 %s 】" % display + (" (%s)" % kata if kata != "" else "")
	# 16-bit header: validate width/line-height — single line 16-bit bracket, no wrap/clip
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.clip_text = false
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Ensure 16-bit font metrics: 14px + Katakana fallback same line-height (DialogLabel 14px), header never wraps
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_constant_override("line_spacing", 0)
	_dialog_label.text = ""
	_next_hint.visible = false
	# Portrait — try explicit path, then canonical map, then fallback hidden
	var tex: Texture2D = null
	var try_paths: Array[String] = []
	if portrait_path != "": try_paths.append(portrait_path)
	var mapped := _portrait_for(speaker)
	if mapped != "": try_paths.append(mapped)
	# alias fallback for legacy names + final fallback
	try_paths.append(FALLBACK_PORTRAIT)
	for p in try_paths:
		# handle legacy alias redirect
		var actual := PORTRAIT_ALIASES.get(p.get_file(), p)
		if ResourceLoader.exists(actual):
			var maybe: Texture2D = load(actual)
			if maybe and maybe.get_image():
				tex = maybe; break
		elif ResourceLoader.exists(p):
			var maybe: Texture2D = load(p)
			if maybe and maybe.get_image():
				tex = maybe; break
	_portrait_rect.texture = tex
	# Fallback: always visible with placeholder if no portrait, never broken image
	_portrait_rect.visible = true
	if tex == null:
		_portrait_rect.modulate = Color(0.6,0.6,0.6,0.5)
	else:
		_portrait_rect.modulate = Color(1,1,1,1)
	if emote != "":
		show_emote(emote)
	# Freeze time while dialogue is open (matches pause menu convention)
	if TimeManager and not TimeManager.is_frozen():
		TimeManager.freeze("dialogue")

func show_emote(emote: String) -> void:
	var key := emote.to_lower()
	var path: String = EMOTE_PATHS.get(key, "")
	if path == "" and emote != "":
		path = emote # allow direct path
	if path == "" or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex == null or tex.get_image() == null:
		return
	_emote_rect.texture = tex
	_emote_rect.visible = true
	# Manga size hints: sweatdrop 3x5 logical, anger 4x4 — but actual PNGs are 16x16, so keep centered.
	_emote_rect.custom_minimum_size = Vector2(24, 24)
	_emote_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emote_timer = EMOTE_DURATION

func hide_emote() -> void:
	if _emote_rect:
		_emote_rect.visible = false
	_emote_timer = 0.0

func is_typing() -> bool:
	return _is_typing

func advance() -> void:
	if _is_typing:
		# Skip typewriter
		_visible_count = _full_text.length()
		_dialog_label.text = _full_text
		_is_typing = false
		_next_hint.visible = true
		return
	# Already complete — close dialogue
	close_dialogue()

func close_dialogue() -> void:
	visible = false
	_is_typing = false
	hide_emote()
	if TimeManager:
		TimeManager.unfreeze("dialogue")
	dialogue_finished.emit()
	queue_free()

func _process(delta: float) -> void:
	if _emote_timer > 0:
		_emote_timer -= delta
		if _emote_timer <= 0:
			hide_emote()
	if not _is_typing:
		return
	_char_timer += delta
	var chars_to_add := int(_char_timer * TYPEWRITER_CPS)
	if chars_to_add <= 0:
		return
	_char_timer -= float(chars_to_add) / TYPEWRITER_CPS
	var prev := _visible_count
	_visible_count = mini(_visible_count + chars_to_add, _full_text.length())
	_dialog_label.text = _full_text.substr(0, _visible_count)
	# Blip every N chars
	var added := _visible_count - prev
	for i in range(added):
		_blip_counter += 1
		if _blip_counter % BLIP_EVERY_N_CHARS == 0:
			if AudioManager and AudioManager.has_method("play_sfx"):
				AudioManager.play_sfx("dialogue_blip")
	if _visible_count >= _full_text.length():
		_is_typing = false
		_next_hint.visible = true
		dialogue_advanced.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("primary_action") or event.is_action_pressed("advance_dialog") or event.is_action_pressed("secondary_action") or event.is_action_pressed("interact"):
		if event is InputEventKey and event.echo:
			return
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
