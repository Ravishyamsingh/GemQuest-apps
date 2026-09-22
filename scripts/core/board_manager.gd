# board_manager.gd — Orchestrates the gameplay loop on the board.
# Owns GridController, InputHandler, MatchDetector, CascadeResolver.
# Manages board state machine: IDLE → SWAPPING → MATCHING → CASCADING → CHECK_END
extends Node2D

enum BoardState { INITIALIZING, IDLE, SWAPPING, MATCHING, CASCADING, CHECK_END, WIN, LOSE }

var state: BoardState = BoardState.INITIALIZING
var level_data: Dictionary = {}

## Grid dimensions
var columns: int = 8
var rows: int = 8
var cell_size: float = 80.0
var board_origin: Vector2 = Vector2.ZERO

## Piece data definitions (loaded once)
var piece_definitions: Array[PieceData] = []
## Piece IDs available for the current level
var available_piece_ids: Array = []

## The 2D grid array: grid[col][row] = Piece node or null
var grid: Array = []

## Piece scene to instantiate
var piece_scene: PackedScene = preload("res://scenes/gameplay/piece.tscn")

## Currently selected piece position
var selected_pos: Vector2i = Vector2i(-1, -1)

## Game systems
var score_manager_node: Node = null
var move_counter_node: Node = null
var objective_tracker_node: Node = null

## Preloaded scripts and scenes for effects and child systems
const ScoreManagerScript = preload("res://scripts/core/score_manager.gd")
const MoveCounterScript = preload("res://scripts/core/move_counter.gd")
const ObjectiveTrackerScript = preload("res://scripts/core/objective_tracker.gd")
var floating_text_scene: PackedScene = preload("res://scenes/gameplay/floating_text.tscn")
var particle_burst_scene: PackedScene = preload("res://scenes/gameplay/gem_particle_burst.tscn")


func _ready() -> void:
	# Connect EventBus signals
	EventBus.piece_selected.connect(_on_piece_selected)
	EventBus.piece_deselected.connect(_on_piece_deselected)
	EventBus.swap_requested.connect(_on_swap_requested)
	
	# Create child game systems
	score_manager_node = Node.new()
	score_manager_node.name = "ScoreManager"
	score_manager_node.set_script(ScoreManagerScript)
	add_child(score_manager_node)
	
	move_counter_node = Node.new()
	move_counter_node.name = "MoveCounter"
	move_counter_node.set_script(MoveCounterScript)
	add_child(move_counter_node)
	
	objective_tracker_node = Node.new()
	objective_tracker_node.name = "ObjectiveTracker"
	objective_tracker_node.set_script(ObjectiveTrackerScript)
	add_child(objective_tracker_node)
	
	# Listen for game-over conditions
	EventBus.objective_complete.connect(_on_objective_complete)
	EventBus.moves_exhausted.connect(_on_moves_exhausted)
	
	# Create piece definitions
	_create_piece_definitions()


## Create PieceData resources for all 6 gem types.
func _create_piece_definitions() -> void:
	var gem_defs := [
		{&"id": &"diamond",  "name": "Diamond",  "color": Color(0.9, 0.9, 1.0)},
		{&"id": &"ruby",     "name": "Ruby",     "color": Color(1.0, 0.2, 0.2)},
		{&"id": &"sapphire", "name": "Sapphire", "color": Color(0.2, 0.4, 1.0)},
		{&"id": &"emerald",  "name": "Emerald",  "color": Color(0.2, 0.85, 0.4)},
		{&"id": &"topaz",    "name": "Topaz",    "color": Color(1.0, 0.85, 0.1)},
		{&"id": &"amethyst", "name": "Amethyst", "color": Color(0.65, 0.3, 0.9)},
	]
	
	piece_definitions.clear()
	for def in gem_defs:
		var pd := PieceData.new()
		pd.piece_id = def[&"id"]
		pd.display_name = def["name"]
		pd.colour = def["color"]
		var tex_path := "res://assets/graphics/pieces/gem_" + String(def[&"id"]) + ".png"
		if ResourceLoader.exists(tex_path):
			pd.texture = load(tex_path)
		piece_definitions.append(pd)


## Get PieceData by id.
func _get_piece_data(piece_id: StringName) -> PieceData:
	for pd in piece_definitions:
		if pd.piece_id == piece_id:
			return pd
	return null


## Get available PieceData list for the current level.
func _get_available_pieces() -> Array[PieceData]:
	var available: Array[PieceData] = []
	for pid in available_piece_ids:
		var pd := _get_piece_data(StringName(pid))
		if pd:
			available.append(pd)
	return available


