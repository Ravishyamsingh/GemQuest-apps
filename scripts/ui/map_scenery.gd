# map_scenery.gd — Lightweight procedural scenery for the Gem Gardens map.
# Draws the river, islands, flowers, toys, and ambient fireflies without
# requiring extra textures or a particle system on every map node.
extends Control
class_name MapScenery

var _time := 0.0

const FLOWER_COLORS := [
	Color(1.0, 0.42, 0.58, 0.95),
	Color(1.0, 0.78, 0.25, 0.95),
	Color(0.56, 0.86, 1.0, 0.95),
	Color(0.75, 0.52, 1.0, 0.95),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	_draw_sky_gradient()
	_draw_stars()
	_draw_islands()
	_draw_river()
	_draw_bridges()
	_draw_flowers()
	_draw_toys()
	_draw_fireflies()


func _draw_sky_gradient() -> void:
	var bands := 18
	var top_color := Color(0.07, 0.10, 0.26, 1.0)
	var bottom_color := Color(0.16, 0.25, 0.34, 1.0)
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var band_color := top_color.lerp(bottom_color, t)
		var band_y := float(i) * size.y / float(bands)
		draw_rect(Rect2(0.0, band_y, size.x, size.y / float(bands) + 2.0), band_color)

	# Soft glowing pools make the map feel like a living garden at night.
	draw_circle(Vector2(size.x * 0.18, size.y * 0.18), size.x * 0.28, Color(0.20, 0.38, 0.48, 0.10))
	draw_circle(Vector2(size.x * 0.72, size.y * 0.78), size.x * 0.34, Color(0.45, 0.25, 0.55, 0.10))


func _draw_stars() -> void:
	for i in range(30):
		var x := fmod(31.0 + float(i * 83), maxf(size.x - 12.0, 1.0)) + 6.0
		var y := fmod(47.0 + float(i * 137), maxf(size.y - 20.0, 1.0)) + 10.0
		var twinkle := 0.5 + 0.5 * sin(_time * (1.2 + float(i % 3) * 0.25) + float(i))
		draw_circle(Vector2(x, y), 1.0 + twinkle * 1.4, Color(1.0, 0.90, 0.56, 0.18 + twinkle * 0.25))


func _river_x(y: float) -> float:
	return size.x * 0.76 + sin(y * 0.007 + 0.4) * size.x * 0.12 + cos(y * 0.015) * size.x * 0.035


func _draw_river() -> void:
	var river_points := PackedVector2Array()
	var river_highlight := PackedVector2Array()
	for i in range(28):
		var y := float(i) * size.y / 27.0
		var x := _river_x(y)
		river_points.append(Vector2(x, y))
		river_highlight.append(Vector2(x - 7.0 + sin(_time * 1.6 + y * 0.02) * 3.0, y))
	draw_polyline(river_points, Color(0.04, 0.20, 0.36, 0.70), 82.0, true)
	draw_polyline(river_points, Color(0.08, 0.48, 0.68, 0.88), 58.0, true)
	draw_polyline(river_highlight, Color(0.42, 0.88, 0.92, 0.34), 3.0, true)


func _draw_bridges() -> void:
	for i in range(3):
		var y := size.y * (0.20 + float(i) * 0.31)
		var center := Vector2(_river_x(y), y)
		var half_width := 47.0
		draw_line(center + Vector2(-half_width, -7.0), center + Vector2(half_width, -7.0), Color(0.28, 0.12, 0.13, 0.9), 13.0, true)
		for plank in range(5):
			var plank_x := center.x - 39.0 + float(plank) * 19.5
			draw_line(Vector2(plank_x, y - 15.0), Vector2(plank_x, y + 2.0), Color(0.86, 0.54, 0.25, 0.95), 5.0, true)


func _draw_islands() -> void:
	var islands := [
		Vector2(size.x * 0.16, size.y * 0.16),
		Vector2(size.x * 0.33, size.y * 0.43),
		Vector2(size.x * 0.15, size.y * 0.72),
		Vector2(size.x * 0.42, size.y * 0.88),
	]
	for i in range(islands.size()):
		var center: Vector2 = islands[i]
		var radius := 37.0 + float(i % 2) * 11.0
		_draw_blob(center, radius, Color(0.12, 0.32, 0.30, 0.85))
		_draw_blob(center + Vector2(-3.0, -4.0), radius * 0.76, Color(0.18, 0.45, 0.32, 0.78))
		for tuft in range(3):
			var tuft_pos := center + Vector2(-radius * 0.35 + float(tuft) * radius * 0.34, -radius * 0.15 + sin(float(tuft)) * 8.0)
			draw_line(tuft_pos + Vector2(0, 8), tuft_pos + Vector2(-4, -3), Color(0.44, 0.75, 0.42, 0.8), 2.0, true)
			draw_line(tuft_pos + Vector2(0, 8), tuft_pos + Vector2(5, -4), Color(0.44, 0.75, 0.42, 0.8), 2.0, true)


func _draw_blob(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var wobble := 1.0 + sin(float(i) * 2.7 + center.y) * 0.10
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * wobble)
	draw_colored_polygon(points, color)


func _draw_flowers() -> void:
	for i in range(22):
		var y := 88.0 + float(i) * (size.y - 150.0) / 21.0
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := size.x * 0.5 + side * (size.x * 0.31 + sin(float(i) * 1.7) * size.x * 0.07)
		x = clampf(x, 24.0, size.x - 24.0)
		var sway := sin(_time * 1.5 + float(i) * 0.8) * 3.0
		var flower_color: Color = FLOWER_COLORS[i % FLOWER_COLORS.size()]
		_draw_flower(Vector2(x + sway, y), flower_color, 6.0 + float(i % 3))


func _draw_flower(pos: Vector2, color: Color, petal_size: float) -> void:
	draw_line(pos + Vector2(0, 4), pos + Vector2(-1, 28), Color(0.33, 0.75, 0.42, 0.85), 2.0, true)
	draw_circle(pos + Vector2(-5, 17), 4.0, Color(0.35, 0.80, 0.42, 0.72))
	for i in range(5):
		var angle := TAU * float(i) / 5.0 + _time * 0.04
		draw_circle(pos + Vector2(cos(angle), sin(angle)) * petal_size, petal_size * 0.62, color)
	draw_circle(pos, petal_size * 0.43, Color(1.0, 0.88, 0.30, 1.0))


func _draw_toys() -> void:
	var toy_spots := [
		Vector2(size.x * 0.10, size.y * 0.30),
		Vector2(size.x * 0.43, size.y * 0.23),
		Vector2(size.x * 0.12, size.y * 0.55),
		Vector2(size.x * 0.45, size.y * 0.68),
		Vector2(size.x * 0.50, size.y * 0.96),
	]
	for i in range(toy_spots.size()):
		var bounce := sin(_time * 1.4 + float(i) * 1.2) * 2.5
		var toy_center: Vector2 = toy_spots[i]
		if i % 2 == 0:
			_draw_toy_bear(toy_center + Vector2(0, bounce), 12.0)
		else:
			_draw_toy_block(toy_center + Vector2(0, bounce), 14.0, i)


func _draw_toy_bear(center: Vector2, radius: float) -> void:
	var fur := Color(0.88, 0.48, 0.28, 0.96)
	draw_circle(center + Vector2(-radius * 0.62, -radius * 0.62), radius * 0.38, fur)
	draw_circle(center + Vector2(radius * 0.62, -radius * 0.62), radius * 0.38, fur)
	draw_circle(center, radius, fur)
	draw_circle(center + Vector2(0, 3), radius * 0.54, Color(1.0, 0.72, 0.47, 0.96))
	draw_circle(center + Vector2(-4, -2), 2.0, Color(0.08, 0.06, 0.12, 1.0))
	draw_circle(center + Vector2(4, -2), 2.0, Color(0.08, 0.06, 0.12, 1.0))
	draw_circle(center + Vector2(0, 4), 2.0, Color(0.20, 0.08, 0.10, 1.0))


func _draw_toy_block(center: Vector2, radius: float, variant: int) -> void:
	var block_color := Color(0.40, 0.72, 0.98, 0.95) if variant % 2 == 1 else Color(0.98, 0.42, 0.48, 0.95)
	var points := PackedVector2Array([
		center + Vector2(-radius, -radius * 0.7),
		center + Vector2(radius * 0.75, -radius),
		center + Vector2(radius, radius * 0.55),
		center + Vector2(-radius * 0.72, radius),
	])
	draw_colored_polygon(points, block_color)
	draw_circle(center + Vector2(-4, -3), 3.0, Color(1.0, 0.90, 0.44, 0.9))
	draw_circle(center + Vector2(5, 4), 3.0, Color(0.15, 0.22, 0.50, 0.75))


func _draw_fireflies() -> void:
	for i in range(16):
		var y := fmod(120.0 + float(i * 179) + _time * (8.0 + float(i % 4) * 3.0), maxf(size.y, 1.0))
		var x := fmod(55.0 + float(i * 97) + sin(_time * 0.8 + float(i)) * 24.0, maxf(size.x - 20.0, 1.0)) + 10.0
		var pulse := 0.5 + 0.5 * sin(_time * 2.0 + float(i))
		draw_circle(Vector2(x, y), 2.0 + pulse * 2.0, Color(1.0, 0.88, 0.33, 0.18 + pulse * 0.32))
