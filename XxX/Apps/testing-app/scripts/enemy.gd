class_name Enemy
extends CharacterBody2D
## Enemy: semi-3D cyber drone in crisp HD, chases player, wobbles menacingly,
## explodes into particles on death.

const DIE_SCORE := 10
const BASE_SCALE := 0.25

@export var speed := 115.0

var _player: Node2D
var _dead := false
var _wobble_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_wobble_time = randf_range(0.0, TAU)


func _physics_process(delta: float) -> void:
	if not Game.is_running:
		velocity = Vector2.ZERO
		return
	if _player == null or not is_instance_valid(_player):
		return
	var to_player := global_position.direction_to(_player.global_position)
	velocity = to_player * speed
	move_and_slide()

	# Organic semi-3D breathing wobble
	_wobble_time += delta * 6.0
	var pulse := 1.0 + sin(_wobble_time) * 0.06
	sprite.scale = Vector2(BASE_SCALE * pulse, BASE_SCALE / pulse)
	sprite.rotation = to_player.angle() + PI / 2.0


## Destroy this enemy and award score.
func kill() -> void:
	if _dead:
		return
	_dead = true
	Game.add_score(DIE_SCORE)
	Game.record_enemy_kill()
	Game.request_screen_shake(6.0)

	if SoundEffects:
		SoundEffects.play_explosion()

	var root := get_tree().current_scene
	if root:
		ExplosionParticles.spawn(root, global_position, Color(1.0, 0.35, 0.2))
		FloatingText.spawn(root, global_position, "+10", Color(1.0, 0.85, 0.2))

	queue_free()
