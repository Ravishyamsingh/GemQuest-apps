# level_map_screen.gd — Displays the scrollable level map with level nodes.
# For Phase 2 testing: shows a simple list of playable levels.
# Full curved-path map will be built in Phase 8.
extends Control


func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	_build_level_list()


func _on_back_pressed() -> void:
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")


## Build a simple vertical list of level buttons for testing.
func _build_level_list() -> void:
	var container := $ScrollContainer/VBoxContainer
	
	# Clear any existing children
	for child in container.get_children():
		child.queue_free()
	
	var total_levels := LevelManager.get_total_levels()
	if total_levels == 0:
		total_levels = 20  # Fallback
	
	for i in range(1, total_levels + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 50)
		
		var is_unlocked := SaveManager.is_level_unlocked(i)
		var is_completed := SaveManager.is_level_completed(i)
		var is_current := (i == SaveManager.get_current_level())
		
		if is_completed:
			btn.text = "★ Level %d — %d pts" % [i, SaveManager.get_best_score(i)]
		elif is_current:
			btn.text = "▶ Level %d" % i
		elif is_unlocked:
			btn.text = "Level %d" % i
		else:
			btn.text = "🔒 Level %d" % i
			btn.disabled = true
		
		var level_id := i  # Capture for lambda
		btn.pressed.connect(func(): _on_level_pressed(level_id))
		container.add_child(btn)


func _on_level_pressed(level_id: int) -> void:
	LevelManager.start_level(level_id)
