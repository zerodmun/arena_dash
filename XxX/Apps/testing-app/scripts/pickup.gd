class_name Pickup
extends Area2D
## Pickup: bobbing 3D energy crystal in crisp HD that grants score when collected.

const SCORE := 25
const BASE_SCALE := 0.20

var _t := 0.0
var _base_y := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
    add_to_group("pickups")
    body_entered.connect(_on_body_entered)
    _base_y = position.y
    _t = randf_range(0.0, TAU)


func _physics_process(delta: float) -> void:
    _t += delta * 3.2
    position.y = _base_y + sin(_t) * 12.0
    # 3D facet spin wobble
    sprite.scale.x = BASE_SCALE * cos(_t * 0.8)
    sprite.rotation = sin(_t * 0.5) * 0.15


func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        Game.add_score(SCORE)
        Game.record_pickup_collected()
        if SoundEffects:
            SoundEffects.play_pickup()
        var root := get_tree().current_scene
        if root:
            FloatingText.spawn(root, global_position, "+25", Color(1.0, 0.95, 0.3))
            ExplosionParticles.spawn(root, global_position, Color(1.0, 0.9, 0.2))
        queue_free()
