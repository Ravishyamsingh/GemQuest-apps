# grid_controller.gd — Manages the 2D array of pieces on the board.
# Provides utilities for piece placement, removal, swapping, and position queries.
extends Node2D

## Grid dimensions
var columns: int = 8
var rows: int = 8

## The 2D array holding piece references. grid[col][row]
var grid: Array = []

## Cell size in pixels (computed at runtime based on screen/board size)
var cell_size: float = 64.0

## Top-left origin of the board in world coordinates
var board_origin: Vector2 = Vector2.ZERO

## Scene to instantiate for new pieces
var piece_scene: PackedScene = preload("res://scenes/gameplay/piece.tscn")


func _ready() -> void:
	pass  # Phase 2: initialize grid


## Initialise the grid with given dimensions.
func init_grid(cols: int, rws: int, c_size: float, origin: Vector2) -> void:
	columns = cols
	rows = rws
	cell_size = c_size
	board_origin = origin
	grid.clear()
	for col in columns:
		var column_array: Array = []
		column_array.resize(rows)
		grid.append(column_array)


## Get the piece at a grid position, or null.
func get_piece(col: int, row: int):
	if not is_valid_position(col, row):
		return null
	return grid[col][row]


## Set a piece at a grid position.
func set_piece(col: int, row: int, piece) -> void:
	if is_valid_position(col, row):
		grid[col][row] = piece


## Remove and return the piece at a position.
func remove_piece(col: int, row: int):
	if not is_valid_position(col, row):
		return null
	var piece = grid[col][row]
	grid[col][row] = null
	return piece


## Swap the pieces at two positions.
func swap_pieces(pos_a: Vector2i, pos_b: Vector2i) -> void:
	var temp = grid[pos_a.x][pos_a.y]
	grid[pos_a.x][pos_a.y] = grid[pos_b.x][pos_b.y]
	grid[pos_b.x][pos_b.y] = temp


## Check if a grid position is within bounds.
func is_valid_position(col: int, row: int) -> bool:
	return col >= 0 and col < columns and row >= 0 and row < rows


## Convert grid position to world pixel position (centre of cell).
func grid_to_world(col: int, row: int) -> Vector2:
	return board_origin + Vector2(col * cell_size + cell_size * 0.5, row * cell_size + cell_size * 0.5)


## Convert world position to grid position.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_position: Vector2 = world_pos - board_origin
	var col: int = int(local_position.x / cell_size)
	var row: int = int(local_position.y / cell_size)
	return Vector2i(col, row)
