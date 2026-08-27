extends Node
## Autoload: AudioManager — S-Tier P2 (Epsilon)
##
## Seasonal music expansion per #113 + festival jingle trigger.
## Previously a single "ambient" sine drone (220 Hz). Now per-season
## placeholder streams: Spring bright, Summer warm, Fall mellow, Winter
## sparse — still procedural sine via AudioStreamGenerator, but distinct
## per season so seasonal transitions read audibly without requiring an
## external asset pipeline. Keeps the original leak fixes from PR #80
## (stop-before-reassign + sfx token guard).
##
## New seasonal API:
##   register_season_track(season, stream_path_or_frequency)
##   get_current_season_track() -> String
##   play_season_music(season) -> bool
##
## Festival jingle: when FestivalManager emits festival_started, a short
## chime fires automatically (read-only signal wiring, same Backend
## contract every manager follows).

signal sfx_played(sfx_id: String)
signal music_changed(track_id: String)
signal music_stopped()

const MIX_RATE := 44100.0
const GENERATOR_BUFFER_LENGTH := 2.0
const AMPLITUDE := 0.2

## sfx_id -> {frequency: float, duration: float}
var _sfx_defs: Dictionary = {}
## track_id -> {frequency: float}
var _music_defs: Dictionary = {}

## season -> track_id (registered via register_season_track)
var _season_tracks: Dictionary = {}
var _current_season_track: String = ""

var _current_music_id: String = ""
var _music_phase: float = 0.0
var _music_frequency: float = 0.0
var _music_playback: AudioStreamGeneratorPlayback

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

## --- Content registration ----------------------------------------

func register_sfx(sfx_id: String, frequency: float, duration: float) -> void:
	if sfx_id.is_empty() or frequency <= 0.0 or duration <= 0.0:
		return
	_sfx_defs[sfx_id] = {"frequency": frequency, "duration": duration}

func register_music(track_id: String, frequency: float) -> void:
	if track_id.is_empty() or frequency <= 0.0:
		return
	_music_defs[track_id] = {"frequency": frequency}

## Seasonal music API per #113.
## stream_path is kept as a String identifier for future asset-pipeline
## replacement; procedurally it maps to a per-season sine frequency so
## every season sounds distinct today without requiring external .ogg
## imports. If `stream_path` looks numeric, it is treated as a direct
## frequency; otherwise it is hashed to a frequency in the seasonal
## band. Passing a float directly is also supported.
func register_season_track(season: String, stream_path) -> void:
	if season.is_empty():
		return
	var track_id := "season_%s" % season.to_lower()
	var freq: float = _season_frequency_for(season)
	# If the caller passed an explicit numeric path/frequency, honour it.
	if typeof(stream_path) == TYPE_FLOAT or typeof(stream_path) == TYPE_INT:
		freq = float(stream_path)
	elif typeof(stream_path) == TYPE_STRING and stream_path != "":
		var as_num: float = (stream_path as String).to_float()
		if as_num > 0.0:
			freq = as_num
		# Otherwise keep seasonal default; store the path string as the
		# track's logical identifier for get_current_season_track().
		_season_tracks[season] = stream_path if stream_path != "" else track_id
		register_music(track_id, freq)
		return
	_season_tracks[season] = track_id
	register_music(track_id, freq)

func get_current_season_track() -> String:
	return _current_season_track

func play_season_music(season: String) -> bool:
	if not _season_tracks.has(season):
		return false
	var track_id := "season_%s" % season.to_lower()
	# Also allow raw string paths that were registered as-is.
	var stored: String = _season_tracks[season]
	if not is_music_registered(track_id) and stored != track_id:
		# Caller registered a raw asset path — ensure we have a
		# procedural stand-in for it so play_music has something to play.
		# (Real asset pipeline will replace this branch.)
		register_music(stored, _season_frequency_for(season))
		track_id = stored
	var ok := play_music(track_id)
	if ok:
		_current_season_track = stored
	return ok

## Deterministic per-season placeholder frequencies.
## Spring bright (higher), Summer warm (mid-high), Fall mellow (mid),
## Winter sparse (low). All within a pleasant 150–350 Hz band.
func _season_frequency_for(season: String) -> float:
	match season:
		"Spring": return 329.63  # E4 — bright
		"Summer": return 392.0   # G4 — warm
		"Fall": return 261.63    # C4 — mellow
		"Winter": return 164.81  # E3 — sparse/low
		_: return 220.0

