# input_handler.gd — Handles touch, drag, swipe, and click input for gem selection and swapping.
# Emits swap_requested and selection events via EventBus. Works with BoardManager for coordinate mapping.
extends Node

## Whether input is currently accepted.
var input_enabled: bool = true

## Currently selected piece position (or Vector2i(-1, -1) for no selection).
var selected_position: Vector2i = Vector2i(-1, -1)

## Reference to the BoardManager for coordinate conversion and state checking.
var board_manager = null

## Minimum drag distance in pixels to trigger a directional swipe.
const SWIPE_THRESHOLD := 28.0

## Touch tracking state
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_grid: Vector2i = Vector2i(-1, -1)
var _is_touching: bool = false
var _touch_index: int = -1


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or board_manager == null:
		reset_touch_state()
		return
	
	# Only accept input when board is idle
	if board_manager.state != board_manager.BoardState.IDLE:
		reset_touch_state()
		return

	# Mouse inputs
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_touch(0, event.position)
		else:
			_end_touch(0, event.position)
	elif event is InputEventMouseMotion:
		if _is_touching and _touch_index == 0:
			_drag_touch(0, event.position)

	# Native Touchscreen inputs
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_touch(event.index, event.position)
		else:
			_end_touch(event.index, event.position)
	elif event is InputEventScreenDrag:
		if _is_touching and _touch_index == event.index:
			_drag_touch(event.index, event.position)


## Begin touch or click tracking.
func _start_touch(index: int, screen_pos: Vector2) -> void:
	# Single-touch focus: ignore secondary fingers if already tracking a touch
	if _is_touching:
		return
	
	_touch_index = index
	_touch_start_pos = screen_pos
	_touch_start_grid = _screen_to_grid(screen_pos)
	_is_touching = true


## Continuous drag tracking: triggers swipe immediately once threshold is passed.
func _drag_touch(index: int, current_pos: Vector2) -> void:
	if not _is_touching or _touch_index != index:
		return
	
	var drag := current_pos - _touch_start_pos
	if drag.length() >= SWIPE_THRESHOLD and _touch_start_grid != Vector2i(-1, -1):
		var from_cell := _touch_start_grid
		reset_touch_state()
		_handle_swipe(from_cell, drag)


## Release touch or click.
func _end_touch(index: int, current_pos: Vector2) -> void:
	if not _is_touching or _touch_index != index:
		return
	
	var drag := current_pos - _touch_start_pos
	var from_cell := _touch_start_grid
	reset_touch_state()
	
	if drag.length() >= SWIPE_THRESHOLD and from_cell != Vector2i(-1, -1):
		_handle_swipe(from_cell, drag)
	else:
		_handle_tap(from_cell)


## Reset all touch tracking state.
func reset_touch_state() -> void:
	_is_touching = false
	_touch_index = -1
	_touch_start_pos = Vector2.ZERO
	_touch_start_grid = Vector2i(-1, -1)


## Convert screen position to grid coordinates using board dimensions.
func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	if board_manager == null or board_manager.cell_size <= 0.0:
		return Vector2i(-1, -1)
	
	var local_position: Vector2 = screen_pos - board_manager.board_origin
	var col: int = int(local_position.x / board_manager.cell_size)
	var row: int = int(local_position.y / board_manager.cell_size)
	
	if col >= 0 and col < board_manager.columns and row >= 0 and row < board_manager.rows:
		return Vector2i(col, row)
	return Vector2i(-1, -1)


## Handle a tap at a grid position (select piece or execute adjacent swap).
func _handle_tap(grid_pos: Vector2i) -> void:
	if grid_pos == Vector2i(-1, -1):
		_deselect()
		return

	if selected_position == Vector2i(-1, -1):
		# First tap — select piece
		selected_position = grid_pos
		EventBus.piece_selected.emit(grid_pos)
	else:
		# Second tap — attempt swap if adjacent
		if _is_adjacent(selected_position, grid_pos):
			var origin := selected_position
			_deselect()
			EventBus.swap_requested.emit(origin, grid_pos)
		elif grid_pos == selected_position:
			# Tapped same piece — deselect
			_deselect()
		else:
			# Select the new piece instead
			_deselect()
			selected_position = grid_pos
			EventBus.piece_selected.emit(grid_pos)


## Handle a swipe gesture from a starting grid cell.
func _handle_swipe(from_grid: Vector2i, drag: Vector2) -> void:
	if from_grid == Vector2i(-1, -1) or board_manager == null:
		return

	var direction := Vector2i.ZERO
	if abs(drag.x) > abs(drag.y):
		direction = Vector2i(1, 0) if drag.x > 0 else Vector2i(-1, 0)
	else:
		direction = Vector2i(0, 1) if drag.y > 0 else Vector2i(0, -1)

	var target := from_grid + direction

	# If nothing was selected yet, select the swiped piece visually
	if selected_position == Vector2i(-1, -1):
		EventBus.piece_selected.emit(from_grid)

	_deselect()

	if board_manager._is_valid_pos(target.x, target.y):
		EventBus.swap_requested.emit(from_grid, target)


## Clear current piece selection.
func _deselect() -> void:
	selected_position = Vector2i(-1, -1)
	EventBus.piece_deselected.emit()


## Check if two grid cells are orthogonally adjacent (no diagonals).
func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := (b - a).abs()
	return (diff.x + diff.y) == 1
