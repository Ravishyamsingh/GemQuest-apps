# piece_pool.gd — Recycles Piece instances to eliminate GC hitching and allocation overhead on mobile.
class_name PiecePool
extends Node

var _piece_scene: PackedScene = preload("res://scenes/gameplay/piece.tscn")
var _pool: Array[Piece] = []
var _active: Array[Piece] = []
var _parent_node: Node2D = null


func init_pool(parent: Node2D, initial_capacity: int = 70) -> void:
	if _parent_node == null:
		_parent_node = parent
	var missing := maxi(0, initial_capacity - _pool.size() - _active.size())
	for i in missing:
		var p: Piece = _create_new_piece()
		p.visible = false
		_pool.append(p)


func acquire(data: PieceData, grid_pos: Vector2i, cell_size: float) -> Piece:
	var piece: Piece = null
	if not _pool.is_empty():
		piece = _pool.pop_back()
	else:
		piece = _create_new_piece()
	
	piece.reset_for_pool()
	piece.visible = true
	piece.setup(data, grid_pos, cell_size)
	_active.append(piece)
	return piece


func release(piece: Piece) -> void:
	if piece == null:
		return
	var idx := _active.find(piece)
	if idx != -1:
		_active.remove_at(idx)
	
	piece.reset_for_pool()
	_pool.append(piece)


func release_all() -> void:
	for piece in _active:
		piece.reset_for_pool()
		_pool.append(piece)
	_active.clear()


func _create_new_piece() -> Piece:
	var p: Piece = _piece_scene.instantiate()
	if _parent_node:
		_parent_node.add_child(p)
	return p
