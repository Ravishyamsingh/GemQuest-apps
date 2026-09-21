# input_handler.gd — Handles touch/click input for piece selection and swaps.
# Emits swap_requested via EventBus. Disabled when board is not in IDLE state.
extends Node

## Whether input is currently accepted
var input_enabled: bool = false

## Currently selected piece position (or null/invalid)
var selected_position: Vector2i = Vector2i(-1, -1)

## Reference to grid controller for coordinate conversion
var grid_controller = null

## Minimum drag distance to register a swipe (in pixels)
const SWIPE_THRESHOLD := 20.0

## Touch tracking
var _touch_start_pos: Vector2 = Vector2.ZERO
var _is_touching: bool = false


func _ready() -> void:
	pass  # Phase 2: wire up to board


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or grid_controller == null:
		return

	# Handle touch/click begin
	if event is InputEventMouseButton and event.pressed:
		_touch_start_pos = event.position
		_is_touching = true
		_handle_tap(event.position)

	# Handle touch/click end (for swipe detection)
	elif event is InputEventMouseButton and not event.pressed:
		if _is_touching:
			var drag := event.position - _touch_start_pos
			if drag.length() > SWIPE_THRESHOLD and selected_position != Vector2i(-1, -1):
				_handle_swipe(drag)
			_is_touching = false


## Handle a tap at a screen position.
func _handle_tap(screen_pos: Vector2) -> void:
	var grid_pos := grid_controller.world_to_grid(screen_pos)
	if not grid_controller.is_valid_position(grid_pos.x, grid_pos.y):
		_deselect()
		return

	if selected_position == Vector2i(-1, -1):
		# First tap — select piece
		selected_position = grid_pos
		EventBus.piece_selected.emit(grid_pos)
	else:
		# Second tap — attempt swap if adjacent
		if _is_adjacent(selected_position, grid_pos):
			EventBus.swap_requested.emit(selected_position, grid_pos)
			_deselect()
		else:
			# Select the new piece instead
			_deselect()
			selected_position = grid_pos
			EventBus.piece_selected.emit(grid_pos)


## Handle a swipe gesture from the selected piece.
func _handle_swipe(drag: Vector2) -> void:
	var direction := Vector2i.ZERO
	if abs(drag.x) > abs(drag.y):
		direction = Vector2i(1, 0) if drag.x > 0 else Vector2i(-1, 0)
	else:
		direction = Vector2i(0, 1) if drag.y > 0 else Vector2i(0, -1)

	var target := selected_position + direction
	if grid_controller.is_valid_position(target.x, target.y):
		EventBus.swap_requested.emit(selected_position, target)
	_deselect()


## Clear selection.
func _deselect() -> void:
	selected_position = Vector2i(-1, -1)
	EventBus.piece_deselected.emit()


## Check if two positions are adjacent (no diagonals).
func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := (b - a).abs()
	return (diff.x + diff.y) == 1
