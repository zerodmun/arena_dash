class_name EnemyShot
extends Area2D
var pool: Node
var active:=true
var direction := Vector2.DOWN
var speed := 250.0
var damage := 1
var _life := 4.0
var _sprite: Sprite2D
func _ready() -> void:
 monitorable=false
 if not pool:add_to_group("enemy_shots")
 collision_layer = 32
 collision_mask = 3
 var shape := CollisionShape2D.new()
 shape.name="CollisionShape2D"
 var circle := CircleShape2D.new()
 circle.radius = 9
 shape.shape = circle
 add_child(shape)
 _sprite = Sprite2D.new()
 _sprite.texture = preload("res://assets/bullet_laser.svg")
 _sprite.scale = Vector2(0.12,0.12)
 _sprite.rotation = direction.angle()+PI/2
 add_child(_sprite)
 body_entered.connect(_impact)
 if pool:
  active=false;visible=false;monitoring=false;shape.disabled=true
  set_physics_process(false)
func _physics_process(delta: float) -> void:
 if not active or not Game.is_running: return
 position += direction*speed*delta
 _life -= delta
 if _life<=0:despawn()
func _impact(body: Node2D) -> void:
 if not active or not Game.is_running:return
 if body is Player: body.receive_hit(damage)
 despawn()

func activate(pos: Vector2,dir: Vector2,travel_speed: float,hit_damage: int) -> void:
 active=true;_life=4.0
 global_position=pos;direction=dir;speed=travel_speed;damage=hit_damage
 reset_physics_interpolation()
 _sprite.rotation=direction.angle()+PI/2
 visible=true;monitoring=true
 $CollisionShape2D.disabled=false
 add_to_group("enemy_shots")
 set_physics_process(true)
func despawn() -> void:
 if not active:return
 active=false
 visible=false
 remove_from_group("enemy_shots")
 set_physics_process(false)
 if is_instance_valid(pool):pool.recycle.call_deferred(self)
 else:queue_free()
