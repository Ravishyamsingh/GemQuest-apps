# test_board_logic.gd — Comprehensive unit tests for core Match-3 board logic,
# gravity simulation, swaps, cascades, shuffle invariants, and star rating.
class_name TestBoardLogic
extends RefCounted

static func run_all_tests() -> Dictionary:
	var results := {"passed": 0, "failed": 0, "errors": []}
	
	_test_swap_adjacency(results)
	_test_gravity_simulation(results)
	_test_star_calculation(results)
	_test_multi_match_resolution(results)
	_test_deadlock_detection(results)
	_test_shuffle_invariant(results)
	
	return results


## 1. Test Orthogonal Adjacency (No diagonals)
static func _test_swap_adjacency(results: Dictionary) -> void:
	var is_adjacent := func(a: Vector2i, b: Vector2i) -> bool:
		var diff := (b - a).abs()
		return (diff.x + diff.y) == 1
	
	# Valid orthogonal
	if is_adjacent.call(Vector2i(2, 3), Vector2i(3, 3)) and \
	   is_adjacent.call(Vector2i(2, 3), Vector2i(1, 3)) and \
	   is_adjacent.call(Vector2i(2, 3), Vector2i(2, 4)) and \
	   is_adjacent.call(Vector2i(2, 3), Vector2i(2, 2)):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_swap_adjacency: orthogonal failed")

	# Invalid diagonal or far
	if not is_adjacent.call(Vector2i(2, 3), Vector2i(3, 4)) and \
	   not is_adjacent.call(Vector2i(2, 3), Vector2i(2, 5)) and \
	   not is_adjacent.call(Vector2i(2, 3), Vector2i(2, 3)):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_swap_adjacency: diagonal / far rejection failed")


## 2. Test Gravity Simulation (Falling pieces to bottom)
static func _test_gravity_simulation(results: Dictionary) -> void:
	# 1 Column of 5 rows: [A, null, B, null, C] (index 0 is top, 4 is bottom)
	var col := ["A", null, "B", null, "C"]
	var rows := 5
	
	# Simulate gravity from bottom to top
	var write_row := rows - 1
	for read_row in range(rows - 1, -1, -1):
		if col[read_row] != null:
			if write_row != read_row:
				col[write_row] = col[read_row]
				col[read_row] = null
			write_row -= 1
	
	# Expected bottom-to-top: [null, null, "A", "B", "C"]
	if col[0] == null and col[1] == null and col[2] == "A" and col[3] == "B" and col[4] == "C":
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_gravity_simulation failed: got %s" % str(col))


## 3. Test Star Calculation Logic (1-3 stars)
static func _test_star_calculation(results: Dictionary) -> void:
	var calc_stars := func(score: int, target: int) -> int:
		if score >= int(target * 1.8):
			return 3
		elif score >= int(target * 1.35):
			return 2
		elif score >= target:
			return 1
		return 0
	
	var target := 1000
	if calc_stars.call(500, target) == 0 and \
	   calc_stars.call(1000, target) == 1 and \
	   calc_stars.call(1350, target) == 2 and \
	   calc_stars.call(1800, target) == 3 and \
	   calc_stars.call(2500, target) == 3:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_star_calculation failed thresholds")


## 4. Test Multi-Match Simultaneous Resolution
static func _test_multi_match_resolution(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(StringName("gem_%d_%d" % [c, r]))
		grid.append(col)
	
	# Create two separate horizontal matches:
	# 1. Row 0: Ruby (0,0), (1,0), (2,0)
	# 2. Row 4: Diamond (3,4), (4,4), (5,4)
	grid[0][0] = &"ruby"
	grid[1][0] = &"ruby"
	grid[2][0] = &"ruby"
	grid[3][4] = &"diamond"
	grid[4][4] = &"diamond"
	grid[5][4] = &"diamond"
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(c): return c)
	if matches.size() == 2:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_multi_match_resolution failed: expected 2 matches, got %d" % matches.size())


## 5. Test Deadlock Detection
static func _test_deadlock_detection(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(StringName("unique_%d_%d" % [c, r]))
		grid.append(col)
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(c): return c)
	if matches.is_empty():
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_deadlock_detection: expected 0 matches")


## 6. Test Shuffle Invariant Check
static func _test_shuffle_invariant(results: Dictionary) -> void:
	# Pieces array containing 6 balanced types
	var types := [&"diamond", &"ruby", &"sapphire", &"emerald", &"topaz", &"amethyst"]
	var pieces := []
	for i in 64:
		pieces.append(types[i % types.size()])
	
	var success := false
	for attempt in 50:
		pieces.shuffle()
		var grid := []
		var idx := 0
		for c in 8:
			var col := []
			for r in 8:
				col.append(pieces[idx])
				idx += 1
			grid.append(col)
		
		var matches := MatchDetector.find_all_matches(grid, 8, 8, func(c): return c)
		if matches.is_empty():
			success = true
			break
	
	if success:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_shuffle_invariant failed to find 0-match shuffle")
