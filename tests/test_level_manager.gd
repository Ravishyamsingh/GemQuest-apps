# test_level_manager.gd — Unit tests for level JSON files and data validity.
class_name TestLevelManager
extends RefCounted

static func run_all_tests() -> Dictionary:
	var results := {"passed": 0, "failed": 0, "errors": []}
	
	var total_levels := 20
	for i in range(1, total_levels + 1):
		var path := "res://resources/levels/level_%03d.json" % i
		if not FileAccess.file_exists(path):
			results["failed"] += 1
			results["errors"].append("Missing level file: %s" % path)
			continue
		
		var file := FileAccess.open(path, FileAccess.READ)
		var text := file.get_as_text()
		file.close()
		
		var json := JSON.new()
		if json.parse(text) != OK:
			results["failed"] += 1
			results["errors"].append("Invalid JSON in: %s" % path)
			continue
		
		var data: Dictionary = json.data
		var required_keys := ["level_id", "grid_columns", "grid_rows", "max_moves", "objective_type", "target_score", "available_piece_ids"]
		var all_keys := true
		for k in required_keys:
			if not data.has(k):
				all_keys = false
				results["failed"] += 1
				results["errors"].append("Level %d missing key: %s" % [i, k])
				break
		
		if all_keys:
			results["passed"] += 1
			
	return results
