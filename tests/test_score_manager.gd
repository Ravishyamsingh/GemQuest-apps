# test_score_manager.gd — Unit tests for scoring calculations.
class_name TestScoreManager
extends RefCounted

static func run_all_tests() -> Dictionary:
	var results := {"passed": 0, "failed": 0, "errors": []}
	
	# Test Match-3 (30 pts)
	var m3 := MatchResult.new()
	m3.length = 3
	m3.positions = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]
	
	var sm = load("res://scripts/core/score_manager.gd").new()
	var score1 := sm.calculate_matches_score([m3], 1)
	if score1 == 30:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_score_m3 failed: expected 30, got %d" % score1)
	
	# Test Match-4 (60 pts)
	var m4 := MatchResult.new()
	m4.length = 4
	m4.positions = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]
	var score2 := sm.calculate_matches_score([m4], 1)
	if score2 == 60:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_score_m4 failed: expected 60, got %d" % score2)

	# Test Match-5 (100 pts)
	var m5 := MatchResult.new()
	m5.length = 5
	m5.positions = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)]
	var score3 := sm.calculate_matches_score([m5], 1)
	if score3 == 100:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_score_m5 failed: expected 100, got %d" % score3)

	# Test Cascade depth multiplier (Cascade 2 = 2x multiplier)
	var score_cascade := sm.calculate_matches_score([m3], 2)
	if score_cascade == 60: # 30 * 2
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("test_score_cascade failed: expected 60, got %d" % score_cascade)
		
	return results
