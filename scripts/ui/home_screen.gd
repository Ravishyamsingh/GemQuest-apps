# home_screen.gd — Polished main menu with ambient floating gems, pulse animations, and audio.
extends Control

@onready var _play_btn: Button = $Content/PlayButton
@onready var _settings_btn: Button = $TopBar/SettingsButton
@onready var _progress_label: Label = $Content/ProgressPill/ProgressMargin/ProgressLabel
@onready var _logo_icon: TextureRect = $Content/LogoIcon
@onready var _floating_container: Control = $FloatingGemsContainer

var _pulse_tween: Tween = null
var _floating_gem_textures: Array[Texture2D] = []


func _ready() -> void:
	if _play_btn:
		_play_btn.pressed.connect(_on_play_pressed)
	if _settings_btn:
		_settings_btn.pressed.connect(_on_settings_pressed)
	
	_load_gem_textures()
	_update_progress()
	_animate_ui()
	_spawn_floating_background_gems()
	
	# Start menu background music
	if AudioManager:
		AudioManager.play_menu_music()


func _load_gem_textures() -> void:
	var paths := [
		"res://assets/graphics/pieces/gem_diamond.png",
		"res://assets/graphics/pieces/gem_ruby.png",
		"res://assets/graphics/pieces/gem_sapphire.png",
		"res://assets/graphics/pieces/gem_emerald.png",
		"res://assets/graphics/pieces/gem_topaz.png",
		"res://assets/graphics/pieces/gem_amethyst.png",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			_floating_gem_textures.append(load(path))


func _update_progress() -> void:
	var cur_lvl := SaveManager.get_current_level()
	var total_stars := 0
	for i in range(1, 21):
		total_stars += SaveManager.get_level_stars(i)
	if _progress_label:
		_progress_label.text = "Level %d Unlocked  •  ★ %d Stars" % [cur_lvl, total_stars]


func _animate_ui() -> void:
	# Pulsing play button
	if _play_btn:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(_play_btn, "scale", Vector2(1.05, 1.05), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_property(_play_btn, "scale", Vector2(1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Gentle floating logo icon
	if _logo_icon:
		var logo_tween := create_tween().set_loops()
		logo_tween.tween_property(_logo_icon, "position:y", _logo_icon.position.y - 8.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		logo_tween.tween_property(_logo_icon, "position:y", _logo_icon.position.y + 4.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Spawn gentle floating background gems
func _spawn_floating_background_gems() -> void:
	if not _floating_container or _floating_gem_textures.is_empty():
		return
	
	var screen_w := 720.0
	var screen_h := 1280.0
	var count := 8
	
	for i in range(count):
		var tr := TextureRect.new()
		var tex: Texture2D = _floating_gem_textures[i % _floating_gem_textures.size()]
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var sz := randf_range(36.0, 56.0)
		tr.custom_minimum_size = Vector2(sz, sz)
		tr.size = Vector2(sz, sz)
		tr.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
		
		var start_x := randf_range(40.0, screen_w - 60.0)
		var start_y := randf_range(80.0, screen_h - 100.0)
		tr.position = Vector2(start_x, start_y)
		tr.modulate = Color(1.0, 1.0, 1.0, randf_range(0.2, 0.45))
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		_floating_container.add_child(tr)
		
		# Drifting animation
		var drift_dur := randf_range(3.0, 6.0)
		var drift_y := randf_range(25.0, 50.0) * (-1.0 if i % 2 == 0 else 1.0)
		var drift_rot := randf_range(-0.3, 0.3)
		
		var tween := create_tween().set_loops()
		tween.set_parallel(true)
		tween.tween_property(tr, "position:y", start_y + drift_y, drift_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(tr, "rotation", drift_rot, drift_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		tween.chain().set_parallel(true)
		tween.tween_property(tr, "position:y", start_y, drift_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(tr, "rotation", 0.0, drift_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_play_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	var tween := create_tween()
	tween.tween_property(_play_btn, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(_play_btn, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(func(): GameManager.go_to_level_map())


func _on_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_by_name("click")
	
	if _settings_btn:
		var rot_tween := create_tween()
		rot_tween.tween_property(_settings_btn, "rotation", PI, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		rot_tween.tween_callback(func(): GameManager.change_screen("settings"))
	else:
		GameManager.change_screen("settings")
