# save_manager.gd — Handles local save/load of player progress and settings.
# Uses JSON serialisation to user:// directory.
# Designed with an abstract interface so a CloudSaveManager can wrap it later.
extends Node

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

## In-memory save data
var data: Dictionary = {}


func _ready() -> void:
	load_game()


## ----- Public API -----

## Save current data to disk.
func save_game() -> void:
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_warning("SaveManager: Could not write to %s" % SAVE_PATH)


## Load saved data from disk. Creates defaults if no save exists.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_create_default_data()
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Could not open %s — using defaults." % SAVE_PATH)
		_create_default_data()
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_warning("SaveManager: JSON parse error — using defaults.")
		_create_default_data()
		return

	data = json.data
	# Validate version for future migration
	if not data.has("version"):
		data["version"] = SAVE_VERSION


## Mark a level as completed, record score and stars, unlock next.
func complete_level(level_id: int, score: int, stars: int = 1) -> void:
	var key := str(level_id)
	if not data["completed_levels"].has(key):
		data["completed_levels"][key] = {"best_score": score, "stars": stars, "completed": true}
	else:
		var existing: Dictionary = data["completed_levels"][key]
		existing["completed"] = true
		if score > existing.get("best_score", 0):
			existing["best_score"] = score
		if stars > existing.get("stars", 0):
			existing["stars"] = stars

	# Unlock next level
	if level_id >= data["current_level"]:
		data["current_level"] = level_id + 1

	save_game()


## Get stars earned for a level (0 to 3).
func get_level_stars(level_id: int) -> int:
	var key := str(level_id)
	if data["completed_levels"].has(key):
		return data["completed_levels"][key].get("stars", 0)
	return 0


## Get the best score for a level, or 0 if not completed.
func get_best_score(level_id: int) -> int:
	var key := str(level_id)
	if data["completed_levels"].has(key):
		return data["completed_levels"][key].get("best_score", 0)
	return 0


## Check if a level is unlocked (completed or current).
func is_level_unlocked(level_id: int) -> bool:
	return level_id <= data.get("current_level", 1)


## Check if a level has been completed.
func is_level_completed(level_id: int) -> bool:
	var key := str(level_id)
	return data["completed_levels"].has(key) and data["completed_levels"][key].get("completed", false)


## Get the current (furthest unlocked) level.
func get_current_level() -> int:
	return data.get("current_level", 1)


## Update a setting and persist.
func update_setting(key: String, value) -> void:
	data["settings"][key] = value
	save_game()


## Get a setting value.
func get_setting(key: String, default_value = null):
	return data["settings"].get(key, default_value)


## Reset all progress (debug / settings).
func reset_progress() -> void:
	_create_default_data()
	save_game()


## ----- Private -----

func _create_default_data() -> void:
	data = {
		"version": SAVE_VERSION,
		"current_level": 1,
		"completed_levels": {},
		"settings": {
			"sfx_enabled": true,
			"music_enabled": true,
			"vibration_enabled": true,
		},
		"total_play_time": 0.0,
	}
