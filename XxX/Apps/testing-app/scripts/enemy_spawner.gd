class_name EnemySpawner
extends Node2D
## EnemySpawner: spawns enemies across the expanded arena.

@export var enemy_scene: PackedScene
@export_range(40, 300, 1) var base_speed := 95.0
@export_range(0.4, 5.0, 0.1) var initial_interval := 1.6
@export_range(0.2, 1.5, 0.1) var min_interval := 0.40
@export_range(1, 60, 1) var max_enemies := 18
@export var arena_rect := Rect2(140.0, 140.0, 3100.0, 1900.0)

var _timer := initial_interval
var _alive := 0
var _spawn_count := 0


func _ready() -> void:
	Game.game_started.connect(_on_game_started)


func _on_game_started() -> void:
	_timer = initial_interval
	_spawn_count = 0


func _physics_process(delta: float) -> void:
	if not Game.is_running:
		return
	_timer -= delta
	if _timer <= 0.0 and _alive < max_enemies:
		_spawn_enemy()
		_spawn_count += 1
		_timer = maxf(min_interval, initial_interval - _spawn_count * 0.025)


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.speed = base_speed + randf_range(0.0, 40.0) + _spawn_count * 0.35
	enemy.position = _pick_spawn_position()
	add_child(enemy)
	_alive += 1
	enemy.tree_exited.connect(func() -> void: _alive -= 1)


func _pick_spawn_position() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for i in 30:
		var pos := Vector2(
			randf_range(arena_rect.position.x, arena_rect.end.x),
			randf_range(arena_rect.position.y, arena_rect.end.y)
		)
		if player == null or (pos.distance_to(player.global_position) > 400.0 and pos.distance_to(player.global_position) < 1400.0):
			return pos
	return arena_rect.get_center() + Vector2(randf_range(-300, 300), randf_range(-300, 300))
