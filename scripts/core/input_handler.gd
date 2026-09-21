# input_handler.gd — Handles touch/click input for piece selection and swaps.
# Emits swap_requested via EventBus. Works with BoardManager for coordinate conversion.
extends Node

## Whether input is currently accepted.
var input_enabled: bool = true

## Currently selected piece position (or invalid sentinel).
var selected_position: Vector2i = Vector2i(-1, -1)

## Reference to the BoardManager for coordinate conversion.
var board_manager = null

## Minimum drag distance to register a swipe (in pixels).
const SWIPE_THRESHOLD := 30.0

## Touch tracking
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_grid: Vector2i = Vector2i(-1, -1)
var _is_touching: bool = false


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or board_manager == null:
		return
	# Only accept input when board is idle
	if board_manager.state != board_manager.BoardState.IDLE:
		return

	# Touch / click begin
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_touch_start_pos = event.position
		_touch_start_grid = _screen_to_grid(event.position)
		_is_touching = true

	# Touch / click end
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_touching:
			var drag := event.position - _touch_start_pos
			if drag.length() > SWIPE_THRESHOLD and _touch_start_grid != Vector2i(-1, -1):
				# Swipe gesture — select the start cell and request swap
				_handle_swipe(_touch_start_grid, drag)
			else:
				# Tap gesture
				_handle_tap(_touch_start_grid)
			_is_touching = false


## Convert screen position to grid position using board_manager.
func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - board_manager.board_origin
	var col := int(local.x / board_manager.cell_size)
	var row := int(local.y / board_manager.cell_size)
	if col >= 0 and col < board_manager.columns and row >= 0 and row < board_manager.rows:
		return Vector2i(col, row)
	return Vector2i(-1, -1)


## Handle a tap at a grid position.
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
			EventBus.swap_requested.emit(selected_position, grid_pos)
			_deselect()
		elif grid_pos == selected_position:
			# Tapped same piece — deselect
			_deselect()
		else:
			# Select the new piece instead
			_deselect()
			selected_position = grid_pos
			EventBus.piece_selected.emit(grid_pos)


## Handle a swipe gesture from a grid position.
func _handle_swipe(from_grid: Vector2i, drag: Vector2) -> void:
	if from_grid == Vector2i(-1, -1):
		return

	var direction := Vector2i.ZERO
	if abs(drag.x) > abs(drag.y):
		direction = Vector2i(1, 0) if drag.x > 0 else Vector2i(-1, 0)
	else:
		direction = Vector2i(0, 1) if drag.y > 0 else Vector2i(0, -1)

	var target := from_grid + direction
	# If nothing selected yet, select the swiped piece first
	if selected_position == Vector2i(-1, -1):
		EventBus.piece_selected.emit(from_grid)

	if board_manager._is_valid_pos(target.x, target.y):
		EventBus.swap_requested.emit(from_grid, target)
	_deselect()


## Clear selection.
func _deselect() -> void:
	selected_position = Vector2i(-1, -1)
	EventBus.piece_deselected.emit()


## Check if two positions are adjacent (no diagonals).
func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := (b - a).abs()
	return (diff.x + diff.y) == 1
