class_name Projectile
extends Node2D
## Fresh one-shot object. No Area2D, overlap signals, timers, reuse or activation API.
var manager: ProjectileManager
var data: WeaponData
var trace_id: int
var event_id: int
var pattern_index: int
var trace_ship: String
var spawn_us: int
var shooter: Player
var direction: Vector2
var speed: float
var damage: int
var weapon_id: String
var lifetime: float
var _life: float
var active:=false
var collision_layer:=0
var collision_mask:=5
var sprite: Sprite2D
var _query:=PhysicsShapeQueryParameters2D.new()
var _initial_position: Vector2
var _step:=0
var _render_steps:=0
func initialize(authority: ProjectileManager, id: int, volley: int, index: int, owner_aircraft: Player, config: WeaponData, pos: Vector2, dir: Vector2) -> void:
 manager=authority;trace_id=id;event_id=volley;pattern_index=index
 shooter=owner_aircraft;data=config;weapon_id=data.id;trace_ship=Game.selected_ship_id
 direction=dir;speed=data.speed;damage=data.damage;lifetime=data.lifetime;_life=lifetime
 _initial_position=pos;spawn_us=Time.get_ticks_usec()
 var shape:=CircleShape2D.new();shape.radius=data.radius
 _query.shape=shape;_query.collision_mask=5;_query.exclude=[shooter.get_rid()]
 _query.collide_with_areas=false;_query.margin=0.05
func _ready() -> void:
 if not is_instance_valid(manager) or manager.active_projectiles.get(trace_id)!=self:
  queue_free();return
 top_level=true
 # Fresh objects have no previous lease/pose to interpolate. Current world pose
 # is authoritative for both rendering and queries, including a rapid turn.
 physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
 global_transform=Transform2D(direction.angle()+PI/2,_initial_position)
 sprite=Sprite2D.new();sprite.texture=data.texture;sprite.scale=data.visual_scale
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(sprite)
 reset_physics_interpolation()
 active=true;add_to_group("bullets")
 set_process(ProjectileTrace.enabled)
 process_physics_priority=1
 if ProjectileTrace.enabled:ProjectileTrace.event("spawn",ProjectileTrace.bullet_data(self))
func _process(_delta: float) -> void:
 if not ProjectileTrace.enabled or not active:set_process(false);return
 if _render_steps<3:
  var details:=ProjectileTrace.bullet_data(self)
  details.sprite_global_position=ProjectileTrace.point(sprite.global_position)
  details.sprite_visible=visible and sprite.visible
  ProjectileTrace.event("render",details)
  _render_steps+=1
 else:set_process(false)
func _draw() -> void:
 if data==null:return
 draw_line(Vector2(0,8),Vector2(0,58),Color(data.color,0.14),12,true)
 draw_line(Vector2(0,6),Vector2(0,42),Color(data.color,0.55),4,true)
 draw_circle(Vector2.ZERO,8,Color(data.color,0.2))
func _physics_process(delta: float) -> void:
 if not active or not Game.is_running:return
 if not is_instance_valid(shooter):despawn("owner_removed");return
 var step_time:=minf(delta,_life)
 var motion:=direction*speed*step_time
 _query.transform=Transform2D(0,global_position);_query.motion=Vector2.ZERO
 var space:=get_world_2d().direct_space_state
 var contact:=space.get_rest_info(_query)
 if not contact.is_empty():manager.impact(self,contact);return
 _query.motion=motion
 var fractions:=space.cast_motion(_query)
 if fractions[0]<1:
  var position_world:=global_position+motion*minf(1,fractions[1]+0.05/maxf(motion.length(),0.05))
  _query.transform.origin=position_world;_query.motion=Vector2.ZERO
  contact=space.get_rest_info(_query)
  if not contact.is_empty():
   global_position=position_world;manager.impact(self,contact,"sweep");return
  global_position+=motion*fractions[0]
 else:global_position+=motion
 _life-=step_time;_step+=1
 if ProjectileTrace.enabled and (_step<=3 or _step%12==0):ProjectileTrace.event("move",ProjectileTrace.bullet_data(self))
 if _life<=0:despawn("expired")
func despawn(reason: String="manual") -> void:
 if is_instance_valid(manager):manager.finish(self,reason)
func consume(reason: String) -> void:
 if not active:return
 if ProjectileTrace.enabled:
  var details:=ProjectileTrace.bullet_data(self);details.reason=reason
  ProjectileTrace.event("despawn",details)
 active=false;visible=false;set_physics_process(false);set_process(false);remove_from_group("bullets")
 queue_free()
func _exit_tree() -> void:
 if active and is_instance_valid(manager):
  if ProjectileTrace.enabled:
   var details:=ProjectileTrace.bullet_data(self);details.reason="scene_exit"
   ProjectileTrace.event("despawn",details)
  manager.active_projectiles.erase(trace_id)
  active=false
