class_name ProjectileManager
extends Node2D
## Scene-owned authority: one accepted volley, immutable spawn snapshots, no pool.
static var next_projectile_id:=0
static var next_event_id:=0
var active_projectiles: Dictionary={}
var _last_sequence: Dictionary={}
var effects: ImpactEffectManager
var shutting_down:=false
var accepted_events:=0
var created_projectiles:=0
var blocked_spawns:=0
func _ready() -> void:
 name="ProjectileManager"
 top_level=true
 global_transform=Transform2D.IDENTITY
 effects=ImpactEffectManager.new();add_child(effects)
func fire(controller: WeaponController, sequence: int) -> int:
 var owner_aircraft:=controller.aircraft
 if shutting_down or not Game.is_running or not is_instance_valid(owner_aircraft):return 0
 if owner_aircraft.weapon_controller!=controller or owner_aircraft.get_parent()!=get_parent():return 0
 var owner_id:=owner_aircraft.get_instance_id()
 if sequence<=int(_last_sequence.get(owner_id,0)):return 0
 _last_sequence[owner_id]=sequence
 var data:=WeaponData.from_catalog(controller.selected_weapon)
 if data==null:return 0
 var origin:=owner_aircraft.shoot_point.global_position
 var heading:=-owner_aircraft.shoot_point.global_transform.y.normalized()
 if not origin.is_finite() or not heading.is_finite() or heading.length_squared()<0.99:return 0
 var tangent:=Vector2(-heading.y,heading.x)
 next_event_id+=1
 var event_id:=next_event_id
 accepted_events+=1
 var spawned:=0
 if ProjectileTrace.enabled:ProjectileTrace.event("fire",{"event_id":event_id,"sequence":sequence,"owner":owner_id,"weapon":data.id,"aircraft":Game.selected_ship_id,"expected_count":data.pattern.size(),"pattern":data.pattern,"speed":data.speed,"damage":data.damage,"muzzle":ProjectileTrace.point(origin),"heading":ProjectileTrace.point(heading)})
 for index in data.pattern.size():
  var sample: Dictionary=data.pattern[index]
  var position_world:=origin+tangent*float(sample.offset)
  var direction_world:=heading.rotated(float(sample.angle)).normalized()
  if not _clear_muzzle(owner_aircraft,position_world,data.radius):
   blocked_spawns+=1
   if ProjectileTrace.enabled:ProjectileTrace.event("spawn_blocked",{"event_id":event_id,"index":index,"weapon":data.id})
   continue
  next_projectile_id+=1
  var projectile:=Projectile.new()
  projectile.initialize(self,next_projectile_id,event_id,index,owner_aircraft,data,position_world,direction_world)
  active_projectiles[projectile.trace_id]=projectile
  add_child(projectile)
  created_projectiles+=1;spawned+=1
 if ProjectileTrace.enabled:ProjectileTrace.event("fire_complete",{"event_id":event_id,"spawned":spawned,"blocked":data.pattern.size()-spawned})
 return spawned
func _clear_muzzle(owner_aircraft: Player, pos: Vector2, radius: float) -> bool:
 var owner_shape:=owner_aircraft.get_node("CollisionShape2D") as CollisionShape2D
 var owner_radius:=(owner_shape.shape as CircleShape2D).radius*maxf(owner_aircraft.global_scale.x,owner_aircraft.global_scale.y)
 if pos.distance_to(owner_aircraft.global_position)<owner_radius+radius:return false
 var query:=PhysicsShapeQueryParameters2D.new()
 var circle:=CircleShape2D.new();circle.radius=radius;query.shape=circle
 query.collision_mask=1;query.exclude=[owner_aircraft.get_rid()]
 query.transform=Transform2D(0,owner_aircraft.global_position)
 query.motion=pos-owner_aircraft.global_position
 var space:=get_world_2d().direct_space_state
 query.motion=Vector2.ZERO
 if not space.intersect_shape(query,1).is_empty():return false
 query.motion=pos-owner_aircraft.global_position
 if space.cast_motion(query)[0]<1:return false
 query.transform.origin=pos;query.motion=Vector2.ZERO
 return space.intersect_shape(query,1).is_empty()
func finish(projectile: Projectile, reason: String) -> bool:
 if active_projectiles.get(projectile.trace_id)!=projectile or not projectile.active:return false
 active_projectiles.erase(projectile.trace_id)
 projectile.consume(reason)
 return true
func impact(projectile: Projectile, contact: Dictionary, contact_kind: String="initial_overlap") -> void:
 if shutting_down or not Game.is_running or active_projectiles.get(projectile.trace_id)!=projectile:return
 var target:=instance_from_id(int(contact.get("collider_id",0))) as CollisionObject2D
 if not is_instance_valid(target) or target==projectile.shooter or target is Player:return
 if (target.collision_layer&5)==0 or not contact.get("point",Vector2(INF,INF)).is_finite():return
 if ProjectileTrace.enabled:
  var details:=ProjectileTrace.bullet_data(projectile)
  details.target=target.get_instance_id();details.target_class=target.get_class()
  details.target_position=ProjectileTrace.point(target.global_position);details.target_layer=target.collision_layer
  details.center=ProjectileTrace.point(projectile.global_position);details.contact=ProjectileTrace.point(contact.point)
  details.actual_overlap=true;details.contact_kind=contact_kind
  ProjectileTrace.event("impact",details)
 if not finish(projectile,"impact"):return
 # Consumption precedes damage and the single-use effect receipt.
 if target is Enemy:target.hit(projectile.damage)
 effects.impact(projectile.trace_id,contact.point,projectile.data.color)
func cleanup(reason: String="scene_cleanup") -> void:
 for projectile: Projectile in active_projectiles.values():finish(projectile,reason)
 active_projectiles.clear()
 if is_instance_valid(effects):effects.cleanup()
func _exit_tree() -> void:
 shutting_down=true
 cleanup("scene_exit")
 _last_sequence.clear()
