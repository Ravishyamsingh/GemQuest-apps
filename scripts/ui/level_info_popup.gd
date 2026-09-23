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
@onready var _difficulty_val: Label = $CardPanel/MarginContainer/VBoxContainer/StatsCard/VBox/DifficultyRow/DifficultyValue
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
	# Keep the pre-level card usable on narrow portrait devices too.
	var viewport_size := get_viewport_rect().size
	var card_width := minf(500.0, maxf(280.0, viewport_size.x - 28.0))
	var card_height := minf(520.0, maxf(440.0, viewport_size.y - 32.0))
	if _card_panel:
		_card_panel.custom_minimum_size = Vector2(card_width, card_height)
		_card_panel.offset_left = -card_width * 0.5
		_card_panel.offset_right = card_width * 0.5
		_card_panel.offset_top = -card_height * 0.5
		_card_panel.offset_bottom = card_height * 0.5
		_card_panel.pivot_offset = Vector2(card_width * 0.5, card_height * 0.5)
	
	# Fetch level data
	var data: Dictionary = LevelManager.get_level_data(level_id)
	var target_score: int = data.get("target_score", 500)
	var max_moves: int = data.get("max_moves", 25)
	var difficulty: int = clampi(data.get("difficulty", 1), 1, 10)
	var stars: int = SaveManager.get_level_stars(level_id)
	var best_score: int = SaveManager.get_best_score(level_id)
	
	# Update labels
	if _level_title:
		_level_title.text = "LEVEL %d" % level_id
	if _target_val:
		_target_val.text = "%d pts" % target_score
	if _moves_val:
		_moves_val.text = "%d moves" % max_moves
	if _difficulty_val:
		_difficulty_val.text = "%d / 10" % difficulty
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
	if _play_btn:
		var press_tween := create_tween()
		press_tween.tween_property(_play_btn, "scale", Vector2(0.94, 0.94), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		press_tween.tween_property(_play_btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		press_tween.tween_callback(_start_selected_level)
	else:
		_start_selected_level()


func _start_selected_level() -> void:
	play_requested.emit(current_level_id)
	# Main's fade transition now covers the final modal close frame, keeping the
	# level start from feeling like an instantaneous scene replacement.
	LevelManager.start_level(current_level_id)
	queue_free()
