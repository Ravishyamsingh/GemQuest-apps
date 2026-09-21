# match_result.gd — Data class representing a single match found on the board.
class_name MatchResult
extends RefCounted

## All grid positions involved in this match.
var positions: Array = []  # Array of Vector2i

## Number of matched pieces.
var length: int = 0

## Direction: "horizontal", "vertical", or "complex" (T/L/cross shapes).
var direction: String = ""

## The piece type that was matched.
var piece_type: StringName = &""


## Factory method to create a MatchResult.
static func create(pos_array: Array, dir: String, p_type: StringName) -> MatchResult:
	var result := MatchResult.new()
	result.positions = pos_array
	result.length = pos_array.size()
	result.direction = dir
	result.piece_type = p_type
	return result
