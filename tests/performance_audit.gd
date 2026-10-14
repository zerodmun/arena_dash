extends Node
var report: Dictionary = {}
func _ready() -> void: run.call_deferred()
func stats(values: Array[float]) -> Dictionary:
 values.sort()
 var total := 0.0
 for value in values: total += value
 return {"average_ms":total/values.size(),"p95_ms":values[int((values.size()-1)*0.95)],"worst_ms":values.back()}
func run() -> void:
 Game.save_path="res://qa/performance-audit/isolated.cfg"
 Game.completed_levels={};Game.map_zoom=1.0;Game.map_focus_planet=""
 var map: LevelSelect=load("res://scenes/level_select.tscn").instantiate()
 get_tree().root.add_child(map)
 await get_tree().process_frame
 map.set_process(false)
 var zoom_times: Array[float]=[]
 var pan_times: Array[float]=[]
 for i in 1200:
  var start:=Time.get_ticks_usec()
  map._apply_zoom(0.5+1.5*(sin(i*0.013)*0.5+0.5),map._map_view.size*0.5)
  zoom_times.append((Time.get_ticks_usec()-start)/1000.0)
  start=Time.get_ticks_usec()
  map._set_offset(Vector2(-600+sin(i*0.1)*300,-500+cos(i*0.1)*250))
  pan_times.append((Time.get_ticks_usec()-start)/1000.0)
  await get_tree().process_frame
 report.zoom=stats(zoom_times);report.pan=stats(pan_times)
 map.free()
 var start:=Time.get_ticks_usec()
 for i in 10000: WeaponData.from_catalog("quantum_spread")
 report.weapon_snapshot_10000_ms=(Time.get_ticks_usec()-start)/1000.0
 report.levels={}
 var packed: PackedScene=load("res://scenes/main.tscn")
 for id: String in Campaign.ORDER:
  Game.selected_map_id=id;Game.is_running=false
  seed(4109)
  start=Time.get_ticks_usec()
  var scene:=packed.instantiate()
  get_tree().root.add_child(scene);get_tree().current_scene=scene
  var init_ms:=(Time.get_ticks_usec()-start)/1000.0
  await get_tree().process_frame
  report.levels[id]={"initialize_ms":init_ms,"nodes":get_tree().get_node_count(),"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)}
  scene.free()
  await get_tree().process_frame
 report.platform=OS.get_name();report.display=DisplayServer.get_name();report.engine=Engine.get_version_info().string
 var suffix:="before" if "--baseline" in OS.get_cmdline_user_args() else "after"
 var file:=FileAccess.open("res://qa/performance-audit/"+suffix+"-"+DisplayServer.get_name()+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 print("PERFORMANCE AUDIT: ",JSON.stringify(report))
 SoundEffects.stop_all()
 await get_tree().create_timer(0.2).timeout
 get_tree().quit()
