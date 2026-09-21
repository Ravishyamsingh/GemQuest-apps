# move_counter.gd — Tracks remaining moves for the current level.
# Decrements on valid swap. Emits moves_exhausted when reaching 0.
extends Node

var max_moves: int = 0
var remaining_moves: int = 0


func _ready() -> void:
	pass


## Initialise with the level's move count.
func setup(moves: int) -> void:
	max_moves = moves
	remaining_moves = moves
	EventBus.moves_changed.emit(remaining_moves)


## Consume one move (called on valid swap).
func use_move() -> void:
	remaining_moves -= 1
	EventBus.moves_changed.emit(remaining_moves)
	if remaining_moves <= 0:
		EventBus.moves_exhausted.emit()


## Reset to max.
func reset() -> void:
	remaining_moves = max_moves
	EventBus.moves_changed.emit(remaining_moves)


## Check if any moves remain.
func has_moves() -> bool:
	return remaining_moves > 0
