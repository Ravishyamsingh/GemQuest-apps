# gameplay_screen.gd — Main gameplay screen container.
# Hosts BoardManager, InputHandler, and HUD elements.
extends Control

var board_manager: Node2D = null
var input_handler: Node = null
var level_data_cache: Dictionary = {}

## Preload the board manager script
const BoardManagerScript = preload("res://scripts/core/board_manager.gd")
const InputHandlerScript = preload("res://scripts/core/input_handler.gd")

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
	
	# Save progress
	SaveManager.complete_level(level_id, score)
	
	# Show win overlay
	_show_overlay("LEVEL COMPLETE!", "Score: %d" % score, true)


func _on_level_lost() -> void:
	input_handler.input_enabled = false
	var score: int = board_manager.score_manager_node.current_score
	
	# Show lose overlay
	_show_overlay("OUT OF MOVES", "Score: %d\nTry again!" % score, false)


func _on_pause_pressed() -> void:
	GameManager.go_to_level_map()


## Create and show a result overlay (win or lose).
func _show_overlay(title_text: String, body_text: String, is_win: bool) -> void:
	# Dark background overlay
	var overlay := ColorRect.new()
	overlay.name = "ResultOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)
	
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -150
	vbox.offset_top = -120
	vbox.offset_right = 150
	vbox.offset_bottom = 120
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 20)
	overlay.add_child(vbox)
	
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var body := Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(body)
	
	if is_win:
		var next_btn := Button.new()
		next_btn.text = "Next Level"
		next_btn.custom_minimum_size = Vector2(180, 50)
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
		retry_btn.text = "Retry"
		retry_btn.custom_minimum_size = Vector2(180, 50)
		retry_btn.pressed.connect(func():
			var level_id: int = level_data_cache.get("level_id", 1)
			LevelManager.start_level(level_id)
		)
		vbox.add_child(retry_btn)
	
	var map_btn := Button.new()
	map_btn.text = "Level Map"
	map_btn.custom_minimum_size = Vector2(180, 50)
	map_btn.pressed.connect(func(): GameManager.go_to_level_map())
	vbox.add_child(map_btn)
	
	# Fade in
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
