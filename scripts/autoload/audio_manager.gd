extends Node
## Autoload: AudioManager
##
## Honesty up front: this repo had zero audio anywhere before this file --
## no music, no SFX, no AudioStreamPlayer usage. This is the integration
## *layer*: a small public API every other manager's existing signals can
## call into. Two AudioStreamPlayer children -- one for one-shot SFX, one
## for a looping "music" drone -- same "autoload owns its own Node
## children" pattern SaveManager/TimeManager use for their own bookkeeping.
##
## SFX are now real audio: the seven SFX registered in
## _register_default_content() below are genuine CC0-licensed clips from
## Kenney's "Interface Sounds" pack (assets/kenney/interface-sounds/, see
## that directory's ATTRIBUTION.md for full provenance/license verification
## and an honest note on how the specific sound-to-event mapping was picked
## without any audio playback capability in this environment). Music is
## still a procedurally generated sine drone (AudioStreamGenerator) -- no
## fitting free CC0 music/ambient loop was found this round, so it stays an
## honest placeholder rather than a forced bad fit (see
## ATTRIBUTION.md's "What's still procedural" section). Nothing here is a
## human composer's or sound designer's finished work; the Studio Head has
## this project's real-audio gap on record separately.
##
## Headless test note: `godot --headless` still initializes an audio
## driver (Dummy on platforms with no real device), so play()/
## get_stream_playback() don't crash, but there's no real output device to
## assert against. Tests verify logic/signal-wiring (sfx_played/
## music_changed/music_stopped firing with the right id, get_current_music()
## reflecting state), not actual sound.

signal sfx_played(sfx_id: String)
signal music_changed(track_id: String)
signal music_stopped()

const MIX_RATE := 44100.0
## Keeps the generator buffer comfortably ahead of the longest registered
## SFX duration so a one-shot push never overruns it.
const GENERATOR_BUFFER_LENGTH := 2.0
## Quiet by construction -- a full-amplitude sine at these frequencies is
## unpleasant; this is a placeholder tone, not mixed/mastered audio.
const AMPLITUDE := 0.2

## sfx_id -> {kind: "procedural", frequency: float, duration: float}
##        or {kind: "asset", stream: AudioStream}
var _sfx_defs: Dictionary = {}
## track_id -> {frequency: float} -- music stays procedural-only for now,
## see this file's top-of-file docstring.
var _music_defs: Dictionary = {}

var _current_music_id: String = ""
var _music_phase: float = 0.0
var _music_frequency: float = 0.0
var _music_playback: AudioStreamGeneratorPlayback

## Bumped on every new one-shot tone; a pending stop-timer callback checks
## it still matches before stopping, so a stale timer from a superseded
## tone can never cut off a newer one that's already reusing the player.
var _sfx_playback_token: int = 0

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

	_register_default_content()
	_connect_signals()

## --- Content registration ---
## Same "content-gap honesty" convention every other manager's
## _register_default_content() uses (see e.g. infrastructure_manager.gd).
## Re-registering an id overwrites it, real asset or procedural either way.

## Procedural fallback -- register a sine-tone SFX (used where no fitting
## free asset exists yet; none of the four defaults below use this path
## anymore, but it stays available for future signal hookups).
func register_sfx(sfx_id: String, frequency: float, duration: float) -> void:
	if sfx_id.is_empty() or frequency <= 0.0 or duration <= 0.0:
		return
	_sfx_defs[sfx_id] = {"kind": "procedural", "frequency": frequency, "duration": duration}

## Real-asset SFX -- loads a genuine AudioStream (e.g. a CC0-licensed clip
## under assets/kenney/, see that directory's ATTRIBUTION.md) instead of
## synthesizing a tone. Silently no-ops on an empty id/path or a path that
## fails to load, same "fail quiet" convention as register_sfx above.
func register_sfx_asset(sfx_id: String, path: String) -> void:
	if sfx_id.is_empty() or path.is_empty():
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_sfx_defs[sfx_id] = {"kind": "asset", "stream": stream}

