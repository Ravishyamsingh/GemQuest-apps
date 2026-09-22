# level_node.gd — Interactive map node representing a single level.
class_name LevelNode
extends Control

signal level_selected(level_id: int)

var level_id: int = 1
var is_unlocked: bool = false
var is_completed: bool = false
var is_current: bool = false
var stars: int = 0

@onready var _btn: TextureButton = $TextureButton
@onready var _label: Label = $Label
@onready var _stars_container: HBoxContainer = $StarsContainer
@onready var _star1: TextureRect = $StarsContainer/Star1
@onready var _star2: TextureRect = $StarsContainer/Star2
@onready var _star3: TextureRect = $StarsContainer/Star3

var _pulse_tween: Tween = null


func _ready() -> void:
	if _btn:
		_btn.pressed.connect(_on_pressed)


func setup(id: int, unlocked: bool, completed: bool, current: bool, earned_stars: int = 0) -> void:
	level_id = id
	is_unlocked = unlocked
	is_completed = completed
	is_current = current
	stars = earned_stars
	
	if _label:
		_label.text = str(level_id)
	
	# Node texture state
	var node_tex_path := "res://assets/graphics/ui/node_locked.png"
	if is_current:
		node_tex_path = "res://assets/graphics/ui/node_current.png"
	elif is_completed:
		node_tex_path = "res://assets/graphics/ui/node_completed.png"
	elif is_unlocked:
		node_tex_path = "res://assets/graphics/ui/node_unlocked.png"
	
	if ResourceLoader.exists(node_tex_path) and _btn:
		var tex: Texture2D = load(node_tex_path)
		_btn.texture_normal = tex
	
	_btn.disabled = not is_unlocked
	
	# Display stars
	if _stars_container:
		_stars_container.visible = is_completed and stars > 0
		var star_filled_tex = load("res://assets/graphics/ui/star_filled.png") if ResourceLoader.exists("res://assets/graphics/ui/star_filled.png") else null
		var star_empty_tex = load("res://assets/graphics/ui/star_empty.png") if ResourceLoader.exists("res://assets/graphics/ui/star_empty.png") else null
		
		if _star1: _star1.texture = star_filled_tex if stars >= 1 else star_empty_tex
		if _star2: _star2.texture = star_filled_tex if stars >= 2 else star_empty_tex
		if _star3: _star3.texture = star_filled_tex if stars >= 3 else star_empty_tex

	# Pulse animation if current level
	if is_current:
		_start_pulse()
	else:
		_stop_pulse()


func _start_pulse() -> void:
	_stop_pulse()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	scale = Vector2.ONE


func _on_pressed() -> void:
	if not is_unlocked:
		return
	
	# Tap bounce animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): level_selected.emit(level_id))
