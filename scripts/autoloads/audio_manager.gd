# audio_manager.gd — Handles music and SFX playback with smart scene routing.
# Routes audio through separate buses and hooks directly into EventBus signals.
extends Node

## Audio bus names
const MUSIC_BUS := "Master"
const SFX_BUS := "Master"

## Internal players
var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

## Cached SFX streams
var _sfx_cache: Dictionary = {}

## State
var music_enabled: bool = true
var sfx_enabled: bool = true
var _current_bgm_track: String = ""

## Asset paths
const SOUND_PATHS := {
	"select": "res://assets/audio/sfx/gem_select.wav",
	"swap": "res://assets/audio/sfx/gem_swap.wav",
	"invalid": "res://assets/audio/sfx/gem_invalid.wav",
	"match": "res://assets/audio/sfx/gem_match.wav",
	"combo": "res://assets/audio/sfx/gem_combo.wav",
	"click": "res://assets/audio/sfx/button_click.wav",
	"star": "res://assets/audio/sfx/star_award.wav",
	"win": "res://assets/audio/sfx/level_win.wav",
	"lose": "res://assets/audio/sfx/level_lose.wav",
}
const BGM_GAMEPLAY_PATH := "res://assets/audio/music/bgm_gameplay.wav"
const BGM_MENU_PATH := "res://assets/audio/music/bgm_menu.wav"


func _ready() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	# Create SFX player pool
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)

	# Preload sounds
	_load_sound_assets()

	# Connect EventBus signals
	_connect_events()


func _load_sound_assets() -> void:
	for sound_key in SOUND_PATHS:
		var path: String = SOUND_PATHS[sound_key]
		if ResourceLoader.exists(path):
			_sfx_cache[sound_key] = load(path)


func _connect_events() -> void:
	if not Engine.has_singleton("EventBus") and not get_node_or_null("/root/EventBus"):
		return
	
	EventBus.piece_selected.connect(func(_pos: Vector2i): play_sfx_by_name("select"))
	EventBus.swap_completed.connect(func(_f: Vector2i, _t: Vector2i): play_sfx_by_name("swap"))
	EventBus.swap_rejected.connect(func(_f: Vector2i, _t: Vector2i): play_sfx_by_name("invalid"))
	EventBus.match_found.connect(_on_match_found)
	EventBus.cascade_step.connect(_on_cascade_step)
	EventBus.level_won.connect(_on_level_won)
	EventBus.level_lost.connect(_on_level_lost)
	EventBus.level_started.connect(_on_level_started)
	EventBus.screen_change_requested.connect(_on_screen_change_requested)


func _on_screen_change_requested(screen_name: String) -> void:
	match screen_name:
		"home", "level_map", "settings":
			play_menu_music()
		"gameplay":
			play_gameplay_music()


func _on_level_started(_level_id: int) -> void:
	play_gameplay_music()


func _on_level_won() -> void:
	stop_music(0.2)
	play_sfx_by_name("win")


func _on_level_lost() -> void:
	stop_music(0.2)
	play_sfx_by_name("lose")


func _on_match_found(_matches: Array) -> void:
	play_sfx_by_name("match")


func _on_cascade_step(depth: int) -> void:
	if depth > 1:
		play_sfx_by_name("combo")


## Play menu background music.
func play_menu_music(fade_in: float = 0.4) -> void:
	if _current_bgm_track == BGM_MENU_PATH and _music_player.playing:
		return
	if ResourceLoader.exists(BGM_MENU_PATH):
		_current_bgm_track = BGM_MENU_PATH
		var stream: AudioStream = load(BGM_MENU_PATH)
		play_music(stream, fade_in)


## Play gameplay background music.
func play_gameplay_music(fade_in: float = 0.4) -> void:
	if _current_bgm_track == BGM_GAMEPLAY_PATH and _music_player.playing:
		return
	if ResourceLoader.exists(BGM_GAMEPLAY_PATH):
		_current_bgm_track = BGM_GAMEPLAY_PATH
		var stream: AudioStream = load(BGM_GAMEPLAY_PATH)
		play_music(stream, fade_in)


## Play background music (loops).
func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if not music_enabled or stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = -80.0 if fade_in > 0.0 else 0.0
	_music_player.play()
	if fade_in > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", 0.0, fade_in)


## Stop music.
func stop_music(fade_out: float = 0.5) -> void:
	_current_bgm_track = ""
	if fade_out > 0.0 and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


## Play a one-shot SFX by name key.
func play_sfx_by_name(sound_name: String) -> void:
	if not sfx_enabled:
		return
	if _sfx_cache.has(sound_name):
		play_sfx(_sfx_cache[sound_name])


## Play a one-shot SFX stream.
func play_sfx(stream: AudioStream) -> void:
	if not sfx_enabled or stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return


## Toggle music on/off.
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		stop_music(0.0)
	elif not _music_player.playing:
		if GameManager.state == GameManager.GameState.GAMEPLAY:
			play_gameplay_music()
		else:
			play_menu_music()


## Toggle SFX on/off.
func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
