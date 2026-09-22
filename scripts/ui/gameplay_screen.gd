# gameplay_screen.gd — Main gameplay screen container.
# Hosts BoardManager, InputHandler, and HUD elements.
extends Control

var board_manager: Node2D = null
var input_handler: Node = null
var level_data_cache: Dictionary = {}

## Preload the board manager script
const BoardManagerScript = preload("res://scripts/core/board_manager.gd")
const InputHandlerScript = preload("res://scripts/core/input_handler.gd")
const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")

var _active_pause_menu: PauseMenu = null

## HUD references
@onready var _moves_label: Label = $HUD/TopBar/MovesLabel
@onready var _score_label: Label = $HUD/TopBar/ScoreLabel
@onready var _target_label: Label = $HUD/TopBar/TargetLabel
@onready var _level_label: Label = $HUD/TopBar/LevelLabel
@onready var _pause_button: Button = $HUD/TopBar/PauseButton


func _ready() -> void:
	# Create board manager
	board_manager = Node2D.new()
	board_manager.name = "BoardManager"
	board_manager.set_script(BoardManagerScript)
	add_child(board_manager)
	
	# Create input handler
	input_handler = Node.new()
	input_handler.name = "InputHandler"
	input_handler.set_script(InputHandlerScript)
	input_handler.board_manager = board_manager
	add_child(input_handler)
	
	# Connect HUD signals
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.moves_changed.connect(_on_moves_changed)
	EventBus.objective_progress.connect(_on_objective_progress)
	EventBus.level_won.connect(_on_level_won)
	EventBus.level_lost.connect(_on_level_lost)
	
	# Connect pause button
	if _pause_button:
		_pause_button.pressed.connect(_on_pause_pressed)
	
	# Load level data and start
	_start_level()


func _start_level() -> void:
	var level_data: Dictionary = {}
	level_data_cache = {}
	
	if GameManager.current_level_data != null and GameManager.current_level_data is Dictionary:
		level_data = GameManager.current_level_data
	else:
		# Fallback: load level 1 for testing
		level_data = LevelManager.get_level_data(1)
		if level_data.is_empty():
			# Ultimate fallback — hardcoded defaults
			level_data = {
				"level_id": 1,
				"grid_columns": 8,
				"grid_rows": 8,
				"max_moves": 25,
				"objective_type": "score_target",
				"target_score": 500,
				"available_piece_ids": ["diamond", "ruby", "sapphire", "emerald", "topaz", "amethyst"],
				"difficulty": 1,
			}
	
	# Cache for win/lose handlers
	level_data_cache = level_data
	
	# Update HUD
	var level_id: int = level_data.get("level_id", 1)
	if _level_label:
		_level_label.text = "Level %d" % level_id
	if _moves_label:
		_moves_label.text = "Moves: %d" % level_data.get("max_moves", 25)
	if _score_label:
		_score_label.text = "Score: 0"
	if _target_label:
		_target_label.text = "Target: %d" % level_data.get("target_score", 500)
	
	# Setup board
	board_manager.setup_board(level_data)


## HUD update callbacks
func _on_score_changed(new_score: int, _delta: int) -> void:
	if _score_label:
		_score_label.text = "Score: %d" % new_score


func _on_moves_changed(remaining: int) -> void:
	if _moves_label:
		_moves_label.text = "Moves: %d" % remaining


func _on_objective_progress(current: int, target: int) -> void:
	if _target_label:
		_target_label.text = "Target: %d/%d" % [current, target]


func _on_level_won() -> void:
	input_handler.input_enabled = false
	var level_id: int = level_data_cache.get("level_id", 1)
	var score: int = board_manager.score_manager_node.current_score
	var target_score: int = level_data_cache.get("target_score", 500)
	
	# Calculate stars (1-3)
	var stars := 1
	if score >= int(target_score * 1.8):
		stars = 3
	elif score >= int(target_score * 1.35):
		stars = 2
	
	# Save progress with stars
	SaveManager.complete_level(level_id, score, stars)
	
	# Show win overlay
	_show_overlay("VICTORY!", "Score: %d" % score, true, stars)


