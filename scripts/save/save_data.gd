# save_data.gd — Data class representing the player's save state.
# Used by SaveManager for serialisation/deserialisation.
class_name SaveData
extends RefCounted

var current_level: int = 1
var completed_levels: Dictionary = {}  # { "level_id_str": { "best_score": int, "completed": bool } }
var settings: Dictionary = {
	"sfx_enabled": true,
	"music_enabled": true,
	"vibration_enabled": true,
}
var total_play_time: float = 0.0
var version: int = 1  # Save format version for future migration


## Serialise to Dictionary for JSON export.
func to_dict() -> Dictionary:
	return {
		"version": version,
		"current_level": current_level,
		"completed_levels": completed_levels,
		"settings": settings,
		"total_play_time": total_play_time,
	}


## Populate from a parsed JSON Dictionary.
static func from_dict(data: Dictionary) -> SaveData:
	var save := SaveData.new()
	save.version = data.get("version", 1)
	save.current_level = data.get("current_level", 1)
	save.completed_levels = data.get("completed_levels", {})
	save.settings = data.get("settings", {
		"sfx_enabled": true,
		"music_enabled": true,
		"vibration_enabled": true,
	})
	save.total_play_time = data.get("total_play_time", 0.0)
	return save
