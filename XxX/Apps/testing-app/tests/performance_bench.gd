extends Node
var scene: Node2D
var samples: Array[float]=[]
var phases: Dictionary={}
var elapsed:=0.0
var phase:="light"
var previous:=0
var _score_clock:=0.0
var _refill:=0.0
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://build/performance-bench.cfg"
 Game.completed_levels={}
 for id: String in Campaign.ORDER: Game.completed_levels[id]=3
 Game.selected_map_id="toxic"
 Game.selected_ship_id="speeder"
 Game.selected_weapon_id="quantum_spread"
 Game.high_score=0
 seed(4109)
 scene=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene)
 get_tree().current_scene=scene
 scene.enemy_spawner.set_physics_process(false)
 scene.player._invuln=1000
 Input.action_press("fire")
 previous=Time.get_ticks_usec()
func _process(delta: float) -> void:
 if not is_instance_valid(scene):return
 var now:=Time.get_ticks_usec()
 if elapsed>1: samples.append((now-previous)/1000.0)
 previous=now
 elapsed+=delta
 Game.enemies_destroyed=0
 _refill-=delta
 if _refill<=0:
  _refill=0.5
  var target:=4 if phase=="light" else 28
  for i in maxi(0,target-get_tree().get_nodes_in_group("enemies").size()):scene.enemy_spawner._spawn_enemy("orbiter" if i%3==0 else "gunner")
 _score_clock-=delta
 if _score_clock<=0:
  _score_clock=0.1
  Game.add_score(10)
 if phase=="light" and elapsed>=6:
  phases.light=summary()
  samples.clear();phase="heavy";elapsed=0
 elif phase=="heavy" and elapsed>=13:
  phases.heavy=summary()
  var args:=OS.get_cmdline_user_args()
  var path:="res://build/performance-baseline.json" if "--baseline" in args else ("res://build/performance-diagnostics.json" if "--perf" in args else "res://build/performance-after.json")
  var file:=FileAccess.open(path,FileAccess.WRITE)
  file.store_string(JSON.stringify(phases,"  "))
  print("PERFORMANCE BENCH: ",JSON.stringify(phases))
  Input.action_release("fire")
  SoundEffects.stop_all()
  set_process(false)
  scene.queue_free()
  for i in 4: await get_tree().process_frame
  get_tree().quit()
func summary() -> Dictionary:
 samples.sort()
 var total:=0.0
 for value in samples:total+=value
 return {"frames":samples.size(),"average_ms":total/maxi(1,samples.size()),"p95_ms":samples[int((samples.size()-1)*0.95)],"p99_ms":samples[int((samples.size()-1)*0.99)],"worst_ms":samples.back(),"over_25ms":samples.filter(func(x: float)->bool:return x>25).size(),"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"enemies":get_tree().get_nodes_in_group("enemies").size(),"bullets":get_tree().get_nodes_in_group("bullets").size(),"hostile_shots":get_tree().get_nodes_in_group("enemy_shots").size(),"physics_seconds":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),"process_seconds":Performance.get_monitor(Performance.TIME_PROCESS),"renderer":RenderingServer.get_video_adapter_name()}
