# board_manager.gd — Orchestrates the gameplay loop on the board.
# Owns GridController, InputHandler, MatchDetector, CascadeResolver.
# Manages board state machine: IDLE → INPUT → SWAPPING → MATCHING → CASCADING → CHECK_END
extends Node2D

enum BoardState { INITIALIZING, IDLE, INPUT, SWAPPING, MATCHING, CASCADING, CHECK_END, WIN, LOSE }

var state: BoardState = BoardState.INITIALIZING
var level_data: Dictionary = {}

## Child system references (assigned in _ready or via @onready)
var grid_controller = null
var input_handler = null
var match_detector = null
var cascade_resolver = null
var score_manager = null
var objective_tracker = null
var move_counter = null


func _ready() -> void:
	pass  # Will be wired up in Phase 2


## Initialise the board with level data.
func setup_board(data: Dictionary) -> void:
	level_data = data
	state = BoardState.INITIALIZING
	# Phase 2: create grid, spawn pieces, validate no initial matches
	state = BoardState.IDLE
	EventBus.board_ready.emit()


## Main gameplay state machine — called after each action resolves.
func _advance_state() -> void:
	match state:
		BoardState.IDLE:
			pass  # Waiting for player input
		BoardState.MATCHING:
			pass  # Phase 3: detect matches
		BoardState.CASCADING:
			pass  # Phase 4: remove → fall → refill → re-check
		BoardState.CHECK_END:
			pass  # Phase 5: check win/lose conditions
		BoardState.WIN:
			EventBus.level_won.emit()
		BoardState.LOSE:
			EventBus.level_lost.emit()
