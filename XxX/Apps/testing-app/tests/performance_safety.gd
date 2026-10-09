extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("run")
func run() -> void:
 Game.save_path="res://build/performance-safety.cfg"
 Game.completed_levels={};Game.selected_map_id="cyber";Game.selected_ship_id="titan"
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 scene.enemy_spawner.set_physics_process(false)
 scene.pickup_spawner.set_physics_process(false)
 scene.player.set_physics_process(false)
 var pool: CombatPool=scene.get_node("CombatPool")
 var writes:=Game.save_writes
 for i in 1000:Game.add_score(1)
 check(Game.save_writes==writes,"Scoring has no synchronous disk writes")
 Game.flush_save()
 check(Game.save_writes==writes+1,"Boundary flush persists dirty high score once")
 var cfg:=ConfigFile.new();cfg.load(Game.save_path)
 check(cfg.get_value("stats","high_score")==Game.high_score,"High score persists after flush")
 for weapon: String in Game.WEAPONS:
  for rate in [30,60,120]:
   var bullet:=pool.bullet(Vector2(3400,2200),Vector2.RIGHT,weapon)
   bullet.set_physics_process(false)
   var initial:=bullet.global_position
   for step in rate:bullet._physics_process(1.0/rate)
   check(absf(bullet.global_position.x-initial.x-bullet.speed)<0.1,"Projectile real-second speed at "+str(rate)+" Hz")
   bullet.despawn()
   await get_tree().process_frame
 # Firing preserves fractional cooldown debt without accumulating a backlog while idle.
 scene.player.fire_rate=0.11
 Game.selected_weapon_id="plasma"
 for rate in [30,60,120]:
  scene.player._fire_cd=0
  Input.action_press("fire")
  for tick in rate:scene.player._physics_process(1.0/rate)
  Input.action_release("fire")
  check(get_tree().get_nodes_in_group("bullets").size()==10,"Equal firing cadence at "+str(rate)+" Hz")
  for shot in get_tree().get_nodes_in_group("bullets"):shot.despawn()
  await get_tree().process_frame
 # Reuse across weapons resets lifetime, texture, speed and collision state.
 var first:=pool.bullet(Vector2(3400,2200),Vector2.UP,"ion")
 var id:=first.get_instance_id()
 first._life=0.01;first.despawn()
 await get_tree().process_frame
 var reused:=pool.bullet(Vector2(3400,2200),Vector2.DOWN,"quantum_spread")
 check(reused.get_instance_id()==id and reused._life==2.4 and reused.speed==600,"Pool resets lifetime/weapon speed")
 check(reused.monitoring and not reused.get_node("CollisionShape2D").disabled,"Reactivated projectile has collision")
 reused.despawn();await get_tree().process_frame
 check(not reused.monitoring and reused.get_node("CollisionShape2D").disabled and not reused.is_in_group("bullets"),"Inactive projectile has no collision or active count")
 var created:=pool.created_bullets
 for batch in 300:
  var active: Array[Bullet]=[]
  for i in 24:active.append(pool.bullet(Vector2(3400+i*10,2200),Vector2.UP,"plasma"))
  for shot in active:shot.despawn()
  await get_tree().process_frame
 check(pool.created_bullets==created,"7200 repeated shots reuse warm pool without allocation growth")
 for i in 80:scene.pickup_spawner._spawn_pickup()
 check(get_tree().get_nodes_in_group("pickups").size()==32,"Stationary pickup memory remains bounded")
 check(not PerfDiagnostics.enabled and PerfDiagnostics.report().enabled==false,"Diagnostics inactive by default")
 scene.free();Game.is_running=false
 SoundEffects.stop_all()
 print("PERFORMANCE SAFETY: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
