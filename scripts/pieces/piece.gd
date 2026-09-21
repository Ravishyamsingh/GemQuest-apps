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

## The piece type id (cached for fast match detection).
var piece_type: StringName = &""

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

## Selection highlight node.
@onready var _highlight: Node2D = $Highlight


func _ready() -> void:
	if _highlight:
		_highlight.visible = false


## Initialise the piece with type data and grid position.
func setup(data: PieceData, pos: Vector2i, cell_size: float) -> void:
	piece_data = data
	piece_type = data.piece_id
	grid_position = pos
	
	# Set up the sprite — use texture if available, otherwise draw coloured placeholder
	if _sprite:
		if piece_data.texture:
			_sprite.texture = piece_data.texture
			# Scale texture to fit cell
			var tex_size := piece_data.texture.get_size()
			var target_size := cell_size * 0.8  # 80% of cell for padding
			_sprite.scale = Vector2(target_size / tex_size.x, target_size / tex_size.y)
		else:
			# Create a placeholder coloured texture
			var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
			img.fill(piece_data.colour)
			var tex := ImageTexture.create_from_image(img)
			_sprite.texture = tex
			var target_size := cell_size * 0.8
			_sprite.scale = Vector2(target_size / 64.0, target_size / 64.0)
		_sprite.modulate = Color.WHITE  # Don't double-tint if texture has colour
	
	# Set up highlight size to match
	if _highlight and _highlight is Sprite2D:
		var target_size := cell_size * 0.9
		_highlight.scale = Vector2(target_size / 64.0, target_size / 64.0)


## Set the grid position (data only, no visual update).
func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos


## Visual highlight for selection.
func set_selected(selected: bool) -> void:
	is_selected = selected
	if _highlight:
		_highlight.visible = selected
	if selected:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	else:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)


## Animate moving to a world position.
func animate_move_to(target_pos: Vector2, duration: float = 0.15) -> void:
	is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func(): is_moving = false)


## Animate swap rejection (wobble back).
func animate_swap_reject(original_pos: Vector2, duration: float = 0.1) -> void:
	is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", position + (position - original_pos).normalized() * 10, duration * 0.5)
	tween.tween_property(self, "position", original_pos, duration * 0.5)
	tween.tween_callback(func():
		is_moving = false
		position = original_pos
	)


## Animate match pop (scale down and fade).
func animate_pop(duration: float = 0.2) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), duration * 0.3)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.2)
	tween.set_parallel(false)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), duration * 0.3)


## Animate spawning in (fade + drop).
func animate_spawn(from_y_offset: float = -80.0, duration: float = 0.2) -> void:
	var target_pos := position
	position.y += from_y_offset
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "modulate:a", 1.0, duration * 0.5)
