class_name PickupSpawner
extends Node2D
## PickupSpawner: drops score pickups inside the arena at a steady pace.

@export var pickup_scene: PackedScene
@export_range(0.5, 8.0, 0.1) var initial_interval := 3.0
@export var arena_rect := Rect2(190.0, 190.0, 900.0, 340.0)

var _timer := initial_interval


func _ready() -> void:
	Game.game_started.connect(_on_game_started)


func _on_game_started() -> void:
	_timer = initial_interval


func _physics_process(delta: float) -> void:
	if not Game.is_running:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = initial_interval
		_spawn_pickup()


func _spawn_pickup() -> void:
	var pickup := pickup_scene.instantiate() as Pickup
	pickup.position = Vector2(
		randf_range(arena_rect.position.x, arena_rect.end.x),
		randf_range(arena_rect.position.y, arena_rect.end.y)
	)
	add_child(pickup)