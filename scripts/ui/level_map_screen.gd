# level_map_screen.gd — Responsive curved level saga map screen.
extends Control

const TOTAL_LEVELS := 20
const NODE_SIZE := 80.0
const TOP_SAFE_AREA := 100.0
const MIN_MAP_HEIGHT := 2200.0

@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _map_content: Control = $ScrollContainer/MapContent
@onready var _path_glow: Line2D = $ScrollContainer/MapContent/PathGlow
@onready var _path_line: Line2D = $ScrollContainer/MapContent/PathLine
@onready var _decorations: Control = $ScrollContainer/MapContent/Decorations
@onready var _nodes_container: Control = $ScrollContainer/MapContent/NodesContainer
@onready var _back_btn: Button = $TopBar/BackButton
@onready var _stars_label: Label = $TopBar/StarsLabel

var level_node_scene: PackedScene = preload("res://scenes/ui/level_node.tscn")
var level_info_popup_scene: PackedScene = preload("res://scenes/ui/level_info_popup.tscn")
var _node_positions: Array[Vector2] = []
var _active_popup: LevelInfoPopup = null
var _map_size := Vector2(720.0, 2600.0)
var _last_viewport_size := Vector2.ZERO
var _scroll_tween: Tween = null
var _decoration_tweens: Array[Tween] = []


func _ready() -> void:
	if _back_btn:
		_back_btn.pressed.connect(_on_back_pressed)
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	_update_header()
	_rebuild_map()

	# Container layout and its scroll range are valid after the first layout pass.
	call_deferred("_scroll_to_current_level", true)


func _on_viewport_size_changed() -> void:
	if get_viewport_rect().size == _last_viewport_size:
		return
	_rebuild_map()
	call_deferred("_scroll_to_current_level", false)


func _rebuild_map() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_last_viewport_size = viewport_size

	# Keep the first level reachable in the initial viewport while giving the
	# full saga enough vertical rhythm to feel like a journey.
	var visible_height := maxf(viewport_size.y - TOP_SAFE_AREA, 480.0)
	var level_step := clampf(visible_height * 0.11, 108.0, 156.0)
	var content_height := maxf(MIN_MAP_HEIGHT, maxf(visible_height + 260.0, 260.0 + level_step * float(TOTAL_LEVELS - 1)))
	_map_size = Vector2(maxf(viewport_size.x, 320.0), content_height)
	if _map_content:
		_map_content.custom_minimum_size = _map_size
		_map_content.size = _map_size

	_generate_map_path()
	_populate_level_nodes()
	_populate_decorations()


func _update_header() -> void:
	var total_stars := 0
	for i in range(1, TOTAL_LEVELS + 1):
		total_stars += SaveManager.get_level_stars(i)
	if _stars_label:
		_stars_label.text = "★ %d / %d" % [total_stars, TOTAL_LEVELS * 3]


func _on_back_pressed() -> void:
	GameManager.state = GameManager.GameState.HOME
	GameManager.change_screen("home")


