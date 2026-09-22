# match_detector.gd — Scans the grid for horizontal and vertical matches of 3+.
# Pure logic — no scene tree access. Operates on grid data only.
extends RefCounted
class_name MatchDetector

## Scan the entire grid and return an Array of MatchResult objects.
## grid: Array[Array] — 2D array where grid[col][row] holds a piece (or null).
## get_type: Callable — function(piece) -> StringName, returns the piece type.
static func find_all_matches(grid: Array, columns: int, rows: int, get_type: Callable) -> Array:
	var horizontal_matches := _find_horizontal(grid, columns, rows, get_type)
	var vertical_matches := _find_vertical(grid, columns, rows, get_type)
	var all_matches := horizontal_matches + vertical_matches
	return _merge_overlapping(all_matches)


## Find horizontal matches (3+ in a row).
static func _find_horizontal(grid: Array, columns: int, rows: int, get_type: Callable) -> Array:
	var matches: Array = []
	for row in rows:
		var run_start := 0
		var run_type: StringName = &""
		for col in columns:
			var piece = grid[col][row]
			var p_type: StringName = get_type.call(piece) if piece != null else &""
			if p_type == run_type and p_type != &"":
				continue  # Extend the current run
			else:
				# End of run — check if it was 3+
				var run_length := col - run_start
				if run_length >= 3 and run_type != &"":
					var positions: Array = []
					for c in range(run_start, col):
						positions.append(Vector2i(c, row))
					matches.append(MatchResult.create(positions, "horizontal", run_type))
				run_start = col
				run_type = p_type
		# Check the last run in the row
		var final_run_length := columns - run_start
		if final_run_length >= 3 and run_type != &"":
			var positions: Array = []
			for c in range(run_start, columns):
				positions.append(Vector2i(c, row))
			matches.append(MatchResult.create(positions, "horizontal", run_type))
	return matches


## Find vertical matches (3+ in a column).
static func _find_vertical(grid: Array, columns: int, rows: int, get_type: Callable) -> Array:
	var matches: Array = []
	for col in columns:
		var run_start := 0
		var run_type: StringName = &""
		for row in rows:
			var piece = grid[col][row]
			var p_type: StringName = get_type.call(piece) if piece != null else &""
			if p_type == run_type and p_type != &"":
				continue
			else:
				var run_length := row - run_start
				if run_length >= 3 and run_type != &"":
					var positions: Array = []
					for r in range(run_start, row):
						positions.append(Vector2i(col, r))
					matches.append(MatchResult.create(positions, "vertical", run_type))
				run_start = row
				run_type = p_type
		var final_run_length := rows - run_start
		if final_run_length >= 3 and run_type != &"":
			var positions: Array = []
			for r in range(run_start, rows):
				positions.append(Vector2i(col, r))
			matches.append(MatchResult.create(positions, "vertical", run_type))
	return matches


## Merge overlapping matches of the same type (e.g., T/L/cross shapes).
## Two matches overlap if they share at least one position AND have the same piece type.
static func _merge_overlapping(matches: Array) -> Array:
	if matches.is_empty():
		return []

	var merged: Array = []
	var used: Array = []  # Track which matches have been merged
	used.resize(matches.size())
	used.fill(false)

	for i in matches.size():
		if used[i]:
			continue
		var current: MatchResult = matches[i]
		var current_positions := {}  # Dictionary used as a set
		for pos in current.positions:
			current_positions[pos] = true

		# Try to merge with subsequent matches
		var did_merge := true
		while did_merge:
			did_merge = false
			for j in range(i + 1, matches.size()):
				if used[j]:
					continue
				var other: MatchResult = matches[j]
				if other.piece_type != current.piece_type:
					continue
				# Check for overlap
				var overlaps := false
				for pos in other.positions:
					if current_positions.has(pos):
						overlaps = true
						break
				if overlaps:
					# Merge positions
					for pos in other.positions:
						current_positions[pos] = true
					used[j] = true
					did_merge = true

		# Build merged result
		var final_positions: Array = current_positions.keys()
		var dir := "complex" if final_positions.size() > current.positions.size() else current.direction
		merged.append(MatchResult.create(final_positions, dir, current.piece_type))

	return merged
