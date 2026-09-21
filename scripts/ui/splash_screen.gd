# splash_screen.gd — Displays the GemQuest logo for ~2 seconds, then transitions to Home.
extends Control

const SPLASH_DURATION := 2.0


func _ready() -> void:
	# Fade in the logo
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_interval(SPLASH_DURATION - 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_go_to_home)


func _go_to_home() -> void:
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")
