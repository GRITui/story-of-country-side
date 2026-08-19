extends Node
## Autoload: AudioManager
##
## Honesty up front: this repo had zero audio anywhere before this file --
## no music, no SFX, no AudioStreamPlayer usage. There is no music-
## composition or audio-synthesis tool available in this environment, so
## nothing here is a real composed track or a designed sound effect.
## Every "sound" below is a procedurally generated sine tone (frequency +
## duration), built at runtime via AudioStreamGenerator/
## AudioStreamGeneratorPlayback -- crude, audibly a beep/chime, not
## placeholder silence. This project genuinely needs a real composer/
## sound designer (or a licensed SFX/music library) before shipping;
## flagged to the Studio Head separately rather than pretending these
## tones are final audio.
##
## This is the integration *layer*: a small public API every other
## manager's existing signals can call into. Two AudioStreamPlayer
## children -- one for one-shot SFX, one for a looping "music" drone --
## same "autoload owns its own Node children" pattern SaveManager/
## TimeManager use for their own bookkeeping.
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

## sfx_id -> {frequency: float, duration: float}
var _sfx_defs: Dictionary = {}
## track_id -> {frequency: float}
var _music_defs: Dictionary = {}

var _current_music_id: String = ""
var _music_phase: float = 0.0
var _music_frequency: float = 0.0
var _music_playback: AudioStreamGeneratorPlayback

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
## Placeholder MVP tone table -- same "content-gap honesty" convention
## every other manager's _register_default_content() uses (see e.g.
## infrastructure_manager.gd). Re-registering an id overwrites it.

func register_sfx(sfx_id: String, frequency: float, duration: float) -> void:
	if sfx_id.is_empty() or frequency <= 0.0 or duration <= 0.0:
		return
	_sfx_defs[sfx_id] = {"frequency": frequency, "duration": duration}

func register_music(track_id: String, frequency: float) -> void:
	if track_id.is_empty() or frequency <= 0.0:
		return
	_music_defs[track_id] = {"frequency": frequency}

func _register_default_content() -> void:
	register_sfx("coin", 880.0, 0.12) ## ShippingBinManager payout
	register_sfx("harvest", 660.0, 0.15) ## FarmPlotManager crop_harvested
	register_sfx("heart", 1046.5, 0.25) ## RelationshipManager heart_event_triggered
	register_sfx("wedding", 523.25, 0.6) ## MarriageManager married
	register_music("ambient", 220.0) ## simple sustained drone, not a composed loop

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

func _on_payout_processed(_total_earned: int, _item_count: int) -> void:
	play_sfx("coin")

func _on_crop_harvested(_position: Vector2i, _item_id: String, _quality: String, _quantity: int) -> void:
	play_sfx("harvest")

func _on_heart_event_triggered(_npc_name: String, _heart_level: int) -> void:
	play_sfx("heart")

func _on_married(_npc_name: String) -> void:
	play_sfx("wedding")

## --- Public API ---

## Plays a registered one-shot SFX. Returns false (no-op) for an unknown
## id -- same "fail quiet, no crash" convention as e.g.
## InfrastructureManager.build_machine() on an unknown machine_type.
func play_sfx(sfx_id: String) -> bool:
	if not _sfx_defs.has(sfx_id):
		return false
	var def: Dictionary = _sfx_defs[sfx_id]
	_start_one_shot_tone(def["frequency"], def["duration"])
	sfx_played.emit(sfx_id)
	return true

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

## --- Procedural tone generation ---

func _start_one_shot_tone(frequency: float, duration: float) -> void:
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

func _start_music_loop(frequency: float) -> void:
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
