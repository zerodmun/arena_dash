class_name Obstacle
extends AnimatableBody2D
## Obstacle: Semi-3D tactical cover blocking bullets, enemies, and players.
## Dynamically supports multiple biomes (Cyber, Primal Jungle, Cosmic Void).

enum Type { PILLAR, BARRIER, DINO_SKULL, ANCIENT_TREE, ASTEROID, CARGO }

@export var obstacle_type: Type = Type.PILLAR

@onready var sprite: Sprite2D = $Sprite2D
@onready var circle_col: CollisionShape2D = $CircleCollision
@onready var rect_col: CollisionShape2D = $RectCollision


var _origin := Vector2.ZERO
var _target := Vector2.ZERO
var _retarget := 0.0
var _drift_speed := 35.0
var _bounds := Rect2(140, 140, 3120, 1920)

func reset_motion() -> void:
	position = _origin
	_target = _origin
	_retarget = randf_range(0.5, 2.0)

func _physics_process(delta: float) -> void:
	if not Game.is_running:
		return
	_retarget -= delta
	if _retarget <= 0.0 or position.distance_to(_target) < 8.0:
		_retarget = randf_range(2.0, 5.0)
		var candidate := _origin + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 210.0)
		candidate.x = clampf(candidate.x, _bounds.position.x, _bounds.end.x)
		candidate.y = clampf(candidate.y, _bounds.position.y, _bounds.end.y)
		# Keep a safe launch area around the arena center.
		var safe := candidate.distance_to(Vector2(1700, 1100)) > 260.0
		for other in get_tree().get_nodes_in_group("moving_cover"):
			if other != self and candidate.distance_to(other.position) < 240.0:
				safe = false
		if safe:
			_target = candidate
		_drift_speed = randf_range(22.0, 55.0)
	position = position.move_toward(_target, _drift_speed * delta)

func _ready() -> void:
	add_to_group("moving_cover")
	circle_col.shape = circle_col.shape.duplicate()
	rect_col.shape = rect_col.shape.duplicate()
	collision_layer = 1
	collision_mask = 0
	_apply_type()
	_origin = position
	_target = position


func set_type(t: Type) -> void:
	obstacle_type = t
	if is_inside_tree():
		_apply_type()


func _apply_type() -> void:
	if sprite == null:
		return

	match obstacle_type:
		Type.CARGO:
			sprite.texture = load("res://assets/obstacle_cargo.svg")
			sprite.scale = Vector2(0.38, 0.38)
			circle_col.disabled = true
			rect_col.disabled = false
			(rect_col.shape as RectangleShape2D).size = Vector2(174, 66)
		Type.PILLAR:
			sprite.texture = load("res://assets/obstacle_pillar.svg")
			sprite.scale = Vector2(0.28, 0.28)
			circle_col.disabled = false
			rect_col.disabled = true
			(circle_col.shape as CircleShape2D).radius = 58.0
		Type.BARRIER:
			sprite.texture = load("res://assets/obstacle_barrier.svg")
			sprite.scale = Vector2(0.35, 0.35)
			circle_col.disabled = true
			rect_col.disabled = false
			(rect_col.shape as RectangleShape2D).size = Vector2(160, 70)
		Type.DINO_SKULL:
			sprite.texture = load("res://assets/obstacle_dino.svg")
			sprite.scale = Vector2(0.32, 0.32) # ~160px skull
			circle_col.disabled = false
			rect_col.disabled = true
			(circle_col.shape as CircleShape2D).radius = 65.0
		Type.ANCIENT_TREE:
			sprite.texture = load("res://assets/obstacle_tree.svg")
			sprite.scale = Vector2(0.34, 0.34) # ~170px tree
			circle_col.disabled = false
			rect_col.disabled = true
			(circle_col.shape as CircleShape2D).radius = 68.0
		Type.ASTEROID:
			sprite.texture = load("res://assets/obstacle_asteroid.svg")
			sprite.scale = Vector2(0.32, 0.32) # ~160px asteroid
			circle_col.disabled = false
			rect_col.disabled = true
			(circle_col.shape as CircleShape2D).radius = 64.0
