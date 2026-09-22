# piece_pool.gd — Recycles Piece instances to eliminate GC hitching and allocation overhead on mobile.
class_name PiecePool
extends Node

var _piece_scene: PackedScene = preload("res://scenes/gameplay/piece.tscn")
var _pool: Array[Piece] = []
var _active: Array[Piece] = []
var _parent_node: Node2D = null


func init_pool(parent: Node2D, initial_capacity: int = 70) -> void:
	_parent_node = parent
	for i in initial_capacity:
		var p: Piece = _create_new_piece()
		p.visible = false
		_pool.append(p)


func acquire(data: PieceData, grid_pos: Vector2i, cell_size: float) -> Piece:
	var piece: Piece = null
	if not _pool.is_empty():
		piece = _pool.pop_back()
	else:
		piece = _create_new_piece()
	
	piece.visible = true
	piece.modulate = Color.WHITE
	piece.scale = Vector2.ONE
	piece.is_matched = false
	piece.is_moving = false
	piece.is_selected = false
	piece.setup(data, grid_pos, cell_size)
	_active.append(piece)
	return piece


func release(piece: Piece) -> void:
	if piece == null:
		return
	var idx := _active.find(piece)
	if idx != -1:
		_active.remove_at(idx)
	
	piece.visible = false
	piece.position = Vector2(-1000, -1000)
	_pool.append(piece)


func release_all() -> void:
	for piece in _active:
		piece.visible = false
		piece.position = Vector2(-1000, -1000)
		_pool.append(piece)
	_active.clear()


func _create_new_piece() -> Piece:
	var p: Piece = _piece_scene.instantiate()
	if _parent_node:
		_parent_node.add_child(p)
	return p
