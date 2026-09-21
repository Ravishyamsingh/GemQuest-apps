# game_manager.gd — Global game state manager and scene-transition controller.
# Manages which screen is active, holds the current level reference, and
# orchestrates transitions between screens.
extends Node

## The currently active screen node (child of Main scene).
var current_screen: Node = null

## The current level data being played (set by LevelManager before gameplay starts).
var current_level_data = null  # Will be typed as LevelData once defined

## Game-wide state
enum GameState { SPLASH, HOME, LEVEL_MAP, GAMEPLAY, PAUSED }
var state: GameState = GameState.SPLASH


func _ready() -> void:
	pass


## Request a screen transition. The Main scene listens for this
## and swaps the visible screen node.
func change_screen(screen_name: String) -> void:
	EventBus.screen_change_requested.emit(screen_name)


## Store the level data that will be used when GameplayScreen initialises.
func set_current_level(level_data) -> void:
	current_level_data = level_data


## Convenience — return to the level map.
func go_to_level_map() -> void:
	state = GameState.LEVEL_MAP
	change_screen("level_map")


## Convenience — start gameplay for the current level.
func start_gameplay() -> void:
	state = GameState.GAMEPLAY
	change_screen("gameplay")