func register_music(track_id: String, frequency: float) -> void:
	if track_id.is_empty() or frequency <= 0.0:
		return
	_music_defs[track_id] = {"frequency": frequency}

func _register_default_content() -> void:
	## Real CC0 clips (Kenney's Interface Sounds pack) -- see
	## assets/kenney/interface-sounds/ATTRIBUTION.md for provenance, license
	## verification, and how each sound-to-event mapping below was picked.
	register_sfx_asset("coin", "res://assets/kenney/interface-sounds/pluck_001.wav") ## ShippingBinManager payout
	register_sfx_asset("harvest", "res://assets/kenney/interface-sounds/confirmation_001.wav") ## FarmPlotManager crop_harvested
	register_sfx_asset("heart", "res://assets/kenney/interface-sounds/bong_001.wav") ## RelationshipManager heart_event_triggered
	register_sfx_asset("wedding", "res://assets/kenney/interface-sounds/select_006.wav") ## MarriageManager married
	register_sfx_asset("levelup", "res://assets/kenney/interface-sounds/confirmation_002.wav") ## SkillManager level_changed
	register_sfx_asset("quest_complete", "res://assets/kenney/interface-sounds/glass_004.wav") ## QuestManager quest_completed
	register_sfx_asset("upgrade", "res://assets/kenney/interface-sounds/maximize_001.wav") ## ToolManager tool_upgraded
	register_music("ambient", 220.0) ## no fitting free music/loop found yet -- stays procedural, see file docstring

## --- Cross-manager signal wiring ---
## Read-only via public signals, same Backend contract every other manager
## follows (SQUAD-SPLIT.md) -- this file never reaches into another
## autoload's private state, only its emitted signals.

func _connect_signals() -> void:
	if ShippingBinManager:
		ShippingBinManager.payout_processed.connect(_on_payout_processed)
	if FarmPlotManager:
		FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	if RelationshipManager:
		RelationshipManager.heart_event_triggered.connect(_on_heart_event_triggered)
	if MarriageManager:
		MarriageManager.married.connect(_on_married)
	if SkillManager:
		SkillManager.level_changed.connect(_on_level_changed)
	if QuestManager:
		QuestManager.quest_completed.connect(_on_quest_completed)
	if ToolManager:
		ToolManager.tool_upgraded.connect(_on_tool_upgraded)

func _on_payout_processed(_total_earned: int, _item_count: int) -> void:
	play_sfx("coin")

func _on_crop_harvested(_position: Vector2i, _item_id: String, _quality: String, _quantity: int) -> void:
	play_sfx("harvest")

func _on_heart_event_triggered(_npc_name: String, _heart_level: int) -> void:
	play_sfx("heart")

func _on_married(_npc_name: String) -> void:
	play_sfx("wedding")

func _on_level_changed(_skill_name: String, _new_level: int, _old_level: int) -> void:
	play_sfx("levelup")

func _on_quest_completed(_quest_id: String, _unlock_flag: String) -> void:
	play_sfx("quest_complete")

func _on_tool_upgraded(_tool_name: String, _new_tier: int) -> void:
	play_sfx("upgrade")

## --- Public API ---

## Plays a registered one-shot SFX. Returns false (no-op) for an unknown
## id -- same "fail quiet, no crash" convention as e.g.
## InfrastructureManager.build_machine() on an unknown machine_type.
func play_sfx(sfx_id: String) -> bool:
	if not _sfx_defs.has(sfx_id):
		return false
	var def: Dictionary = _sfx_defs[sfx_id]
	if def["kind"] == "asset":
		_play_sfx_asset(def["stream"])
	else:
		_start_one_shot_tone(def["frequency"], def["duration"])
	sfx_played.emit(sfx_id)
	return true

## Stops any currently-playing one-shot SFX early and releases its
## AudioStreamGeneratorPlayback immediately, rather than waiting on the
## natural-duration timer _start_one_shot_tone() schedules. Symmetric
## with stop_music() -- a no-op if nothing is playing. Mainly useful for
## tests/shutdown paths that want a deterministic "nothing left playing"
## point without waiting out a real-time timer.
func stop_sfx() -> void:
	if _sfx_player.playing:
		_sfx_player.stop()

