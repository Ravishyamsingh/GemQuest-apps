# settings_screen.gd — Player settings (sound, music, vibration toggles).
extends Control


func _ready() -> void:
	# Load current settings
	$VBoxContainer/SFXToggle.button_pressed = SaveManager.get_setting("sfx_enabled", true)
	$VBoxContainer/MusicToggle.button_pressed = SaveManager.get_setting("music_enabled", true)
	$VBoxContainer/VibrationToggle.button_pressed = SaveManager.get_setting("vibration_enabled", true)

	# Connect signals
	$VBoxContainer/SFXToggle.toggled.connect(_on_sfx_toggled)
	$VBoxContainer/MusicToggle.toggled.connect(_on_music_toggled)
	$VBoxContainer/VibrationToggle.toggled.connect(_on_vibration_toggled)
	$BackButton.pressed.connect(_on_back_pressed)


func _on_sfx_toggled(enabled: bool) -> void:
	SaveManager.update_setting("sfx_enabled", enabled)
	AudioManager.set_sfx_enabled(enabled)


func _on_music_toggled(enabled: bool) -> void:
	SaveManager.update_setting("music_enabled", enabled)
	AudioManager.set_music_enabled(enabled)


func _on_vibration_toggled(enabled: bool) -> void:
	SaveManager.update_setting("vibration_enabled", enabled)


func _on_back_pressed() -> void:
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")
