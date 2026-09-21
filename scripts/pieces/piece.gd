# piece.gd — Individual gem piece on the game board.
# Attached to the Piece scene. Handles its own visual state,
# selection highlight, and tween animations.
class_name Piece
extends Node2D

## Special piece types — NONE for MVP, others added in Phase 2.
enum SpecialType { NONE, STRIPED_H, STRIPED_V, BLAST, PRISM }

## The grid position of this piece (column, row).
var grid_position: Vector2i = Vector2i.ZERO

## Reference to this piece's type data.
var piece_data: PieceData = null

## Special type (Phase 2). Always NONE in MVP.
var special_type: SpecialType = SpecialType.NONE

## Whether this piece is currently part of a match being resolved.
var is_matched: bool = false

## Whether this piece is currently animating (moving, spawning, etc.).
var is_moving: bool = false

## Whether this piece is currently selected by the player.
var is_selected: bool = false

## The sprite node displaying this piece.
@onready var _sprite: Sprite2D = $Sprite2D


## Initialise the piece with type data and grid position.
func setup(data: PieceData, pos: Vector2i) -> void:
	piece_data = data
	grid_position = pos
	if _sprite and piece_data and piece_data.texture:
		_sprite.texture = piece_data.texture
	# Fallback: tint a white placeholder with the piece colour
	if _sprite and piece_data:
		_sprite.modulate = piece_data.colour


## Set the grid position and update visual position.
func set_grid_pos(pos: Vector2i, cell_size: float, board_origin: Vector2) -> void:
	grid_position = pos
	position = board_origin + Vector2(pos.x * cell_size + cell_size * 0.5, pos.y * cell_size + cell_size * 0.5)


## Visual highlight for selection.
func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		scale = Vector2(1.1, 1.1)
	else:
		scale = Vector2(1.0, 1.0)