## Starts a registered looping "music" track. Re-calling with the track
## already playing is a no-op (fires no signal) -- same "only announce
## actual change" convention WeatherManager's weather_changed uses.
func play_music(track_id: String) -> bool:
	if not _music_defs.has(track_id):
		return false
	if _current_music_id == track_id and _music_player.playing:
		return true
	var def: Dictionary = _music_defs[track_id]
	_start_music_loop(def["frequency"])
	_current_music_id = track_id
	music_changed.emit(track_id)
	return true

func stop_music() -> void:
	if _current_music_id.is_empty():
		return
	_music_player.stop()
	_music_playback = null
	_current_music_id = ""
	music_stopped.emit()

func get_current_music() -> String:
	return _current_music_id

func is_sfx_registered(sfx_id: String) -> bool:
	return _sfx_defs.has(sfx_id)

func is_music_registered(track_id: String) -> bool:
	return _music_defs.has(track_id)

## --- Real-asset SFX playback ---

## A real AudioStream (e.g. a loaded WAV) has a genuine finite length, so
## unlike the procedural generator path below, AudioStreamPlayer.playing
## naturally goes false when it finishes -- no token/timer release dance
## needed here.
func _play_sfx_asset(stream: AudioStream) -> void:
	if _sfx_player.playing:
		_sfx_player.stop()
	_sfx_player.stream = stream
	_sfx_player.play()

## --- Procedural tone generation ---

func _start_one_shot_tone(frequency: float, duration: float) -> void:
	if _sfx_player.playing:
		## Same leak risk as _start_music_loop below -- stop any
		## still-playing one-shot before handing the player a fresh
		## stream/playback so the old AudioStreamGeneratorPlayback is
		## released instead of orphaned.
		_sfx_player.stop()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = GENERATOR_BUFFER_LENGTH
	_sfx_player.stream = gen
	_sfx_player.play()

	var playback := _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return ## no audio driver available (shouldn't happen even headless, but stay safe)

	var frame_count := int(MIX_RATE * duration)
	var increment := frequency / MIX_RATE
	var phase := 0.0
	for i in range(frame_count):
		var sample := sin(phase * TAU) * AMPLITUDE
		playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + increment, 1.0)

	## A generator stream has no inherent length, so AudioStreamPlayer's
	## own `finished` signal never fires for it -- without this, a
	## one-shot SFX stays "playing" (and its AudioStreamGeneratorPlayback
	## stays alive/leaked) forever unless another call happens to
	## supersede it. Explicitly release it once its synthesized duration
	## has actually had time to play out.
	_sfx_playback_token += 1
	var token := _sfx_playback_token
	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if token == _sfx_playback_token and _sfx_player.playing:
				_sfx_player.stop()
	)

func _start_music_loop(frequency: float) -> void:
	if _music_player.playing:
		## Switching tracks while one is already playing -- stop the old
		## player first so its AudioStreamGeneratorPlayback is released
		## before we hand the player a new stream, instead of leaking it.
		_music_player.stop()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = GENERATOR_BUFFER_LENGTH
	_music_player.stream = gen
	_music_player.play()

	_music_playback = _music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_music_phase = 0.0
	_music_frequency = frequency ## drives _process's continuous top-up below

## Keeps the looping "music" drone's buffer topped up -- an
## AudioStreamGeneratorPlayback buffer is finite, so a true loop needs
## fresh frames pushed every frame rather than one big upfront push (that
## works fine for short one-shot SFX above, not for something meant to
## play indefinitely).
func _process(_delta: float) -> void:
	if _music_playback == null or not _music_player.playing:
		return
	var to_fill := _music_playback.get_frames_available()
	var increment := _music_frequency / MIX_RATE
	for i in range(to_fill):
		var sample := sin(_music_phase * TAU) * AMPLITUDE
		_music_playback.push_frame(Vector2(sample, sample))
		_music_phase = fmod(_music_phase + increment, 1.0)
