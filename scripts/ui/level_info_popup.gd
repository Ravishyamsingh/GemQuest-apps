# level_info_popup.gd — Pre-level modal displaying objectives, stars, and play button.
class_name LevelInfoPopup
extends Control

signal play_requested(level_id: int)
signal popup_closed()

@onready var _backdrop: ColorRect = $Backdrop
@onready var _card_panel: PanelContainer = $CardPanel
@onready var _level_title: Label = $CardPanel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var _close_btn: Button = $CardPanel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var _star1: TextureRect = $CardPanel/MarginContainer/VBoxContainer/StarsContainer/Star1
@onready var _star2: TextureRect = $CardPanel/MarginContainer/VBoxContainer/StarsContainer/Star2
@onready var _star3: TextureRect = $CardPanel/MarginContainer/VBoxContainer/StarsContainer/Star3
@onready var _target_val: Label = $CardPanel/MarginContainer/VBoxContainer/StatsCard/VBox/TargetRow/TargetValue
@onready var _moves_val: Label = $CardPanel/MarginContainer/VBoxContainer/StatsCard/VBox/MovesRow/MovesValue
@onready var _best_val: Label = $CardPanel/MarginContainer/VBoxContainer/StatsCard/VBox/BestRow/BestValue
@onready var _play_btn: Button = $CardPanel/MarginContainer/VBoxContainer/PlayButton

var current_level_id: int = 1
var _is_closing: bool = false


func _ready() -> void:
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _play_btn:
		_play_btn.pressed.connect(_on_play_pressed)
	if _backdrop:
		_backdrop.gui_input.connect(_on_backdrop_gui_input)


func setup_and_show(level_id: int) -> void:
	current_level_id = level_id
	_is_closing = false
	
	# Fetch level data
	var data: Dictionary = LevelManager.get_level_data(level_id)
	var target_score: int = data.get("target_score", 500)
	var max_moves: int = data.get("max_moves", 25)
	var stars: int = SaveManager.get_level_stars(level_id)
	var best_score: int = SaveManager.get_best_score(level_id)
	
	# Update labels
	if _level_title:
		_level_title.text = "LEVEL %d" % level_id
	if _target_val:
		_target_val.text = "%d pts" % target_score
	if _moves_val:
		_moves_val.text = "%d moves" % max_moves
	if _best_val:
		_best_val.text = "%d" % best_score if best_score > 0 else "---"
	
	# Update stars
	var star_filled_tex = load("res://assets/graphics/ui/star_filled.png") if ResourceLoader.exists("res://assets/graphics/ui/star_filled.png") else null
	var star_empty_tex = load("res://assets/graphics/ui/star_empty.png") if ResourceLoader.exists("res://assets/graphics/ui/star_empty.png") else null
	
	if _star1: _star1.texture = star_filled_tex if stars >= 1 else star_empty_tex
	if _star2: _star2.texture = star_filled_tex if stars >= 2 else star_empty_tex
	if _star3: _star3.texture = star_filled_tex if stars >= 3 else star_empty_tex
	
	# Animate pop-in
	visible = true
	modulate.a = 0.0
	_card_panel.scale = Vector2(0.75, 0.75)
	_card_panel.pivot_offset = _card_panel.size * 0.5
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(_card_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Trigger sound
	if AudioManager:
		AudioManager.play_sfx_by_name("click")


func close_popup() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(_card_panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	popup_closed.emit()
	queue_free()


func _on_close_pressed() -> void:
	close_popup()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_popup()
	elif event is InputEventScreenTouch and event.pressed:
		close_popup()


func _on_play_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	play_requested.emit(current_level_id)
	LevelManager.start_level(current_level_id)
	queue_free()
