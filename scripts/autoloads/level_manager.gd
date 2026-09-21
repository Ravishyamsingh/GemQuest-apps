# level_manager.gd — Loads and provides level data from resource files.
# Levels are stored as JSON in res://resources/levels/ and loaded on demand.
extends Node

## Path to the directory containing level JSON files.
const LEVELS_DIR := "res://resources/levels/"

## Total number of levels available in the game.
var total_levels: int = 0

## Cache of loaded level data (Dictionary keyed by level_id).
var _level_cache: Dictionary = {}


func _ready() -> void:
	_count_levels()


## Load a level's data by its ID. Returns a Dictionary or null.
func get_level_data(level_id: int) -> Dictionary:
	if _level_cache.has(level_id):
		return _level_cache[level_id]

	var path := LEVELS_DIR + "level_%03d.json" % level_id
	if not FileAccess.file_exists(path):
		push_warning("LevelManager: Level file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("LevelManager: Could not open: %s" % path)
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var result := json.parse(json_text)
	if result != OK:
		push_warning("LevelManager: JSON parse error in %s" % path)
		return {}

	var level_data: Dictionary = json.data
	_level_cache[level_id] = level_data
	return level_data


## Start a level — set it in GameManager and transition to gameplay.
func start_level(level_id: int) -> void:
	var level_data := get_level_data(level_id)
	if level_data.is_empty():
		push_error("LevelManager: Cannot start level %d — data not found." % level_id)
		return
	GameManager.set_current_level(level_data)
	EventBus.level_started.emit(level_id)
	GameManager.start_gameplay()


## Get the total number of levels.
func get_total_levels() -> int:
	return total_levels


## Clear the cache (useful after downloading new levels in the future).
func clear_cache() -> void:
	_level_cache.clear()


## Count how many level files exist.
func _count_levels() -> void:
	total_levels = 0
	var id := 1
	while FileAccess.file_exists(LEVELS_DIR + "level_%03d.json" % id):
		total_levels = id
		id += 1