## ===== PUBLIC API =====

## Initialise the board with level data.
func setup_board(data: Dictionary) -> void:
	level_data = data
	state = BoardState.INITIALIZING
	
	# Extract level parameters
	columns = data.get("grid_columns", 8)
	rows = data.get("grid_rows", 8)
	available_piece_ids = data.get("available_piece_ids", ["diamond", "ruby", "sapphire", "emerald", "topaz", "amethyst"])
	
	# Calculate cell size to fit the screen
	var viewport_size := get_viewport_rect().size
	var board_width := viewport_size.x * 0.95  # 95% of screen width
	var board_height := viewport_size.y * 0.55  # 55% of screen height (leave room for HUD)
	cell_size = min(board_width / columns, board_height / rows)
	
	# Centre the board horizontally, place it in the middle-lower area
	var total_board_width := columns * cell_size
	board_origin = Vector2(
		(viewport_size.x - total_board_width) / 2.0,
		viewport_size.y * 0.25  # Start 25% from top
	)
	
	# Clear any existing pieces
	_clear_board()
	
	# Initialise grid array
	grid.clear()
	for col in columns:
		var column_array: Array = []
		column_array.resize(rows)
		grid.append(column_array)
	
	# Fill the board ensuring no initial matches and at least one valid move
	_fill_board_guaranteed_playable()
	
	# Initialise game systems
	score_manager_node.reset()
	move_counter_node.setup(data.get("max_moves", 25))
	objective_tracker_node.setup(data)
	
	# Draw the board background
	queue_redraw()
	
	state = BoardState.IDLE
	EventBus.board_ready.emit()


## ===== DRAWING =====

func _draw() -> void:
	if grid.is_empty():
		return
	
	# Draw board background
	var board_rect := Rect2(board_origin, Vector2(columns * cell_size, rows * cell_size))
	draw_rect(board_rect, Color(0.15, 0.08, 0.35, 0.8), true, -1.0)
	draw_rect(board_rect, Color(0.5, 0.35, 0.8, 0.5), false, 2.0)
	
	# Draw grid lines / cell backgrounds
	for col in columns:
		for row in rows:
			var cell_rect := Rect2(
				board_origin + Vector2(col * cell_size, row * cell_size),
				Vector2(cell_size, cell_size)
			)
			# Alternating cell tint for subtle checkerboard
			var tint := Color(1, 1, 1, 0.03) if (col + row) % 2 == 0 else Color(0, 0, 0, 0.03)
			draw_rect(cell_rect, tint, true)
			# Cell border
			draw_rect(cell_rect, Color(0.4, 0.25, 0.65, 0.2), false, 1.0)


## ===== BOARD FILL =====

## Fill the board ensuring no initial matches of 3+ and that at least one valid move exists.
func _fill_board_guaranteed_playable() -> void:
	var attempts := 0
	while attempts < 30:
		attempts += 1
		_clear_board()
		
		# Re-initialise empty grid columns
		grid.clear()
		for col in columns:
			var column_array: Array = []
			column_array.resize(rows)
			grid.append(column_array)
		
		_fill_board_no_matches()
		if has_valid_moves():
			return


## Fill the board ensuring no initial matches of 3+.
func _fill_board_no_matches() -> void:
	var available := _get_available_pieces()
	
	for col in columns:
		for row in rows:
			var valid_pieces := available.duplicate()
			
			# Remove pieces that would create a horizontal match of 3
			if col >= 2:
				var p1 = grid[col - 1][row]
				var p2 = grid[col - 2][row]
				if p1 != null and p2 != null:
					if p1.piece_type == p2.piece_type:
						valid_pieces = valid_pieces.filter(func(pd): return pd.piece_id != p1.piece_type)
			
			# Remove pieces that would create a vertical match of 3
			if row >= 2:
				var p1 = grid[col][row - 1]
				var p2 = grid[col][row - 2]
				if p1 != null and p2 != null:
					if p1.piece_type == p2.piece_type:
						valid_pieces = valid_pieces.filter(func(pd): return pd.piece_id != p1.piece_type)
			
			# Fallback: if no valid pieces (shouldn't happen with 5+ types), use any
			if valid_pieces.is_empty():
				valid_pieces = available.duplicate()
			
			# Pick a random piece
			var chosen: PieceData = valid_pieces[randi() % valid_pieces.size()]
			_spawn_piece(col, row, chosen, false)


