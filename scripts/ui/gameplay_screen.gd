# gameplay_screen.gd — Main gameplay screen container.
# Placeholder — will host BoardManager, HUD, and overlays in Phase 2+.
extends Control


func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	GameManager.go_to_level_map()
