class_name ProjectileTrace
extends RefCounted
## Opt-in JSONL trace in the isolated debug QA package only.
static var enabled := false
static var stream: FileAccess
static var markers: Array[Dictionary] = []
static func start() -> void:
 enabled=OS.is_debug_build() and OS.has_feature("arena_review")
 if enabled:stream=FileAccess.open("user://projectile_trace.jsonl",FileAccess.WRITE)
static func point(p: Vector2) -> Array:
 return [p.x,p.y]
static func event(kind: String, data: Dictionary) -> void:
 if not enabled or stream==null:return
 data=data.duplicate()
 data.event=kind
 data.tick=Engine.get_physics_frames()
 data.us=Time.get_ticks_usec()
 if kind in ["spawn","impact"]:
  var marker:=data.duplicate()
  if kind=="impact" and data.has("contact"):marker.position=data.contact
  markers.append(marker)
  if markers.size()>64:markers.pop_front()
 stream.store_line(JSON.stringify(data))
 if kind in ["impact","effect","despawn"]:stream.flush()
static func bullet_data(bullet: Projectile) -> Dictionary:
 var owner_aircraft:=bullet.shooter
 return {"id":bullet.trace_id,"event_id":bullet.event_id,"pattern_index":bullet.pattern_index,"instance":bullet.get_instance_id(),"weapon":bullet.weapon_id,"aircraft":bullet.trace_ship,"spawn_us":bullet.spawn_us,"position":point(bullet.global_position),"direction":point(bullet.direction),"velocity":point(bullet.direction*bullet.speed),"layer":bullet.collision_layer,"mask":bullet.collision_mask,"owner":owner_aircraft.get_instance_id() if is_instance_valid(owner_aircraft) else 0,"player":point(owner_aircraft.global_position) if is_instance_valid(owner_aircraft) else [],"muzzle":point(owner_aircraft.shoot_point.global_position) if owner_aircraft is Player else [],"age":bullet.lifetime-bullet._life}
