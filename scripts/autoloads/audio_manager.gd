# audio_manager.gd — Handles music and SFX playback.
# Provides simple play/stop API; routes audio through separate buses
# so music and SFX volumes can be controlled independently.
extends Node

## Audio bus names (must match the buses configured in Godot's Audio tab).
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## Internal players
var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8  # Pool of SFX players for overlapping sounds

## Cached SFX streams (preloaded)
var _sfx_cache: Dictionary = {}

## State
var music_enabled: bool = true
var sfx_enabled: bool = true


func _ready() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"  # Will use Music bus once configured
	add_child(_music_player)

	# Create SFX player pool
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"  # Will use SFX bus once configured
		add_child(player)
		_sfx_players.append(player)


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
	if fade_out > 0.0 and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


## Play a one-shot SFX.
func play_sfx(stream: AudioStream) -> void:
	if not sfx_enabled or stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# All players busy — skip this SFX (graceful degradation)


## Toggle music on/off.
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		stop_music(0.0)


## Toggle SFX on/off.
func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
