# splash_screen.gd — Polished brand splash screen with emblem animations.
extends Control

const SPLASH_DURATION := 2.2

@onready var _center_container: VBoxContainer = $CenterContainer
@onready var _gem_center: TextureRect = $CenterContainer/Crest/GemCenter


func _ready() -> void:
	modulate.a = 0.0
	_center_container.scale = Vector2(0.8, 0.8)
	
	# Entry animation
	var intro_tween := create_tween().set_parallel(true)
	intro_tween.tween_property(self, "modulate:a", 1.0, 0.45)
	intro_tween.tween_property(_center_container, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Crest gem floating idle
	if _gem_center:
		var gem_tween := create_tween().set_loops()
		gem_tween.tween_property(_gem_center, "position:y", -46.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		gem_tween.tween_property(_gem_center, "position:y", -40.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Schedule transition to Home
	get_tree().create_timer(SPLASH_DURATION).timeout.connect(_transition_to_home)


func _transition_to_home() -> void:
	var out_tween := create_tween()
	out_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	await out_tween.finished
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")
