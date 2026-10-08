class_name ExplosionParticles
extends CPUParticles2D
## Dynamic particle burst for enemy destruction and impacts.

func _ready() -> void:
	emitting = false
	one_shot = true
	explosiveness = 0.95
	lifetime = 0.55
	amount = 26
	direction = Vector2.ZERO
	spread = 180.0
	gravity = Vector2.ZERO
	initial_velocity_min = 90.0
	initial_velocity_max = 240.0
	damping_min = 120.0
	damping_max = 200.0
	scale_amount_min = 3.5
	scale_amount_max = 7.0
	color = Color(1.0, 0.35, 0.2, 1.0)
	
	# Gradient fade
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	grad.add_point(0.4, Color(1.0, 0.25, 0.1, 0.9))
	grad.set_color(1, Color(0.4, 0.05, 0.05, 0.0))
	color_ramp = grad


static func spawn(parent: Node, pos: Vector2, col: Color = Color(1.0, 0.35, 0.2)) -> void:
	var p := ExplosionParticles.new()
	p.global_position = pos
	parent.add_child(p)
	p.color = col
	var gradient := Gradient.new()
	gradient.set_color(0, col.lightened(0.4))
	gradient.set_color(1, Color(col, 0.0))
	p.color_ramp = gradient
	p.restart()
	p.finished.connect(p.queue_free)
