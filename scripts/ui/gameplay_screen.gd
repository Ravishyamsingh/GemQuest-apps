# gameplay_screen.gd — Main gameplay screen container.
# Hosts BoardManager, InputHandler, and HUD elements.
extends Control

var board_manager: Node2D = null
var input_handler: Node = null

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
	# Show win overlay (placeholder for now)
	print("LEVEL WON!")


func _on_level_lost() -> void:
	# Show lose overlay (placeholder for now)
	print("LEVEL LOST!")


func _on_pause_pressed() -> void:
	GameManager.go_to_level_map()
