extends Node
var scene: Node2D
var seconds:=0.0
var next_sample:=60.0
var records: Array[Dictionary]=[]
func _ready() -> void:call_deferred("run")
func run() -> void:
 Game.audio_enabled=false # Accelerated headless soak excludes wall-clock audio-driver scheduling.
 Game.apply_audio()
 Game.save_path="res://build/performance-soak.cfg"
 for id: String in Campaign.ORDER:Game.completed_levels[id]=3
 Game.selected_map_id="toxic";Game.selected_ship_id="speeder";Game.selected_weapon_id="quantum_spread"
 scene=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 scene.player._invuln=100000
 Input.action_press("fire")
func _process(delta: float) -> void:
 if not is_instance_valid(scene):return
 seconds+=delta
 Game.enemies_destroyed=0 # Keep the same mission running beyond normal completion for a soak.
 if seconds>=next_sample:
  next_sample+=60
  records.append({"simulation_seconds":seconds,"nodes":get_tree().get_node_count(),"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"enemies":get_tree().get_nodes_in_group("enemies").size(),"bullets":get_tree().get_nodes_in_group("bullets").size(),"hostile_shots":get_tree().get_nodes_in_group("enemy_shots").size(),"pickups":get_tree().get_nodes_in_group("pickups").size()})
 if seconds>=1200:
  set_process(false)
  Input.action_release("fire");Game.is_running=false
  var file:=FileAccess.open("res://build/performance-soak.json",FileAccess.WRITE)
  file.store_string(JSON.stringify(records,"  "))
  var failures:=0
  for sample in records:
   if sample.enemies>28 or sample.hostile_shots>64 or sample.pickups>32:failures+=1
  # Compare settled final vs middle samples; concurrent object bursts can vary within the pool bounds.
  if records.back().nodes>records[9].nodes+100:failures+=1
  print("PERFORMANCE SOAK: ","PASS" if failures==0 else "FAIL"," / 20 simulated minutes / ",failures," failures")
  SoundEffects.stop_all()
  scene.queue_free()
  for i in 4:await get_tree().process_frame
  SoundEffects.stop_all()
  get_tree().quit(0 if failures==0 else 1)
