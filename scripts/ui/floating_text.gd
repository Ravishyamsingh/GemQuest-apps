# floating_text.gd — Floating bounce & fade score popup.
class_name FloatingText
extends Node2D

@onready var _label: Label = $Label

func setup(text: String, start_pos: Vector2, color: Color = Color(1.0, 0.9, 0.2)) -> void:
	position = start_pos
	z_index = 20
	if not _label:
		_label = get_node_or_null("Label")
	if _label:
		_label.text = text
		_label.modulate = color
	
	scale = Vector2(0.3, 0.3)
	modulate.a = 1.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	# Float upward
	tween.tween_property(self, "position:y", start_pos.y - 65.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Bounce scale up then settle
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.4)
	
	tween.chain().tween_callback(queue_free)