## Spawn a single piece at a grid position.
func _spawn_piece(col: int, row: int, data: PieceData, animate: bool = true) -> Piece:
	var piece: Piece = piece_scene.instantiate()
	add_child(piece)
	
	# Position the piece
	var world_pos := _grid_to_world(col, row)
	piece.position = world_pos
	piece.setup(data, Vector2i(col, row), cell_size)
	
	# Store in grid
	grid[col][row] = piece
	
	if animate:
		piece.animate_spawn(-cell_size * 2)
	
	return piece


## Clear all pieces from the board.
func _clear_board() -> void:
	for child in get_children():
		if child is Piece:
			child.queue_free()
	grid.clear()


## ===== COORDINATE HELPERS =====

## Convert grid position to world position (centre of cell).
func _grid_to_world(col: int, row: int) -> Vector2:
	return board_origin + Vector2(col * cell_size + cell_size * 0.5, row * cell_size + cell_size * 0.5)


## Convert world position to grid position.
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_position: Vector2 = world_pos - board_origin
	var col: int = int(local_position.x / cell_size)
	var row: int = int(local_position.y / cell_size)
	return Vector2i(clampi(col, 0, columns - 1), clampi(row, 0, rows - 1))


## Check if a grid position is valid.
func _is_valid_pos(col: int, row: int) -> bool:
	return col >= 0 and col < columns and row >= 0 and row < rows


## Check if two positions are adjacent (no diagonals).
func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := (b - a).abs()
	return (diff.x + diff.y) == 1


## ===== INPUT HANDLING =====

func _on_piece_selected(pos: Vector2i) -> void:
	if state != BoardState.IDLE:
		return
	
	# Deselect previous
	if selected_pos != Vector2i(-1, -1):
		var prev_piece = grid[selected_pos.x][selected_pos.y]
		if prev_piece:
			prev_piece.set_selected(false)
	
	# Select new piece
	if _is_valid_pos(pos.x, pos.y) and grid[pos.x][pos.y] != null:
		selected_pos = pos
		grid[pos.x][pos.y].set_selected(true)


func _on_piece_deselected() -> void:
	if selected_pos != Vector2i(-1, -1):
		var piece = grid[selected_pos.x][selected_pos.y]
		if piece:
			piece.set_selected(false)
	selected_pos = Vector2i(-1, -1)


func _on_swap_requested(from_pos: Vector2i, to_pos: Vector2i) -> void:
	if state != BoardState.IDLE:
		return
	if not _is_adjacent(from_pos, to_pos):
		return
	if not _is_valid_pos(from_pos.x, from_pos.y) or not _is_valid_pos(to_pos.x, to_pos.y):
		return
	
	var piece_a = grid[from_pos.x][from_pos.y]
	var piece_b = grid[to_pos.x][to_pos.y]
	if piece_a == null or piece_b == null:
		return
	
	# Deselect
	piece_a.set_selected(false)
	selected_pos = Vector2i(-1, -1)
	
	# Perform the swap
	state = BoardState.SWAPPING
	await _animate_swap(piece_a, piece_b, from_pos, to_pos)
	
	# Swap in grid data
	grid[from_pos.x][from_pos.y] = piece_b
	grid[to_pos.x][to_pos.y] = piece_a
	piece_a.grid_position = to_pos
	piece_b.grid_position = from_pos
	
	# Check if swap produces a match
	var matches := _find_matches()
	
	if matches.is_empty():
		# Invalid swap — swap back
		await _animate_swap(piece_a, piece_b, to_pos, from_pos)
		grid[from_pos.x][from_pos.y] = piece_a
		grid[to_pos.x][to_pos.y] = piece_b
		piece_a.grid_position = from_pos
		piece_b.grid_position = to_pos
		EventBus.swap_rejected.emit(from_pos, to_pos)
		state = BoardState.IDLE
	else:
		# Valid swap — consume a move
		EventBus.swap_completed.emit(from_pos, to_pos)
		move_counter_node.use_move()
		
		# Process matches and cascades
		state = BoardState.MATCHING
		await _process_matches_and_cascades(matches)
		
		# Check end conditions
		if state == BoardState.WIN or state == BoardState.LOSE:
			return
		
		# Check for no valid moves and shuffle if needed
		if not has_valid_moves():
			shuffle_board()
			await get_tree().create_timer(0.35).timeout
		
		state = BoardState.IDLE


## ===== SWAP ANIMATION =====

