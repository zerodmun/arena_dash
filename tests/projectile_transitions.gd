extends Node
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _ready() -> void:run.call_deferred()
func run() -> void:
 Game.save_path=("user://projectile-transitions-test.cfg" if OS.get_name()=="Android" else "res://qa/projectile-transitions-test.cfg")
 Game.selected_map_id="cyber";Game.completed_levels={}
 var ids: Dictionary={}
 for round in 14:
  var scene:Node2D=load("res://scenes/main.tscn").instantiate()
  get_tree().root.add_child(scene);get_tree().current_scene=scene
  scene.enemy_spawner.set_physics_process(false);scene.pickup_spawner.set_physics_process(false)
  Game.start();scene.player.set_physics_process(false)
  Game.selected_ship_id=Game.SHIPS.keys()[round%16]
  Game.selected_weapon_id=Game.WEAPONS.keys()[round%6];scene.player.apply_customization()
  scene.player._shoot()
  var manager:ProjectileManager=scene.get_node("ProjectileManager")
  var pattern:=EquipmentCatalog.firing_pattern(Game.get_current_weapon())
  check(manager.active_projectiles.size()==pattern.size(),"Scene has intended volley")
  for shot:Projectile in manager.active_projectiles.values():
   check(not ids.has(shot.trace_id),"Runtime IDs never repeat across levels")
   ids[shot.trace_id]=true
  Game.start()
  check(manager.active_projectiles.is_empty(),"Restart clears all active shots immediately")
  check(scene.player.weapon_controller.cooldown==.25,"Restart resets sole firing clock")
  for i in 3:await get_tree().process_frame
  check(manager.get_child_count()==1,"Restart destroys shot nodes and effects")
  scene.player._shoot()
  var previous:WeaponController=scene.player.weapon_controller
  # Destroy while firing, then instantiate the next real scene with no old authority.
  scene.free();get_tree().current_scene=null
  check(previous.request_fire()==0,"Retained old controller cannot fire after transition")
  check(get_tree().get_nodes_in_group("bullets").is_empty(),"Transition leaves no player shots")
 Input.action_release("fire");Game.is_running=false;SoundEffects.stop_all()
 print("PROJECTILE_TRANSITIONS ",JSON.stringify({"rounds":14,"checks":checks,"failures":failures}))
 get_tree().quit(0 if failures.is_empty() else 1)
