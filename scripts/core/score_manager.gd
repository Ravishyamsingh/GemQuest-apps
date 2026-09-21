# score_manager.gd — Calculates and tracks the score for the current level.
# Scoring formula (from PRD §6.5):
#   Match of 3: 3 × 10 = 30
#   Match of 4: 4 × 15 = 60
#   Match of 5: 5 × 20 = 100
#   Cascade multiplier: 1st = ×1, 2nd = ×2, 3rd = ×3, etc.
extends Node

## Current score for this level
var current_score: int = 0


func _ready() -> void:
	pass


## Reset score for a new level.
func reset() -> void:
	current_score = 0
	EventBus.score_changed.emit(current_score, 0)


## Calculate score for a set of matches at a given cascade depth.
## Returns the total points added.
func add_match_score(matches: Array, cascade_depth: int) -> int:
	var base_score := 0
	for match_result in matches:
		base_score += _calculate_match_points(match_result.length)

	var multiplier := maxi(cascade_depth, 1)
	var total := base_score * multiplier
	current_score += total
	EventBus.score_changed.emit(current_score, total)
	return total


## Points for a single match based on length.
func _calculate_match_points(length: int) -> int:
	match length:
		3: return 30   # 3 × 10
		4: return 60   # 4 × 15
		5: return 100  # 5 × 20
		_:
			# 6+ pieces: 20 per piece (generous scaling)
			if length > 5:
				return length * 20
			return 0