func _animate_swap(piece_a: Piece, piece_b: Piece, pos_a: Vector2i, pos_b: Vector2i) -> void:
	var target_a := _grid_to_world(pos_b.x, pos_b.y)
	var target_b := _grid_to_world(pos_a.x, pos_a.y)
	
	piece_a.animate_move_to(target_a, 0.15)
	piece_b.animate_move_to(target_b, 0.15)
	
	await get_tree().create_timer(0.18).timeout


## ===== MATCH DETECTION =====

## Find all matches on the current board.
func _find_matches() -> Array:
	var get_type := func(piece) -> StringName:
		if piece == null:
			return &""
		return piece.piece_type
	
	return MatchDetector.find_all_matches(grid, columns, rows, get_type)


## ===== MATCH + CASCADE PROCESSING =====

func _process_matches_and_cascades(initial_matches: Array) -> void:
	var cascade_depth := 0
	var matches := initial_matches
	
	while not matches.is_empty():
		cascade_depth += 1
		
		# Emit match found
		EventBus.match_found.emit(matches)
		
		# Calculate score for this cascade step and spawn floating texts
		var step_score: int = 0
		if score_manager_node.has_method("calculate_matches_score"):
			step_score = int(score_manager_node.calculate_matches_score(matches, cascade_depth))
		score_manager_node.add_match_score(matches, cascade_depth)
		
		# Spawn floating score text at center of first match
		if not matches.is_empty() and floating_text_scene != null:
			var first_match: MatchResult = matches[0] as MatchResult
			if not first_match.positions.is_empty():
				var match_pos: Vector2i = first_match.positions[0]
				var center_pos: Vector2 = _grid_to_world(match_pos.x, match_pos.y)
				var ft = floating_text_scene.instantiate()
				add_child(ft)
				var text_label := "+%d" % step_score
				if cascade_depth > 1:
					text_label += " (x%d)" % cascade_depth
				ft.setup(text_label, center_pos)
		
		# Collect all positions to remove
		var positions_to_remove: Dictionary = {}  # Used as a set
		for match_result in matches:
			for pos in match_result.positions:
				positions_to_remove[pos] = true
		
		# Animate and remove matched pieces
		await _remove_matched_pieces(positions_to_remove.keys())
		EventBus.pieces_removed.emit(positions_to_remove.keys())
		
		# Apply gravity — pieces fall down
		await _apply_gravity()
		
		# Refill empty cells at top
		await _refill_empty_cells()
		
		# Check if objective was met during this cascade
		if objective_tracker_node.is_complete:
			state = BoardState.WIN
			EventBus.cascade_complete.emit()
			EventBus.level_won.emit()
			return
		
		# Emit cascade step
		EventBus.cascade_step.emit(cascade_depth)
		
		# Check for new matches (cascade)
		matches = _find_matches()
		
		# Safety limit
		if cascade_depth >= 100:
			push_warning("BoardManager: Hit cascade limit!")
			break
	
	EventBus.cascade_complete.emit()
	
	# After cascade resolves, check if player is out of moves
	if not move_counter_node.has_moves() and not objective_tracker_node.is_complete:
		state = BoardState.LOSE
		EventBus.level_lost.emit()


## Remove matched pieces with pop animation and particles.
func _remove_matched_pieces(positions: Array) -> void:
	for pos in positions:
		var piece = grid[pos.x][pos.y]
		if piece != null:
			piece.animate_pop(0.2)
			if particle_burst_scene != null:
				var burst = particle_burst_scene.instantiate()
				add_child(burst)
				var color: Color = piece.piece_data.colour if piece.piece_data else Color.WHITE
				burst.setup(_grid_to_world(int(pos.x), int(pos.y)), color)
	
	await get_tree().create_timer(0.25).timeout
	
	# Actually free the pieces
	for pos in positions:
		var piece = grid[pos.x][pos.y]
		if piece != null:
			piece.queue_free()
			grid[pos.x][pos.y] = null


## Apply gravity — pieces above gaps fall down.
func _apply_gravity() -> void:
	var any_fell := false
	
	for col in columns:
		# Process from bottom to top
		var write_row := rows - 1
		for read_row in range(rows - 1, -1, -1):
			if grid[col][read_row] != null:
				if write_row != read_row:
					# Move piece down
					var piece: Piece = grid[col][read_row]
					grid[col][write_row] = piece
					grid[col][read_row] = null
					piece.grid_position = Vector2i(col, write_row)
					var target := _grid_to_world(col, write_row)
					piece.animate_move_to(target, 0.08 * (write_row - read_row))
					any_fell = true
				write_row -= 1
	
	if any_fell:
		await get_tree().create_timer(0.2).timeout


