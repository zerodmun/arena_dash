extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("run")
func run() -> void:
 Game.save_path="res://qa/performance-safety.cfg"
 Game.completed_levels={};Game.selected_map_id="cyber";Game.selected_ship_id="titan"
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 scene.enemy_spawner.set_physics_process(false)
 scene.pickup_spawner.set_physics_process(false)
 scene.player.set_physics_process(false)
 var manager: ProjectileManager=scene.get_node("ProjectileManager")
 var writes:=Game.save_writes
 for i in 1000:Game.add_score(1)
 check(Game.save_writes==writes,"Scoring has no synchronous disk writes")
 Game.flush_save()
 check(Game.save_writes==writes+1,"Boundary flush persists dirty high score once")
 var cfg:=ConfigFile.new();cfg.load(Game.save_path)
 check(cfg.get_value("stats","high_score")==Game.high_score,"High score persists after flush")
 for weapon: String in Game.WEAPONS:
  for rate in [30,60,120]:
   Game.selected_weapon_id=weapon;scene.player.apply_customization()
   scene.player.global_position=Vector2(3332,-500);scene.player.global_rotation=PI/2
   scene.player._shoot()
   var bullet:Projectile=get_tree().get_nodes_in_group("bullets")[-1]
   bullet.set_physics_process(false)
   var initial:=bullet.global_position
   for step in rate:bullet._physics_process(1.0/rate)
   check(bullet.global_position.distance_to(initial+bullet.direction*bullet.speed)<0.1,"Projectile real-second speed at "+str(rate)+" Hz")
   manager.cleanup()
   await get_tree().process_frame
 # Firing preserves fractional cooldown debt without accumulating a backlog while idle.
 scene.player.fire_rate=0.11
 Game.selected_weapon_id="plasma"
 for rate in [30,60,120]:
  scene.player.weapon_controller.cooldown=0
  Input.action_press("fire")
  for tick in rate:scene.player._physics_process(1.0/rate)
  Input.action_release("fire")
  check(get_tree().get_nodes_in_group("bullets").size()==10,"Equal firing cadence at "+str(rate)+" Hz")
  for shot in get_tree().get_nodes_in_group("bullets"):shot.despawn()
  await get_tree().process_frame
 # Fresh allocations must leave no live player-shot nodes after cleanup.
 for batch in 100:
  for i in 24:scene.player._shoot()
  manager.cleanup()
  await get_tree().process_frame
  check(manager.active_projectiles.is_empty(),"Fresh shots are fully released")
 check(manager.get_child_count()==1,"Manager retains only its impact manager after 2400 volleys")
 for i in 80:scene.pickup_spawner._spawn_pickup()
 check(get_tree().get_nodes_in_group("pickups").size()==32,"Stationary pickup memory remains bounded")
 check(not PerfDiagnostics.enabled and PerfDiagnostics.report().enabled==false,"Diagnostics inactive by default")
 scene.free();Game.is_running=false
 SoundEffects.stop_all()
 # Let the audio mixer release stopped playback before the headless runner exits.
 await get_tree().create_timer(0.2,true).timeout
 print("PERFORMANCE SAFETY: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
