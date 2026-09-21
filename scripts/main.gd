# main.gd — Root scene controller.
# Manages screen transitions by swapping child screen nodes.
extends Node

## Preloaded screen scenes
const SCREENS := {
	"splash": preload("res://scenes/screens/splash_screen.tscn"),
	"home": preload("res://scenes/screens/home_screen.tscn"),
	"level_map": preload("res://scenes/screens/level_map_screen.tscn"),
	"gameplay": preload("res://scenes/screens/gameplay_screen.tscn"),
	"settings": preload("res://scenes/screens/settings_screen.tscn"),
}

## Currently displayed screen node
var _current_screen: Node = null

## Transition overlay for fade effects
@onready var _transition_overlay: ColorRect = $TransitionOverlay


func _ready() -> void:
	EventBus.screen_change_requested.connect(_on_screen_change_requested)
	# Start with splash screen
	_show_screen("splash")


## Handle screen change requests from GameManager / other systems.
func _on_screen_change_requested(screen_name: String) -> void:
	if not SCREENS.has(screen_name):
		push_error("Main: Unknown screen '%s'" % screen_name)
		return
	_transition_to_screen(screen_name)


## Simple fade transition between screens.
func _transition_to_screen(screen_name: String) -> void:
	# Fade out
	if _transition_overlay:
		var tween := create_tween()
		tween.tween_property(_transition_overlay, "color:a", 1.0, 0.15)
		await tween.finished

	# Swap screen
	_show_screen(screen_name)

	# Fade in
	if _transition_overlay:
		var tween := create_tween()
		tween.tween_property(_transition_overlay, "color:a", 0.0, 0.15)


## Instantiate and display a screen, removing the old one.
func _show_screen(screen_name: String) -> void:
	if _current_screen:
		_current_screen.queue_free()
		_current_screen = null

	var screen_scene: PackedScene = SCREENS[screen_name]
	_current_screen = screen_scene.instantiate()
	# Insert before the transition overlay so overlay renders on top
	add_child(_current_screen)
	if _transition_overlay:
		move_child(_transition_overlay, get_child_count() - 1)

	GameManager.current_screen = _current_screen