func _register_default_content() -> void:
	register_sfx("coin", 880.0, 0.12)
	register_sfx("harvest", 660.0, 0.15)
	register_sfx("heart", 1046.5, 0.25)
	register_sfx("wedding", 523.25, 0.6)
	register_sfx("festival_jingle", 783.99, 0.45)
	register_music("ambient", 220.0)
	# Per-season procedural placeholder tracks — Decision E art direction
	# wants seasonal identity even before a composer lands.
	register_season_track("Spring", "res://audio/music/spring_theme.ogg")
	register_season_track("Summer", "res://audio/music/summer_theme.ogg")
	register_season_track("Fall", "res://audio/music/fall_theme.ogg")
	register_season_track("Winter", "res://audio/music/winter_theme.ogg")
	# Also register the bare season track_ids with their seasonal
	# frequencies so play_music("season_spring") etc. work directly.
	# register_season_track already does this; no extra work needed.

## --- Cross-manager signal wiring ---------------------------------

func _connect_signals() -> void:
	if ShippingBinManager:
		ShippingBinManager.payout_processed.connect(_on_payout_processed)
	if FarmPlotManager:
		FarmPlotManager.crop_harvested.connect(_on_crop_harvested)
	if RelationshipManager:
		RelationshipManager.heart_event_triggered.connect(_on_heart_event_triggered)
	if MarriageManager:
		MarriageManager.married.connect(_on_married)
	if FestivalManager:
		FestivalManager.festival_started.connect(_on_festival_started)
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started_season_music)

func _on_payout_processed(_total_earned: int, _item_count: int) -> void:
	play_sfx("coin")

func _on_crop_harvested(_position: Vector2i, _item_id: String, _quality: String, _quantity: int) -> void:
	play_sfx("harvest")

func _on_heart_event_triggered(_npc_name: String, _heart_level: int) -> void:
	play_sfx("heart")

func _on_married(_npc_name: String) -> void:
	play_sfx("wedding")

func _on_festival_started(_festival_id: String) -> void:
	play_sfx("festival_jingle")

func _on_day_started_season_music(_day: int, season: String, _dow: String) -> void:
	# Auto-switch seasonal music on day rollover if a track exists.
	# No-op (no signal) when the same season's track is already playing.
	if _season_tracks.has(season):
		play_season_music(season)

## --- Public API --------------------------------------------------

func play_sfx(sfx_id: String) -> bool:
	if not _sfx_defs.has(sfx_id):
		return false
	var def: Dictionary = _sfx_defs[sfx_id]
	_start_one_shot_tone(def["frequency"], def["duration"])
	sfx_played.emit(sfx_id)
	return true

func stop_sfx() -> void:
	if _sfx_player.playing:
		_sfx_player.stop()

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
	_current_season_track = ""
	music_stopped.emit()

func get_current_music() -> String:
	return _current_music_id

func is_sfx_registered(sfx_id: String) -> bool:
	return _sfx_defs.has(sfx_id)

func is_music_registered(track_id: String) -> bool:
	return _music_defs.has(track_id)

## Also expose seasonal helpers for tests.
func is_season_track_registered(season: String) -> bool:
	return _season_tracks.has(season)

## --- Procedural tone generation ----------------------------------

func _start_one_shot_tone(frequency: float, duration: float) -> void:
	if _sfx_player.playing:
		_sfx_player.stop()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = GENERATOR_BUFFER_LENGTH
	_sfx_player.stream = gen
	_sfx_player.play()

	var playback := _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frame_count := int(MIX_RATE * duration)
	var increment := frequency / MIX_RATE
	var phase := 0.0
	for i in range(frame_count):
		var sample := sin(phase * TAU) * AMPLITUDE
		playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + increment, 1.0)

	_sfx_playback_token += 1
	var token := _sfx_playback_token
	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if token == _sfx_playback_token and _sfx_player.playing:
				_sfx_player.stop()
	)

func _start_music_loop(frequency: float) -> void:
	if _music_player.playing:
		_music_player.stop()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = GENERATOR_BUFFER_LENGTH
	_music_player.stream = gen
	_music_player.play()

	_music_playback = _music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_music_phase = 0.0
	_music_frequency = frequency

func _process(_delta: float) -> void:
	if _music_playback == null or not _music_player.playing:
		return
	var to_fill := _music_playback.get_frames_available()
	var increment := _music_frequency / MIX_RATE
	for i in range(to_fill):
		var sample := sin(_music_phase * TAU) * AMPLITUDE
		_music_playback.push_frame(Vector2(sample, sample))
		_music_phase = fmod(_music_phase + increment, 1.0)
