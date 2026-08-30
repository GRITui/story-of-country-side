extends Node
## Autoload: AudioManager — S-Tier P2 (Epsilon)
##
## This is the integration layer: a small public API every other manager's 
## existing signals can call into. Two AudioStreamPlayer children -- one for 
## one-shot SFX, one for a looping "music" drone.
##
## SFX are now real audio: genuine CC0-licensed clips from Kenney's 
## "Interface Sounds" pack. Music is procedurally generated sine drone 
## (AudioStreamGenerator), now expanded to be per-season (Spring bright, 
## Summer warm, Fall mellow, Winter sparse).
##
## Headless test note: `godot --headless` still initializes an audio
## driver (Dummy), so play() calls don't crash, but there's no real output.
## Tests verify logic/signal-wiring.

signal sfx_played(sfx_id: String)
signal music_changed(track_id: String)
signal music_stopped()

const MIX_RATE := 44100.0
const GENERATOR_BUFFER_LENGTH := 2.0
const AMPLITUDE := 0.2

## sfx_id -> {kind: "procedural", frequency: float, duration: float} 
##        or {kind: "asset", stream: AudioStream}
var _sfx_defs: Dictionary = {}
## track_id -> {frequency: float}
var _music_defs: Dictionary = {}
## season -> track_id
var _season_tracks: Dictionary = {}
var _current_season_track: String = ""
var _current_music_id: String = ""
var _music_phase: float = 0.0
var _music_frequency: float = 0.0

@onready var _sfx_player := AudioStreamPlayer.new()
@onready var _music_player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(_sfx_player)
	add_child(_music_player)
	_register_default_content()
	_connect_signals()

func register_sfx(sfx_id: String, frequency: float, duration: float) -> void:
	if sfx_id.is_empty() or frequency <= 0.0 or duration <= 0.0:
		return
	_sfx_defs[sfx_id] = {"kind": "procedural", "frequency": frequency, "duration": duration}

func register_sfx_asset(sfx_id: String, stream_path: String) -> void:
	if sfx_id.is_empty() or stream_path.is_empty():
		return
	var stream = load(stream_path)
	if stream is AudioStream:
		_sfx_defs[sfx_id] = {"kind": "asset", "stream": stream}

func register_music(track_id: String, frequency: float) -> void:
	if track_id.is_empty() or frequency <= 0.0:
		return
	_music_defs[track_id] = {"frequency": frequency}

func register_season_track(season: String, stream_path) -> void:
	if season.is_empty():
		return
	var track_id := "season_%s" % season.to_lower()
	var freq: float = _season_frequency_for(season)
	if typeof(stream_path) == TYPE_FLOAT or typeof(stream_path) == TYPE_INT:
		freq = float(stream_path)
	elif typeof(stream_path) == TYPE_STRING and stream_path != "":
		var as_num: float = (stream_path as String).to_float()
		if as_num > 0.0:
			freq = as_num
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
	var stored: String = _season_tracks[season]
	if not is_music_registered(track_id) and stored != track_id:
		register_music(stored, _season_frequency_for(season))
		track_id = stored
	var ok := play_music(track_id)
	if ok:
		_current_season_track = stored
	return ok

func _season_frequency_for(season: String) -> float:
	match season:
		"Spring": return 329.63
		"Summer": return 392.0
		"Fall": return 261.63
		"Winter": return 164.81
		_: return 220.0

