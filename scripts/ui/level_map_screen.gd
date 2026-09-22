# level_map_screen.gd — Curved path level saga map screen.
extends Control

const TOTAL_LEVELS := 20
const MAP_WIDTH := 720.0
const MAP_HEIGHT := 2600.0

@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _map_content: Control = $ScrollContainer/MapContent
@onready var _path_line: Line2D = $ScrollContainer/MapContent/PathLine
@onready var _nodes_container: Control = $ScrollContainer/MapContent/NodesContainer
@onready var _back_btn: Button = $TopBar/BackButton
@onready var _stars_label: Label = $TopBar/StarsLabel

var level_node_scene: PackedScene = preload("res://scenes/ui/level_node.tscn")
var level_info_popup_scene: PackedScene = preload("res://scenes/ui/level_info_popup.tscn")
var _node_positions: Array[Vector2] = []
var _active_popup: LevelInfoPopup = null


func _ready() -> void:
	if _back_btn:
		_back_btn.pressed.connect(_on_back_pressed)
	
	_update_header()
	_generate_map_path()
	_populate_level_nodes()
	
	# Defer auto-scrolling to ensure container layout has resolved
	call_deferred("_scroll_to_current_level")


func _update_header() -> void:
	var total_stars := 0
	for i in range(1, TOTAL_LEVELS + 1):
		total_stars += SaveManager.get_level_stars(i)
	if _stars_label:
		_stars_label.text = "★ %d / %d" % [total_stars, TOTAL_LEVELS * 3]


func _on_back_pressed() -> void:
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")


## Generate the S-curve winding path coordinates for all 20 levels.
func _generate_map_path() -> void:
	_node_positions.clear()
	
	# Levels go from Level 1 at bottom (Y ~ 2400) to Level 20 at top (Y ~ 200)
	var bottom_y := MAP_HEIGHT - 200.0
	var top_y := 200.0
	var y_step := (bottom_y - top_y) / float(TOTAL_LEVELS - 1)
	
	for i in range(TOTAL_LEVELS):
		var level_idx := i # 0 is Level 1, 19 is Level 20
		var y := bottom_y - (level_idx * y_step)
		
		# Winding S-curve horizontal wave
		var wave := sin(float(level_idx) * 0.9) # oscillates between -1 and 1
		var x := (MAP_WIDTH * 0.5) + wave * 220.0
		
		_node_positions.append(Vector2(x, y))

	# Setup the Line2D visual path
	if _path_line:
		_path_line.clear_points()
		_path_line.width = 16.0
		_path_line.default_color = Color(1.0, 0.85, 0.3, 0.65) # Warm gold glow
		
		# Sample smooth intermediate curve points using cubic interpolation
		for i in range(_node_positions.size()):
			_path_line.add_point(_node_positions[i])


## Instantiate LevelNode scenes along the path.
func _populate_level_nodes() -> void:
	for child in _nodes_container.get_children():
		child.queue_free()

	var current_lvl := SaveManager.get_current_level()

	for i in range(TOTAL_LEVELS):
		var level_id := i + 1
		var pos := _node_positions[i]
		
		var node: LevelNode = level_node_scene.instantiate()
		_nodes_container.add_child(node)
		node.position = pos - Vector2(40, 40) # Center 80x80 node on pos
		
		var unlocked := SaveManager.is_level_unlocked(level_id)
		var completed := SaveManager.is_level_completed(level_id)
		var is_curr := (level_id == current_lvl)
		var stars := SaveManager.get_level_stars(level_id)
		
		node.setup(level_id, unlocked, completed, is_curr, stars)
		node.level_selected.connect(_on_level_selected)


func _on_level_selected(level_id: int) -> void:
	if _active_popup and is_instance_valid(_active_popup):
		_active_popup.queue_free()
		_active_popup = null
	
	_active_popup = level_info_popup_scene.instantiate()
	add_child(_active_popup)
	_active_popup.setup_and_show(level_id)
	_active_popup.popup_closed.connect(func(): _active_popup = null)


## Smoothly scroll the view to center on the player's current unlocked level.
func _scroll_to_current_level() -> void:
	var current_lvl := clampi(SaveManager.get_current_level(), 1, TOTAL_LEVELS)
	var current_pos := _node_positions[current_lvl - 1]
	
	# Scroll so current_pos.y is roughly centered in the 1280 screen height
	var target_scroll_y := current_pos.y - 640.0
	target_scroll_y = clampf(target_scroll_y, 0.0, MAP_HEIGHT - 1280.0)
	
	if _scroll_container:
		_scroll_container.scroll_vertical = int(target_scroll_y)