## Generate centered S-curve coordinates and a sampled smooth path.
func _generate_map_path() -> void:
	_node_positions.clear()
	var center_x := _map_size.x * 0.5
	# Leave enough breathing room for the node radius on narrow phones.
	var amplitude := minf(_map_size.x * 0.30, maxf(0.0, _map_size.x * 0.5 - NODE_SIZE * 0.9))
	var top_y := 150.0
	var bottom_y := _map_size.y - 160.0
	var y_step := (bottom_y - top_y) / float(TOTAL_LEVELS - 1)

	for i in range(TOTAL_LEVELS):
		var wave := sin(float(i) * 0.92 + 0.25)
		_node_positions.append(Vector2(center_x + wave * amplitude, bottom_y - float(i) * y_step))

	var sampled_points: Array[Vector2] = []
	for i in range(_node_positions.size() - 1):
		var p0 := _node_positions[maxi(i - 1, 0)]
		var p1 := _node_positions[i]
		var p2 := _node_positions[i + 1]
		var p3 := _node_positions[mini(i + 2, _node_positions.size() - 1)]
		for step in range(12):
			sampled_points.append(_catmull_rom(p0, p1, p2, p3, float(step) / 12.0))
	sampled_points.append(_node_positions.back())

	if _path_line:
		_path_line.clear_points()
		_path_line.width = clampf(_map_size.x * 0.014, 7.0, 12.0)
		_path_line.default_color = Color(1.0, 0.86, 0.35, 0.58)
		for point in sampled_points:
			_path_line.add_point(point)
	if _path_glow:
		_path_glow.clear_points()
		_path_glow.width = clampf(_map_size.x * 0.04, 18.0, 30.0)
		_path_glow.default_color = Color(0.95, 0.64, 0.2, 0.12)
		for point in sampled_points:
			_path_glow.add_point(point)


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## Instantiate level nodes along the responsive path.
func _populate_level_nodes() -> void:
	if not _nodes_container:
		return
	for child in _nodes_container.get_children():
		child.queue_free()

	var current_lvl := clampi(SaveManager.get_current_level(), 1, TOTAL_LEVELS)
	for i in range(TOTAL_LEVELS):
		var level_id := i + 1
		var node: LevelNode = level_node_scene.instantiate()
		_nodes_container.add_child(node)
		node.position = _node_positions[i] - Vector2(NODE_SIZE * 0.5, NODE_SIZE * 0.5)

		var unlocked := SaveManager.is_level_unlocked(level_id)
		var completed := SaveManager.is_level_completed(level_id)
		node.setup(level_id, unlocked, completed, level_id == current_lvl, SaveManager.get_level_stars(level_id))
		node.level_selected.connect(_on_level_selected)


## Small, pooled-by-scene decorative accents keep the map lively without
## introducing a particle system for every level.
func _populate_decorations() -> void:
	if not _decorations:
		return
	for tween in _decoration_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_decoration_tweens.clear()
	for child in _decorations.get_children():
		child.queue_free()

	var symbols := ["✦", "·", "✧"]
	for i in range(14):
		var accent := Label.new()
		accent.text = symbols[i % symbols.size()]
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		accent.modulate = Color(1.0, 0.87, 0.45, 0.18 + float(i % 3) * 0.08)
		accent.add_theme_font_size_override("font_size", 14 + (i % 3) * 5)
		var y := 90.0 + float(i) * (_map_size.y - 180.0) / 13.0
		var x := clampf(_map_size.x * 0.5 + sin(float(i) * 2.2) * _map_size.x * 0.42, 18.0, _map_size.x - 30.0)
		accent.position = Vector2(x, y)
		_decorations.add_child(accent)
		var start_y := accent.position.y
		var tween := create_tween().set_loops()
		tween.tween_property(accent, "position:y", start_y - 7.0, 1.8 + float(i % 4) * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(accent, "position:y", start_y + 5.0, 1.8 + float(i % 4) * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_decoration_tweens.append(tween)


func _on_level_selected(level_id: int) -> void:
	_scroll_to_level(level_id, true)
	if _active_popup and is_instance_valid(_active_popup):
		_active_popup.queue_free()
		_active_popup = null

	_active_popup = level_info_popup_scene.instantiate()
	add_child(_active_popup)
	_active_popup.setup_and_show(level_id)
	_active_popup.popup_closed.connect(func(): _active_popup = null)


## Smoothly center the selected/current level in the visible map viewport.
func _scroll_to_current_level(animated: bool = true) -> void:
	_scroll_to_level(clampi(SaveManager.get_current_level(), 1, TOTAL_LEVELS), animated)


func _scroll_to_level(level_id: int, animated: bool = true) -> void:
	if not _scroll_container or _node_positions.is_empty():
		return
	var index := clampi(level_id - 1, 0, _node_positions.size() - 1)
	var visible_height := maxf(_scroll_container.size.y, get_viewport_rect().size.y - TOP_SAFE_AREA)
	var max_scroll := maxf(0.0, _map_size.y - visible_height)
	var target_scroll_y := clampf(_node_positions[index].y - visible_height * 0.5, 0.0, max_scroll)

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	if animated:
		_scroll_tween = create_tween()
		_scroll_tween.tween_property(_scroll_container, "scroll_vertical", int(target_scroll_y), 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		_scroll_container.scroll_vertical = int(target_scroll_y)
