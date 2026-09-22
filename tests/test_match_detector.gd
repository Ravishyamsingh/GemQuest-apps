# test_match_detector.gd — Unit tests for MatchDetector algorithm.
# Tests horizontal, vertical, L, T, and cross matches.
class_name TestMatchDetector
extends RefCounted

static func run_all_tests() -> Dictionary:
	var results := {"passed": 0, "failed": 0, "errors": []}
	
	_test_horizontal_match_3(results)
	_test_vertical_match_3(results)
	_test_horizontal_match_5(results)
	_test_t_shape_match(results)
	_test_l_shape_match(results)
	_test_no_matches(results)
	
	return results


static func _test_horizontal_match_3(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(&"diamond" if (r == 0 and c < 3) else StringName("gem_%d_%d" % [c, r]))
		grid.append(col)
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(cell): return cell)
	if matches.size() == 1 and matches[0].length == 3:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_horizontal_match_3 failed: expected 1 match of length 3, got %d" % matches.size())


static func _test_vertical_match_3(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(&"ruby" if (c == 2 and r < 3) else StringName("gem_%d_%d" % [c, r]))
		grid.append(col)
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(cell): return cell)
	if matches.size() == 1 and matches[0].length == 3:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_vertical_match_3 failed: expected 1 match of length 3")


static func _test_horizontal_match_5(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(&"emerald" if (r == 4 and c >= 1 and c <= 5) else StringName("gem_%d_%d" % [c, r]))
		grid.append(col)
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(cell): return cell)
	if matches.size() == 1 and matches[0].length == 5:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_horizontal_match_5 failed: expected match of length 5")


static func _test_t_shape_match(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(StringName("gem_%d_%d" % [c, r]))
		grid.append(col)
	
	# Horizontal: (2,2), (3,2), (4,2)
	# Vertical: (3,1), (3,2), (3,3)
	grid[2][2] = &"sapphire"
	grid[3][2] = &"sapphire"
	grid[4][2] = &"sapphire"
	grid[3][1] = &"sapphire"
	grid[3][3] = &"sapphire"
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(cell): return cell)
	if matches.size() == 1 and matches[0].positions.size() == 5:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_t_shape_match failed: expected merged T-match of 5 positions")


static func _test_l_shape_match(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	for c in cols:
		var col := []
		for r in rows:
			col.append(StringName("gem_%d_%d" % [c, r]))
		grid.append(col)
	
	# Horizontal: (0,0), (1,0), (2,0)
	# Vertical: (0,0), (0,1), (0,2)
	grid[0][0] = &"topaz"
	grid[1][0] = &"topaz"
	grid[2][0] = &"topaz"
	grid[0][1] = &"topaz"
	grid[0][2] = &"topaz"
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(cell): return cell)
	if matches.size() == 1 and matches[0].positions.size() == 5:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_l_shape_match failed: expected merged L-match of 5 positions")


static func _test_no_matches(results: Dictionary) -> void:
	var cols := 8
	var rows := 8
	var grid := []
	var gem_types := [&"diamond", &"ruby"]
	for c in cols:
		var col := []
		for r in rows:
			col.append(gem_types[(c + r) % 2])
		grid.append(col)
	
	var matches := MatchDetector.find_all_matches(grid, cols, rows, func(cell): return cell)
	if matches.is_empty():
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_no_matches failed: expected 0 matches")