## Refill empty cells at the top of each column.
func _refill_empty_cells() -> void:
	var available := _get_available_pieces()
	var any_spawned := false
	
	for col in columns:
		for row in rows:
			if grid[col][row] == null:
				var chosen: PieceData = available[randi() % available.size()]
				_spawn_piece(col, row, chosen, true)
				any_spawned = true
	
	if any_spawned:
		await get_tree().create_timer(0.25).timeout


## ===== NO VALID MOVES CHECK =====

## Check if any valid move exists on the board.
func has_valid_moves() -> bool:
	for col in columns:
		for row in rows:
			# Try swapping right
			if col < columns - 1:
				_grid_swap(col, row, col + 1, row)
				if not _find_matches().is_empty():
					_grid_swap(col, row, col + 1, row)  # Swap back
					return true
				_grid_swap(col, row, col + 1, row)  # Swap back
			
			# Try swapping down
			if row < rows - 1:
				_grid_swap(col, row, col, row + 1)
				if not _find_matches().is_empty():
					_grid_swap(col, row, col, row + 1)  # Swap back
					return true
				_grid_swap(col, row, col, row + 1)  # Swap back
	return false


## Swap two pieces in the grid array only (no animation).
func _grid_swap(col_a: int, row_a: int, col_b: int, row_b: int) -> void:
	var temp = grid[col_a][row_a]
	grid[col_a][row_a] = grid[col_b][row_b]
	grid[col_b][row_b] = temp


## Shuffle the board if no valid moves exist, guaranteeing no starting matches and >= 1 valid move.
func shuffle_board() -> void:
	# Spawn visual announcement
	if floating_text_scene != null:
		var center_pos := board_origin + Vector2(columns * cell_size * 0.5, rows * cell_size * 0.45)
		var ft = floating_text_scene.instantiate()
		add_child(ft)
		ft.setup("No Moves! Shuffling...", center_pos)
	
	if AudioManager:
		AudioManager.play_sfx_by_name("swap")
	
	# Collect all pieces
	var all_pieces: Array = []
	for col in columns:
		for row in rows:
			if grid[col][row] != null:
				all_pieces.append(grid[col][row])
				grid[col][row] = null
	
	var success := false
	var attempts := 0
	
	while not success and attempts < 100:
		attempts += 1
		all_pieces.shuffle()
		
		# Place into grid
		var idx := 0
		for col in columns:
			for row in rows:
				grid[col][row] = all_pieces[idx]
				idx += 1
		
		# Check invariants: 0 immediate matches and at least 1 valid move
		if _find_matches().is_empty() and has_valid_moves():
			success = true
			break
	
	# If permutation failed, safely reassign piece types
	if not success:
		var available := _get_available_pieces()
		var p_idx := 0
		for col in columns:
			for row in rows:
				var piece: Piece = all_pieces[p_idx]
				p_idx += 1
				
				var valid_pieces := available.duplicate()
				if col >= 2:
					var p1: Piece = grid[col - 1][row]
					var p2: Piece = grid[col - 2][row]
					if p1 and p2 and p1.piece_type == p2.piece_type:
						valid_pieces = valid_pieces.filter(func(pd): return pd.piece_id != p1.piece_type)
				if row >= 2:
					var p1: Piece = grid[col][row - 1]
					var p2: Piece = grid[col][row - 2]
					if p1 and p2 and p1.piece_type == p2.piece_type:
						valid_pieces = valid_pieces.filter(func(pd): return pd.piece_id != p1.piece_type)
				if valid_pieces.is_empty():
					valid_pieces = available.duplicate()
				
				var chosen: PieceData = valid_pieces[randi() % valid_pieces.size()]
				piece.setup(chosen, Vector2i(col, row), cell_size)
				grid[col][row] = piece
	
	# Animate all pieces with scale pop & slide to new grid locations
	for col in columns:
		for row in rows:
			var piece: Piece = grid[col][row]
			if piece:
				piece.grid_position = Vector2i(col, row)
				var target := _grid_to_world(col, row)
				var tween := create_tween()
				tween.tween_property(piece, "scale", Vector2(0.5, 0.5), 0.1)
				tween.tween_property(piece, "position", target, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(piece, "scale", Vector2.ONE, 0.15)
	
	EventBus.board_shuffled.emit()


## ===== WIN / LOSE HANDLERS =====

func _on_objective_complete() -> void:
	# Objective met — the cascade loop handles this
	pass


func _on_moves_exhausted() -> void:
	# Moves ran out — the cascade loop handles the lose check after resolution
	pass
