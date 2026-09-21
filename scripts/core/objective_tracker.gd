# objective_tracker.gd — Tracks progress toward the current level's objective.
# MVP supports "score_target" only. Extensible for future objective types.
extends Node

var objective_type: String = "score_target"
var target_value: int = 0
var current_value: int = 0
var is_complete: bool = false


func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)


## Initialise with level data.
func setup(level_data: Dictionary) -> void:
	objective_type = level_data.get("objective_type", "score_target")
	target_value = level_data.get("target_score", 1000)
	current_value = 0
	is_complete = false
	EventBus.objective_progress.emit(current_value, target_value)


## Reset tracker.
func reset() -> void:
	current_value = 0
	is_complete = false


## Called when score changes (for score_target objective).
func _on_score_changed(new_score: int, _delta: int) -> void:
	if objective_type != "score_target":
		return
	current_value = new_score
	EventBus.objective_progress.emit(current_value, target_value)
	if current_value >= target_value and not is_complete:
		is_complete = true
		EventBus.objective_complete.emit()
