extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message);push_error(message)
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://qa/meteor-lifecycle.cfg"
 Game.completed_levels={"cyber":3,"forest":3};Game.selected_map_id="space"
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 scene.enemy_spawner.set_physics_process(false)
 scene.player._invuln=100000
 for frame in 4: await get_tree().process_frame
 for stage in [0.1,1.2]:
  Game.is_running=true
  scene._spawn_meteor_strike(Vector2(3000,1800),0)
  await get_tree().create_timer(stage).timeout
  check(not get_tree().get_nodes_in_group("mission_hazards").is_empty(),"Hazard created before cancellation")
  Game.is_running=false
  await get_tree().create_timer(1.6).timeout
  check(get_tree().get_nodes_in_group("mission_hazards").is_empty(),"Stopped mission cleans warning/descent visuals")
 Game.is_running=true
 scene._spawn_meteor_strike(Vector2(3000,1800),0)
 await get_tree().create_timer(1.2).timeout
 scene._on_game_started()
 await get_tree().create_timer(.5).timeout
 check(get_tree().get_nodes_in_group("mission_hazards").is_empty(),"Retry safely clears pending hazards")
 scene.free();Game.is_running=false;SoundEffects.stop_all()
 await get_tree().create_timer(.2).timeout
 print("METEOR LIFECYCLE: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
