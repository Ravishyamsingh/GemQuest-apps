# settings_screen.gd — Player settings (sound, music, vibration toggles, reset progress).
extends Control

@onready var _sfx_toggle: CheckButton = $Panel/VBoxContainer/SFXRow/SFXToggle
@onready var _music_toggle: CheckButton = $Panel/VBoxContainer/MusicRow/MusicToggle
@onready var _vibration_toggle: CheckButton = $Panel/VBoxContainer/VibRow/VibrationToggle
@onready var _reset_btn: Button = $Panel/VBoxContainer/ResetButton
@onready var _back_btn: Button = $TopBar/BackButton


func _ready() -> void:
	# Load current settings
	if _sfx_toggle:
		_sfx_toggle.button_pressed = SaveManager.get_setting("sfx_enabled", true)
		_sfx_toggle.toggled.connect(_on_sfx_toggled)
	if _music_toggle:
		_music_toggle.button_pressed = SaveManager.get_setting("music_enabled", true)
		_music_toggle.toggled.connect(_on_music_toggled)
	if _vibration_toggle:
		_vibration_toggle.button_pressed = SaveManager.get_setting("vibration_enabled", true)
		_vibration_toggle.toggled.connect(_on_vibration_toggled)
	
	if _reset_btn:
		_reset_btn.pressed.connect(_on_reset_pressed)
	if _back_btn:
		_back_btn.pressed.connect(_on_back_pressed)


func _on_sfx_toggled(enabled: bool) -> void:
	SaveManager.update_setting("sfx_enabled", enabled)
	AudioManager.set_sfx_enabled(enabled)
	if enabled:
		AudioManager.play_sfx_by_name("click")


func _on_music_toggled(enabled: bool) -> void:
	SaveManager.update_setting("music_enabled", enabled)
	AudioManager.set_music_enabled(enabled)


func _on_vibration_toggled(enabled: bool) -> void:
	SaveManager.update_setting("vibration_enabled", enabled)


func _on_reset_pressed() -> void:
	SaveManager.reset_progress()
	if _reset_btn:
		_reset_btn.text = "Progress Reset! ✓"
		var timer := get_tree().create_timer(1.5)
		timer.timeout.connect(func(): if _reset_btn: _reset_btn.text = "Reset Progress")


func _on_back_pressed() -> void:
	AudioManager.play_sfx_by_name("click")
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")
