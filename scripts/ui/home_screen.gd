# home_screen.gd — Main menu with Play and Settings buttons.
extends Control


func _ready() -> void:
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$SettingsButton.pressed.connect(_on_settings_pressed)


func _on_play_pressed() -> void:
	GameManager.go_to_level_map()


func _on_settings_pressed() -> void:
	GameManager.change_screen("settings")
