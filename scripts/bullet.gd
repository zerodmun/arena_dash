class_name Bullet
extends Area2D
## Bullet: travels in a direction with weapon-specific visual styling and effects.

@export var speed := 650.0
@export var lifetime := 2.4

var pool: Node
var active := true
const TEXTURES := {"ion":preload("res://assets/bullet_ion.svg"),"twin_laser":preload("res://assets/bullet_laser.svg"),"quantum_spread":preload("res://assets/bullet_quantum.svg"),"plasma":preload("res://assets/bullet.svg")}
var direction := Vector2.UP
var weapon_id := "plasma"
var _life := 2.4
var _color := Color(0.22, 0.74, 1.0)

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
    monitorable=false
    if pool:
        active=false
        visible=false
        monitoring=false
        $CollisionShape2D.disabled=true
        set_physics_process(false)
    else:add_to_group("bullets")
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
        sprite.texture = TEXTURES.ion
        sprite.scale = Vector2(0.22, 0.22)
        _color = Color(1.0, 0.72, 0.25)
        speed = 900.0
    elif weapon_id == "twin_laser":
        sprite.texture = TEXTURES.twin_laser
        sprite.scale = Vector2(0.24, 0.28)
        _color = Color(1.0, 0.25, 0.35)
        speed = 780.0
    elif weapon_id == "quantum_spread":
        sprite.texture = TEXTURES.quantum_spread
        sprite.scale = Vector2(0.20, 0.20)
        _color = Color(0.75, 0.45, 1.0)
        speed = 600.0
    else: # plasma
        sprite.texture = TEXTURES.plasma
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
    if not active or not Game.is_running:return
    global_position += direction * speed * delta
    _life -= delta
    if _life <= 0.0:
        despawn()


func _on_body_entered(body: Node2D) -> void:
    if not active or not Game.is_running:return
    if body is Enemy:
        body.hit()
    var root := get_tree().current_scene
    if root:
        ExplosionParticles.spawn(root, global_position, _color)
    despawn()

func activate(pos: Vector2,dir: Vector2,weapon: String) -> void:
 active=true
 global_position=pos
 reset_physics_interpolation()
 _life=lifetime
 visible=true
 monitoring=true
 $CollisionShape2D.disabled=false
 add_to_group("bullets")
 setup(dir,weapon)
 set_physics_process(true)
func despawn() -> void:
 if not active:return
 active=false
 remove_from_group("bullets")
 visible=false
 set_physics_process(false)
 if is_instance_valid(pool):pool.recycle.call_deferred(self)
 else:queue_free()
