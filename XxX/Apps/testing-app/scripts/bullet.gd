class_name Bullet
extends Area2D
## Bullet: travels in a direction with weapon-specific visual styling and effects.

@export var speed := 650.0
@export var lifetime := 2.4

var direction := Vector2.UP
var weapon_id := "plasma"
var _life := 2.4
var _color := Color(0.22, 0.74, 1.0)

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("bullets")
	body_entered.connect(_on_body_entered)


func setup(dir: Vector2, weapon: String = "plasma") -> void:
	direction = dir.normalized()
	weapon_id = weapon
	rotation = direction.angle() + PI / 2.0
	_apply_weapon_style()


func _apply_weapon_style() -> void:
	if not is_inside_tree() or sprite == null:
		return
	if weapon_id == "ion":
		sprite.texture = load("res://assets/bullet_ion.svg")
		sprite.scale = Vector2(0.22, 0.22)
		_color = Color(1.0, 0.72, 0.25)
		speed = 900.0
	elif weapon_id == "twin_laser":
		sprite.texture = load("res://assets/bullet_laser.svg")
		sprite.scale = Vector2(0.24, 0.28)
		_color = Color(1.0, 0.25, 0.35)
		speed = 780.0
	elif weapon_id == "quantum_spread":
		sprite.texture = load("res://assets/bullet_quantum.svg")
		sprite.scale = Vector2(0.20, 0.20)
		_color = Color(0.75, 0.45, 1.0)
		speed = 600.0
	else: # plasma
		sprite.texture = load("res://assets/bullet.svg")
		sprite.scale = Vector2(0.22, 0.22)
		_color = Color(0.22, 0.74, 1.0)
		speed = 680.0

	queue_redraw()

func _draw() -> void:
	# Local-space luminous projectile wake, aligned with the direction of travel.
	draw_line(Vector2(0, 8), Vector2(0, 58), Color(_color, 0.14), 12.0, true)
	draw_line(Vector2(0, 6), Vector2(0, 42), Color(_color, 0.55), 4.0, true)
	draw_circle(Vector2.ZERO, 8.0, Color(_color, 0.2))

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.kill()
	var root := get_tree().current_scene
	if root:
		ExplosionParticles.spawn(root, global_position, _color)
	queue_free()
