extends Node2D
var failures: Array[String]=[]
var checks:=0
var manager: ProjectileManager
var player: Player
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _ready() -> void:run.call_deferred()
func volley(id: String, pos:=Vector2(1000,-500), heading:=Vector2.UP) -> Array:
 Game.selected_weapon_id=id;player.apply_customization()
 player.global_rotation=heading.angle()+PI/2
 player.global_position=pos-heading*68
 player._shoot()
 var shots:=manager.active_projectiles.values()
 for shot: Projectile in shots:shot.set_physics_process(false)
 return shots
func run() -> void:
 Game.save_path=("user://projectile-rebuild-test.cfg" if OS.get_name()=="Android" else "res://qa/projectile-rebuild-test.cfg")
 Game.is_running=true;Game.selected_ship_id="valkyrie"
 get_tree().current_scene=self
 manager=ProjectileManager.new();add_child(manager)
 player=load("res://scenes/player.tscn").instantiate();add_child(player);player.set_physics_process(false)
 position=Vector2(50,70);rotation=.35;scale=Vector2(1.1,1.1)
 for weapon: String in Game.WEAPONS:
  var shots:=volley(weapon)
  var pattern:=EquipmentCatalog.firing_pattern(Game.WEAPONS[weapon])
  check(shots.size()==pattern.size(),"Authorized volley count "+weapon)
  var event_id:int=shots[0].event_id
  for i in shots.size():
   var shot:Projectile=shots[i]
   check(shot.event_id==event_id and shot.pattern_index==i,"Single event authorizes each pattern index")
   check(shot.sprite.texture.resource_path==Game.WEAPONS[weapon].texture,"Supplied artwork "+weapon)
   check(shot.direction.distance_to(Vector2.UP.rotated(pattern[i].angle))<.001,"Mathematical direction "+weapon)
   check(shot.direction.dot(Vector2.UP)>0,"No unintended backward fire")
   check(shot.shooter==player and shot.collision_mask==5,"Owner and mask")
   var start:=shot.global_position
   shot._physics_process(.1)
   check(shot.global_position.distance_to(start+shot.direction*shot.speed*.1)<.01,"Deterministic world velocity")
  var count:=manager.created_projectiles
  check(manager.fire(player.weapon_controller,player.weapon_controller.sequence)==0 and manager.created_projectiles==count,"Replay of same event rejected")
  var bogus:=WeaponController.new(player)
  check(manager.fire(bogus,999)==0,"Unregistered controller rejected")
  manager.cleanup();await get_tree().process_frame
  check(manager.active_projectiles.is_empty() and get_tree().get_nodes_in_group("bullets").is_empty(),"Cleanup leaves no active shot")
 # Expiration never produces impact effects, even when the physics step overshoots.
 var expired:Projectile=volley("ion")[0]
 var before:=manager.effects.created
 expired._life=.001;expired._physics_process(1)
 check(not expired.active and manager.effects.created==before,"Lifetime expiry has no explosion")
 await get_tree().process_frame
 # A fresh instance has no earlier transform, timer, collision callback or lease.
 var fresh:Projectile=volley("plasma")[0]
 check(fresh._life==2.4 and fresh.damage==1 and fresh.speed==680,"Fresh configuration")
 manager.impact(fresh,{"collider_id":player.get_instance_id(),"point":player.global_position})
 check(fresh.active,"Player cannot be its own target")
 manager.cleanup();await get_tree().process_frame
 # Verified high-speed contact against a two-unit wall.
 var wall:=StaticBody2D.new();wall.collision_layer=1;wall.collision_mask=0
 var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=Vector2(2,300)
 shape.shape=rect;wall.add_child(shape);add_child(wall)
 wall.global_transform=Transform2D(0,Vector2(500,-500))
 await get_tree().physics_frame;await get_tree().physics_frame
 var hit:Projectile=volley("ion",Vector2(400,-500),Vector2.RIGHT)[0]
 hit._physics_process(.3)
 check(not hit.active and manager.effects.created==before+1,"Thin-wall swept impact once")
 var burst:ExplosionParticles=manager.effects.get_child(0)
 check(absf(burst.global_position.x-499)<1,"Effect at actual wall surface under transformed parent")
 manager.impact(hit,{"collider_id":wall.get_instance_id(),"point":Vector2(999,999)})
 check(manager.effects.created==before+1,"Consumed shot cannot create duplicate effect")
 manager.cleanup();await get_tree().process_frame
 # Terrain crossing the launch corridor rejects the shot without a fake impact.
 wall.global_position=Vector2(365,-500)
 await get_tree().physics_frame;await get_tree().physics_frame
 check(volley("ion",Vector2(400,-500),Vector2.RIGHT).is_empty(),"Blocked launch corridor rejects shot")
 check(manager.effects.created==before+1,"Rejected spawn has no effect")
 wall.global_position=Vector2(332,-500)
 await get_tree().physics_frame;await get_tree().physics_frame
 check(volley("ion",Vector2(400,-500),Vector2.RIGHT).is_empty(),"Origin overlap cannot be ignored by motion cast")
 wall.queue_free();await get_tree().physics_frame;await get_tree().physics_frame
 # Repeated input edges and equipment changes use the same immediate clock.
 for i in 100:
  Game.selected_weapon_id=Game.WEAPONS.keys()[i%6];player.apply_customization()
  player.weapon_controller.cooldown=0
  var old_count:=manager.accepted_events
  player.weapon_controller.tick(.016,true)
  player.weapon_controller.tick(.001,false)
  player.weapon_controller.tick(.001,true)
  check(manager.accepted_events==old_count+1,"Repeated press and switch cannot duplicate cooldown event")
  for shot:Projectile in manager.active_projectiles.values():check(shot.weapon_id==Game.selected_weapon_id,"No stale weapon snapshot")
  manager.cleanup();await get_tree().process_frame
 # Manager removal cleans references and prevents a retained controller firing.
 var retained:=player.weapon_controller
 manager.free()
 check(retained.request_fire()==0,"No firing after scene authority removed")
 player.queue_free();Game.is_running=false
 for i in 3:await get_tree().process_frame
 SoundEffects.stop_all()
 print("PROJECTILE_LIFECYCLE ",JSON.stringify({"checks":checks,"failures":failures}))
 get_tree().quit(0 if failures.is_empty() else 1)
