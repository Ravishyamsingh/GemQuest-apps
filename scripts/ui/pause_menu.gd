# pause_menu.gd — In-game pause modal with resume, restart, settings, and quit.
class_name PauseMenu
extends Control

signal resumed()
signal restarted()
signal quit_to_map()

@onready var _backdrop: ColorRect = $Backdrop
@onready var _panel: PanelContainer = $Panel
@onready var _level_label: Label = $Panel/MarginContainer/VBoxContainer/LevelLabel
@onready var _resume_btn: Button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var _restart_btn: Button = $Panel/MarginContainer/VBoxContainer/RestartButton
@onready var _sfx_toggle: CheckButton = $Panel/MarginContainer/VBoxContainer/AudioToggles/SFXToggle
@onready var _music_toggle: CheckButton = $Panel/MarginContainer/VBoxContainer/AudioToggles/MusicToggle
@onready var _map_btn: Button = $Panel/MarginContainer/VBoxContainer/MapButton

var _level_id: int = 1
var _is_closing: bool = false


func _ready() -> void:
	if _resume_btn:
		_resume_btn.pressed.connect(_on_resume_pressed)
	if _restart_btn:
		_restart_btn.pressed.connect(_on_restart_pressed)
	if _map_btn:
		_map_btn.pressed.connect(_on_map_pressed)
	if _sfx_toggle:
		_sfx_toggle.button_pressed = SaveManager.get_setting("sfx_enabled", true)
		_sfx_toggle.toggled.connect(_on_sfx_toggled)
	if _music_toggle:
		_music_toggle.button_pressed = SaveManager.get_setting("music_enabled", true)
		_music_toggle.toggled.connect(_on_music_toggled)


func setup_and_show(level_data: Dictionary) -> void:
	_level_id = level_data.get("level_id", 1)
	_is_closing = false
	
	if _level_label:
		_level_label.text = "Level %d" % _level_id
	
	if _sfx_toggle:
		_sfx_toggle.button_pressed = SaveManager.get_setting("sfx_enabled", true)
	if _music_toggle:
		_music_toggle.button_pressed = SaveManager.get_setting("music_enabled", true)
	
	GameManager.state = GameManager.GameState.PAUSED
	EventBus.game_paused.emit()
	
	# Duck gameplay music volume
	_duck_bgm(true)
	
	# Pop in animation
	visible = true
	modulate.a = 0.0
	_panel.scale = Vector2(0.75, 0.75)
	_panel.pivot_offset = _panel.size * 0.5
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if AudioManager:
		AudioManager.play_sfx_by_name("click")


func _duck_bgm(duck: bool) -> void:
	if AudioManager and AudioManager._music_player and AudioManager._music_player.playing:
		var target_db := -12.0 if duck else 0.0
		var tween := create_tween()
		tween.tween_property(AudioManager._music_player, "volume_db", target_db, 0.25)


func _on_resume_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	_duck_bgm(false)
	GameManager.state = GameManager.GameState.GAMEPLAY
	EventBus.game_resumed.emit()
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	resumed.emit()
	queue_free()


func _on_restart_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	_duck_bgm(false)
	GameManager.state = GameManager.GameState.GAMEPLAY
	EventBus.level_restarted.emit()
	restarted.emit()
	LevelManager.start_level(_level_id)
	queue_free()


func _on_map_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	_duck_bgm(false)
	quit_to_map.emit()
	GameManager.go_to_level_map()
	queue_free()


func _on_sfx_toggled(enabled: bool) -> void:
	SaveManager.update_setting("sfx_enabled", enabled)
	AudioManager.set_sfx_enabled(enabled)
	if enabled:
		AudioManager.play_sfx_by_name("click")


func _on_music_toggled(enabled: bool) -> void:
	SaveManager.update_setting("music_enabled", enabled)
	AudioManager.set_music_enabled(enabled)
