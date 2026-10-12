@static_unload
class_name ExplosionParticles
extends CPUParticles2D
## Dynamic particle burst for enemy destruction and impacts.

var active := false
var lease := 0
var pool: Node
static var gradients: Dictionary={}

func _ready() -> void:
    top_level = true
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    local_coords = false
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
    
    finished.connect(_finished)
    if pool:visible=false

static func gradient_for(col: Color) -> Gradient:
 if not gradients.has(col):
  var gradient:=Gradient.new()
  gradient.set_color(0,col.lightened(0.4))
  gradient.set_color(1,Color(col,0.0))
  gradients[col]=gradient
 return gradients[col]
func activate(pos: Vector2,col: Color,source_id: int = 0,source_kind: String = "world_effect") -> void:
 lease+=1
 active=true
 emitting=false
 if ProjectileTrace.enabled:ProjectileTrace.event("effect",{"instance":get_instance_id(),"position":ProjectileTrace.point(pos),"previous_position":ProjectileTrace.point(global_position),"emitting_before":emitting,"local_coords":local_coords,"projectile_id":source_id,"lease":lease,"source_kind":source_kind})
 global_transform=Transform2D(0.0,pos)
 reset_physics_interpolation()
 color=col
 color_ramp=gradient_for(col)
 visible=true
 restart()
func _finished() -> void:
 if not active:return
 active=false
 visible=false
 if is_instance_valid(pool):pool.recycle.call_deferred(self,lease)
 else:queue_free()
static func spawn(parent: Node,pos: Vector2,col: Color=Color(1.0,0.35,0.2),source_id: int = 0,source_kind: String = "world_effect") -> void:
 var cache:=parent.get_node_or_null("CombatPool")
 if cache:
  cache.burst(pos,col,source_id,source_kind)
  return
 var particle:=ExplosionParticles.new()
 parent.add_child(particle)
 particle.activate(pos,col,source_id,source_kind)
