# level_map_screen.gd — Displays the scrollable level map with node states.
# Placeholder implementation — will be fully built in Phase 8.
extends Control


func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")
