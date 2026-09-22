# home_screen.gd — Main menu with animated logo, play button, and settings.
extends Control

@onready var _play_btn: Button = $Content/PlayButton
@onready var _settings_btn: Button = $TopBar/SettingsButton
@onready var _progress_label: Label = $Content/ProgressLabel
@onready var _title_label: Label = $Content/TitleLabel

var _pulse_tween: Tween = null


func _ready() -> void:
	if _play_btn:
		_play_btn.pressed.connect(_on_play_pressed)
	if _settings_btn:
		_settings_btn.pressed.connect(_on_settings_pressed)
	
	_update_progress()
	_animate_ui()


func _update_progress() -> void:
	var cur_lvl := SaveManager.get_current_level()
	var total_stars := 0
	for i in range(1, 21):
		total_stars += SaveManager.get_level_stars(i)
	if _progress_label:
		_progress_label.text = "Level %d Unlocked  •  ★ %d Stars" % [cur_lvl, total_stars]


func _animate_ui() -> void:
	if _play_btn:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(_play_btn, "scale", Vector2(1.06, 1.06), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_property(_play_btn, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_play_pressed() -> void:
	AudioManager.play_sfx_by_name("click")
	var tween := create_tween()
	tween.tween_property(_play_btn, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(_play_btn, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(func(): GameManager.go_to_level_map())


func _on_settings_pressed() -> void:
	AudioManager.play_sfx_by_name("click")
	GameManager.change_screen("settings")
