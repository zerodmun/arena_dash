extends Node
## Native rendering/audio soak; desktop evidence does not certify Android devices.
var failures: Array[String]=[]
var samples: Array[Dictionary]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message);push_error(message)
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://qa/stability-stress.cfg"
 Game.audio_enabled=true
 Game.apply_audio()
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),-60)
 for id: String in Campaign.ORDER: Game.completed_levels[id]=3
 for map: String in Campaign.ORDER:
  Game.selected_map_id=map
  Game.selected_ship_id="speeder"
  Game.selected_weapon_id="quantum_spread"
  var scene: Node2D=load("res://scenes/main.tscn").instantiate()
  get_tree().root.add_child(scene);get_tree().current_scene=scene
  scene.player._invuln=100000
  Input.action_press("fire")
  var started:=Time.get_ticks_msec()
  var next_sample:=0
  while Time.get_ticks_msec()-started<12000:
   Game.enemies_destroyed=0 # Sustain combat beyond normal completion.
   await get_tree().process_frame
   var elapsed:=Time.get_ticks_msec()-started
   if elapsed>=next_sample:
    next_sample+=2000
    var pool: CombatPool=scene.get_node("CombatPool")
    var sample:={"map":map,"elapsed_ms":elapsed,"nodes":get_tree().get_node_count(),"memory":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"enemies":get_tree().get_nodes_in_group("enemies").size(),"hostile":get_tree().get_nodes_in_group("enemy_shots").size(),"shots":get_tree().get_nodes_in_group("bullets").size(),"particles":pool.created_bursts,"audio_players":SoundEffects.get_child_count()}
    samples.append(sample)
    check(sample.enemies<=30 and sample.hostile<=64,"Combat population bounded: "+map)
    check(sample.audio_players<=18,"Audio nodes bounded")
  Input.action_release("fire")
  scene.free();Game.is_running=false
  for frame in 4: await get_tree().process_frame
  print("STABILITY MAP: ",map," PASS")
 SoundEffects.stop_all()
 var file:=FileAccess.open("res://qa/stability-stress.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(samples,"  "))
 await get_tree().create_timer(.3).timeout
 print("NATIVE STABILITY: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
