# level_node.gd — Interactive map node representing a single level.
class_name LevelNode
extends Control

signal level_selected(level_id: int)

const NODE_LOCKED: Texture2D = preload("res://assets/graphics/ui/node_locked.png")
const NODE_UNLOCKED: Texture2D = preload("res://assets/graphics/ui/node_unlocked.png")
const NODE_COMPLETED: Texture2D = preload("res://assets/graphics/ui/node_completed.png")
const NODE_CURRENT: Texture2D = preload("res://assets/graphics/ui/node_current.png")
const STAR_FILLED: Texture2D = preload("res://assets/graphics/ui/star_filled.png")
const STAR_EMPTY: Texture2D = preload("res://assets/graphics/ui/star_empty.png")

var level_id: int = 1
var is_unlocked: bool = false
var is_completed: bool = false
var is_current: bool = false
var stars: int = 0
var _phase: float = 0.0
var _idle_tween: Tween = null
var _pulse_tween: Tween = null
var _press_tween: Tween = null
var _selection_pending := false

@onready var _btn: TextureButton = $TextureButton
@onready var _label: Label = $Label
@onready var _stars_container: HBoxContainer = $StarsContainer
@onready var _star1: TextureRect = $StarsContainer/Star1
@onready var _star2: TextureRect = $StarsContainer/Star2
@onready var _star3: TextureRect = $StarsContainer/Star3


func _ready() -> void:
	_phase = float(get_instance_id() % 17) * 0.23
	if _btn:
		_btn.pressed.connect(_on_pressed)
		_btn.focus_mode = Control.FOCUS_NONE


func _process(_delta: float) -> void:
	# A tiny redraw-only shimmer is cheaper than a separate animated shader or
	# particle emitter per node.
	if is_current or is_unlocked:
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004 + _phase)
	if is_current:
		draw_circle(center, 48.0 + pulse * 4.0, Color(1.0, 0.75, 0.24, 0.08 + pulse * 0.07))
		draw_arc(center, 45.0 + pulse * 2.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.44, 0.7), 2.0, true)
	elif is_completed:
		draw_arc(center, 43.0, 0.0, TAU, 28, Color(0.35, 1.0, 0.72, 0.42), 2.0, true)
	elif is_unlocked:
		draw_arc(center, 42.0, 0.0, TAU, 28, Color(0.45, 0.85, 1.0, 0.22), 1.5, true)

	# Two sparse highlight motes provide motion without making the path noisy.
	if is_current or is_unlocked:
		var orbit := Time.get_ticks_msec() * 0.001 + _phase
		for i in range(2):
			var angle := orbit * (0.45 + float(i) * 0.1) + float(i) * PI
			var mote := center + Vector2(cos(angle), sin(angle)) * (49.0 + pulse * 2.0)
			draw_circle(mote, 2.0, Color(1.0, 0.93, 0.66, 0.45))


func setup(id: int, unlocked: bool, completed: bool, current: bool, earned_stars: int = 0) -> void:
	level_id = id
	is_unlocked = unlocked
	is_completed = completed
	is_current = current
	stars = earned_stars
	_selection_pending = false

	if _label:
		_label.text = str(level_id)
		_label.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_unlocked else Color(0.75, 0.78, 0.88, 0.85)

	var texture := NODE_LOCKED
	if is_current:
		texture = NODE_CURRENT
	elif is_completed:
		texture = NODE_COMPLETED
	elif is_unlocked:
		texture = NODE_UNLOCKED
	if _btn:
		_btn.texture_normal = texture
		_btn.texture_hover = texture
		_btn.texture_pressed = texture
		_btn.disabled = not is_unlocked

	if _stars_container:
		_stars_container.visible = is_completed and stars > 0
		if _star1: _star1.texture = STAR_FILLED if stars >= 1 else STAR_EMPTY
		if _star2: _star2.texture = STAR_FILLED if stars >= 2 else STAR_EMPTY
		if _star3: _star3.texture = STAR_FILLED if stars >= 3 else STAR_EMPTY

	_start_idle_motion()
	if is_current:
		_start_pulse()
	else:
		_stop_pulse()
	queue_redraw()


func _start_idle_motion() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	var base_position := position
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "position:y", base_position.y - 3.0, 1.8 + (_phase * 0.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "position:y", base_position.y + 2.0, 1.8 + (_phase * 0.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_pulse() -> void:
	_stop_pulse()
	_pivot_to_center()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	scale = Vector2.ONE


func _pivot_to_center() -> void:
	pivot_offset = size * 0.5


func _on_pressed() -> void:
	if not is_unlocked or _selection_pending:
		return
	_selection_pending = true
	if AudioManager:
		AudioManager.play_sfx_by_name("select")
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	_pivot_to_center()
	_press_tween = create_tween()
	_press_tween.tween_property(_btn, "scale", Vector2(0.9, 0.9), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(_btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_press_tween.tween_callback(func():
		_selection_pending = false
		level_selected.emit(level_id)
	)