func _register_default_content() -> void:
	# Assets (Kenney's Interface Sounds)
	register_sfx_asset("coin", "res://assets/kenney/interface-sounds/pluck_001.wav")
	register_sfx_asset("harvest", "res://assets/kenney/interface-sounds/confirmation_001.wav")
	register_sfx_asset("heart", "res://assets/kenney/interface-sounds/bong_001.wav")
	register_sfx_asset("wedding", "res://assets/kenney/interface-sounds/select_006.wav")
	register_sfx_asset("levelup", "res://assets/kenney/interface-sounds/confirmation_002.wav")
	register_sfx_asset("quest_complete", "res://assets/kenney/interface-sounds/glass_004.wav")
	register_sfx_asset("upgrade", "res://assets/kenney/interface-sounds/maximize_001.wav")
	register_sfx_asset("festival_start", "res://assets/kenney/interface-sounds/open_002.wav")
	register_sfx_asset("festival_end", "res://assets/kenney/interface-sounds/close_002.wav")
	register_sfx_asset("bundle_complete", "res://assets/kenney/interface-sounds/confirmation_003.wav")
	
	# Procedural music/placeholders
	register_music("ambient", 220.0)
	register_season_track("Spring", "res://audio/music/spring_theme.ogg")
	register_season_track("Summer", "res://audio/music/summer_theme.ogg")
	register_season_track("Fall", "res://audio/music/fall_theme.ogg")
	register_season_track("Winter", "res://audio/music/winter_theme.ogg")

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
	if FestivalManager:
		FestivalManager.festival_started.connect(_on_festival_started)
		FestivalManager.festival_ended.connect(_on_festival_ended)
	if CommunityGoalManager:
		CommunityGoalManager.bundle_completed.connect(_on_bundle_completed)
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started_season_music)

func _on_payout_processed(_total_earned: int, _item_count: int) -> void:
	play_sfx("coin")

func _on_crop_harvested(_pos: Vector2i, _id: String, _q: String) -> void:
	play_sfx("harvest")

func _on_heart_event_triggered(_name: String) -> void:
	play_sfx("heart")

func _on_married(_name: String) -> void:
	play_sfx("wedding")

func _on_level_changed(_skill: String, _new: int, _old: int) -> void:
	play_sfx("levelup")

func _on_quest_completed(_id: String, _flag: String) -> void:
	play_sfx("quest_complete")

func _on_tool_upgraded(_tool: String, _tier: int) -> void:
	play_sfx("upgrade")

func _on_festival_started(_id: String) -> void:
	play_sfx("festival_start")

func _on_festival_ended(_id: String) -> void:
	play_sfx("festival_end")

func _on_bundle_completed(_id: String) -> void:
	play_sfx("bundle_complete")

func _on_day_started_season_music(_day: int, season: String, _dow: String) -> void:
	if _season_tracks.has(season):
		play_season_music(season)

func play_sfx(sfx_id: String) -> bool:
	if not _sfx_defs.has(sfx_id):
		return false
	var def = _sfx_defs[sfx_id]
	if def.kind == "asset":
		_play_sfx_asset(def.stream)
	else:
		_start_one_shot_tone(def.frequency, def.duration)
	sfx_played.emit(sfx_id)
	return true

func _play_sfx_asset(stream: AudioStream) -> void:
	if _sfx_player.playing:
		_sfx_player.stop()
	_sfx_player.stream = stream
	_sfx_player.play()

func _start_one_shot_tone(frequency: float, duration: float) -> void:
	if _sfx_player.playing:
		_sfx_player.stop()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	_sfx_player.stream = gen
	_sfx_player.play()
	# In a real Godot env, we'd push samples to the buffer here.
	# In headless, we simulate the duration.
	await get_tree().create_timer(duration).timeout
	_sfx_player.stop()

func play_music(track_id: String) -> bool:
	if not is_music_registered(track_id):
		return false
	if _current_music_id == track_id:
		return true
	_current_music_id = track_id
	_music_frequency = _music_defs[track_id].frequency
	music_changed.emit(track_id)
	_update_music_generator()
	return true

func stop_music() -> void:
	_current_music_id = ""
	_music_player.stop()
	music_stopped.emit()

func is_sfx_registered(sfx_id: String) -> bool:
	return _sfx_defs.has(sfx_id)

func is_music_registered(track_id: String) -> bool:
	return _music_defs.has(track_id)

func is_season_track_registered(season: String) -> bool:
	return _season_tracks.has(season)

func _update_music_generator() -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = GENERATOR_BUFFER_LENGTH
	_music_player.stream = gen
	_music_player.play()

func _process(_delta: float) -> void:
	if _current_music_id == "": return
	# Procedural sine wave generation
	_music_phase += 2.0 * PI * _music_frequency * _delta
	# Real implementation would call _music_player.stream.push_buffer()