func _on_level_lost() -> void:
	input_handler.input_enabled = false
	var score: int = board_manager.score_manager_node.current_score
	
	# Show lose overlay
	_show_overlay("OUT OF MOVES", "Score: %d\nTry again!" % score, false, 0)


func _on_pause_pressed() -> void:
	if _active_pause_menu and is_instance_valid(_active_pause_menu):
		return
	
	if input_handler:
		input_handler.input_enabled = false
	
	_active_pause_menu = PauseMenuScene.instantiate()
	add_child(_active_pause_menu)
	_active_pause_menu.setup_and_show(level_data_cache)
	_active_pause_menu.resumed.connect(func():
		if input_handler:
			input_handler.input_enabled = true
		_active_pause_menu = null
	)
	_active_pause_menu.restarted.connect(func():
		_active_pause_menu = null
	)
	_active_pause_menu.quit_to_map.connect(func():
		_active_pause_menu = null
	)


## Create and show a result overlay (win or lose).
func _show_overlay(title_text: String, body_text: String, is_win: bool, stars: int = 0) -> void:
	# Dark background overlay
	var overlay := ColorRect.new()
	overlay.name = "ResultOverlay"
	overlay.color = Color(0.05, 0.03, 0.12, 0.85)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 520)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240
	panel.offset_top = -260
	panel.offset_right = 240
	panel.offset_bottom = 260
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set("theme_override_font_sizes/font_size", 40)
	title.set("theme_override_colors/font_color", Color(1.0, 0.85, 0.2) if is_win else Color(1.0, 0.35, 0.35))
	vbox.add_child(title)
	
	# Stars display on victory
	if is_win:
		var stars_box := HBoxContainer.new()
		stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_box.set("theme_override_constants/separation", 12)
		vbox.add_child(stars_box)
		
		var star_fill = load("res://assets/graphics/ui/star_filled.png") if ResourceLoader.exists("res://assets/graphics/ui/star_filled.png") else null
		var star_empty = load("res://assets/graphics/ui/star_empty.png") if ResourceLoader.exists("res://assets/graphics/ui/star_empty.png") else null
		
		for s in range(3):
			var tr := TextureRect.new()
			tr.custom_minimum_size = Vector2(48, 48)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture = star_fill if (s < stars) else star_empty
			stars_box.add_child(tr)
			
			if s < stars:
				tr.scale = Vector2.ZERO
				tr.pivot_offset = Vector2(24, 24)
				var tween := create_tween()
				tween.tween_property(tr, "scale", Vector2(1.2, 1.2), 0.25).set_delay(0.3 + s * 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(tr, "scale", Vector2(1.0, 1.0), 0.1)
	
	var body := Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.set("theme_override_font_sizes/font_size", 24)
	vbox.add_child(body)
	
	if is_win:
		var next_btn := Button.new()
		next_btn.text = "Next Level ▶"
		next_btn.custom_minimum_size = Vector2(220, 56)
		next_btn.set("theme_override_font_sizes/font_size", 22)
		next_btn.pressed.connect(func():
			var next_id: int = level_data_cache.get("level_id", 1) + 1
			var next_data := LevelManager.get_level_data(next_id)
			if not next_data.is_empty():
				LevelManager.start_level(next_id)
			else:
				GameManager.go_to_level_map()
		)
		vbox.add_child(next_btn)
	else:
		var retry_btn := Button.new()
		retry_btn.text = "Try Again ↺"
		retry_btn.custom_minimum_size = Vector2(220, 56)
		retry_btn.set("theme_override_font_sizes/font_size", 22)
		retry_btn.pressed.connect(func():
			var level_id: int = level_data_cache.get("level_id", 1)
			LevelManager.start_level(level_id)
		)
		vbox.add_child(retry_btn)
	
	var map_btn := Button.new()
	map_btn.text = "Level Map 🗺"
	map_btn.custom_minimum_size = Vector2(220, 56)
	map_btn.set("theme_override_font_sizes/font_size", 22)
	map_btn.pressed.connect(func(): GameManager.go_to_level_map())
	vbox.add_child(map_btn)
	
	# Animate card entry
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = Vector2(240, 260)
	overlay.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
