# gem_particle_burst.gd — One-shot sparkling particle effect when gem is popped.
class_name GemParticleBurst
extends Node2D

@onready var _particles: CPUParticles2D = $CPUParticles2D

func setup(pos: Vector2, color: Color) -> void:
	position = pos
	z_index = 15
	if not _particles:
		_particles = get_node_or_null("CPUParticles2D")
	if _particles:
		_particles.color = color
		_particles.emitting = true
		_particles.one_shot = true
	
	# Clean up after particles finish
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(queue_free)
