extends Node
## Opt-in debug diagnostics. Release exports do not sample, monitor input or measure rendering.
const CAPACITY := 7200
var enabled := false
var _auto_gameplay := false
var _frames:=PackedFloat64Array()
var _latencies:=PackedFloat64Array()
var _count:=0
var _input_count:=0
var _last:=0
var _pending_input:=0
var _interval:=0.0
var snapshot: Dictionary={}
var _equipment_cycle := false
var _equipment_interval := 1.5
var _projectile_markers := false
var _advanced_review := false
func _ready() -> void:
 var arguments := OS.get_cmdline_user_args() + OS.get_cmdline_args()
 _auto_gameplay = OS.is_debug_build() and "--stability-auto" in arguments
 if OS.is_debug_build() and OS.has_feature("arena_review") and FileAccess.file_exists("user://movement_fire_qa.json"):
  var qa_config = JSON.parse_string(FileAccess.get_file_as_string("user://movement_fire_qa.json"))
  if qa_config is Dictionary:
   _advanced_review=bool(qa_config.get("advanced_campaign",false))
   _auto_gameplay=bool(qa_config.get("gameplay",false)) or _advanced_review
   if qa_config.get("projectile_trace",false):ProjectileTrace.start()
 enabled=OS.is_debug_build() and ("--perf" in arguments or _auto_gameplay)
 if _auto_gameplay: _start_automated_gameplay.call_deferred()
 process_mode=Node.PROCESS_MODE_ALWAYS
 set_process(enabled)
 set_process_input(enabled)
 if not enabled:return
 print("PERF_START ",JSON.stringify({"platform":OS.get_name(),"model":OS.get_model_name(),"engine":Engine.get_version_info().string,"rendering_method":RenderingServer.get_current_rendering_method(),"rendering_driver":RenderingServer.get_current_rendering_driver_name()}))
 Game.game_started.connect(func() -> void: _event("mission_started"))
 Game.game_over.connect(func() -> void: _event("mission_failed"))
 Game.mission_completed.connect(func() -> void: _event("mission_completed"))
 _frames.resize(CAPACITY);_latencies.resize(CAPACITY)
 _last=Time.get_ticks_usec()
 RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
func _start_automated_gameplay() -> void:
 # Let the normal threaded loading scene finish before switching scenes.
 await get_tree().process_frame
 if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/loading.tscn":
  var loading := get_tree().current_scene
  while is_instance_valid(loading) and loading.is_inside_tree():
   await get_tree().process_frame
 if _advanced_review:
  _auto_gameplay=false
  add_child(AdvancedCampaignReview.new())
  return
 # Debug-only isolation build: never save test progression over a player's save.
 Game.save_path = "user://arena_dash_diagnostic_save.cfg"
 Game.selected_map_id = Campaign.ORDER[0]
 # Optional device QA selection, read only in this opt-in debug automation path.
 if FileAccess.file_exists("user://movement_fire_qa.json"):
  var config = JSON.parse_string(FileAccess.get_file_as_string("user://movement_fire_qa.json"))
  if config is Dictionary:
   _equipment_cycle=bool(config.get("equipment_cycle",false))
   _equipment_interval=clampf(float(config.get("equipment_interval",1.5)),1.5,5.0)
   _projectile_markers=bool(config.get("projectile_markers",false))
   if Game.SHIPS.has(config.get("ship", "")): Game.selected_ship_id=config.ship
   if Game.WEAPONS.has(config.get("weapon", "")): Game.selected_weapon_id=config.weapon
   if Campaign.ORDER.has(config.get("map", "")): Game.selected_map_id=config.map
 if OS.is_debug_build() and OS.has_feature("arena_review"):
  # Only the separate QA package receives temporary in-memory test entitlements.
  Game.owned_ships[Game.selected_ship_id]=true
  Game.owned_weapons[Game.selected_weapon_id]=true
 Game.audio_enabled = true
 Game.audio_volumes = {"Master":0.3,"Music":0.6,"UI":0.6,"SFX":0.6}
 Game.apply_audio()
 var error := get_tree().change_scene_to_file("res://scenes/main.tscn")
 if error != OK:
  push_error("Automated gameplay scene failed: " + str(error))
  _auto_gameplay = false
  return
 await get_tree().scene_changed
 var player := get_tree().get_first_node_in_group("player") as Player
 if player:
  player._invuln = 100000
  if "--stability-touch" not in (OS.get_cmdline_args() + OS.get_cmdline_user_args()):
   Input.action_press("fire")
  if ProjectileTrace.enabled and _projectile_markers:get_tree().current_scene.add_child(ProjectileDebugOverlay.new())
  print("AUTO_GAMEPLAY_STARTED")
  if _equipment_cycle: _run_equipment_cycle.call_deferred(player)
 else:
  push_error("Automated gameplay player missing")
  _auto_gameplay = false

func mark_input() -> void:
 if enabled and _pending_input==0:_pending_input=Time.get_ticks_usec()
func consume_input() -> void:
 if not enabled or _pending_input==0:return
 _latencies[_input_count%CAPACITY]=(Time.get_ticks_usec()-_pending_input)/1000.0
 _input_count+=1
 _pending_input=0
func _process(delta: float) -> void:
 if _auto_gameplay: Game.enemies_destroyed = 0
 if get_tree().paused:_pending_input=0
 var now:=Time.get_ticks_usec()
 _frames[_count%CAPACITY]=(now-_last)/1000.0
 _last=now;_count+=1;_interval+=delta
 if _interval>=5.0:
  _interval=0
  snapshot=report()
  print("PERF ",JSON.stringify(snapshot))
func report() -> Dictionary:
 if not enabled:return {"enabled":false}
 var frames:=_frames.slice(0,mini(_count,CAPACITY));frames.sort()
 var latency:=_latencies.slice(0,mini(_input_count,CAPACITY));latency.sort()
 var total:=0.0
 var spikes:=0
 for ms in frames:total+=ms;spikes+=int(ms>25.0)
 var avg:=total/maxi(1,frames.size())
 var rid:=get_viewport().get_viewport_rid()
 var player := get_tree().get_first_node_in_group("player") as Player
 var joystick := get_tree().get_first_node_in_group("joystick") as GameJoystick
 var controls := {"fire_pressed":Input.is_action_pressed("fire"),"joystick_pressed":is_instance_valid(joystick) and joystick.pressed,"joystick_output":[joystick.output.x,joystick.output.y] if is_instance_valid(joystick) else [],"player_position":[player.position.x,player.position.y] if is_instance_valid(player) else []}
 return {"controls":controls,"uptime_ms":Time.get_ticks_msec(),"game_running":Game.is_running,"paused":get_tree().paused,"mission_elapsed":Game.mission_elapsed,"map":Game.selected_map_id,"ship":Game.selected_ship_id,"weapon":Game.selected_weapon_id,"audio_nodes":SoundEffects.get_child_count(),"fps":Engine.get_frames_per_second(),"frame_average_ms":avg,"frame_p95_ms":percentile(frames,0.95),"frame_p99_ms":percentile(frames,0.99),"frame_worst_ms":percentile(frames,1),"spikes_over_25ms":spikes,"samples":frames.size(),"physics_update_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"render_cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(rid),"render_gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(rid),"input_to_physics_p95_ms":percentile(latency,0.95),"input_samples":latency.size(),"enemies":get_tree().get_nodes_in_group("enemies").size(),"projectiles":get_tree().get_nodes_in_group("bullets").size()+get_tree().get_nodes_in_group("enemy_shots").size(),"nodes":get_tree().get_node_count(),"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
func percentile(values: PackedFloat64Array,fraction: float) -> float:
 return values[int((values.size()-1)*fraction)] if not values.is_empty() else 0.0

func _input(event: InputEvent) -> void:
 if not Game.is_running or get_tree().paused:return
 if event is InputEventKey and event.pressed and not event.echo:
  for action in ["fire","move_left","move_right","move_up","move_down"]:
   if event.is_action(action):mark_input();break

func _event(reason: String) -> void:
 if enabled: print("PERF_EVENT ",JSON.stringify({"reason":reason,"uptime_ms":Time.get_ticks_msec(),"game_running":Game.is_running,"mission_elapsed":Game.mission_elapsed,"map":Game.selected_map_id}))
func _notification(what: int) -> void:
 if enabled and what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_WM_CLOSE_REQUEST]: _event("notification_"+str(what))

func _run_equipment_cycle(player: Player) -> void:
 # Real Android touch remains the sole input source. Recenter between loadouts
 # to exercise all equipment without modifying the player's ownership or save.
 await get_tree().create_timer(4.0).timeout
 for ship_id in Game.SHIPS:
  for weapon_id in Game.WEAPONS:
   Game.selected_ship_id=ship_id
   Game.selected_weapon_id=weapon_id
   for bullet in get_tree().get_nodes_in_group("bullets"):bullet.despawn("qa_loadout_change")
   player.apply_customization()
   player.global_position=Vector2(3400,2200)
   player.reset_physics_interpolation()
   var camera:Camera2D=get_tree().current_scene.get_node("Camera2D")
   camera.global_position=player.global_position
   camera.reset_physics_interpolation()
   print("EQUIPMENT_CASE_START ",ship_id,"/",weapon_id)
   await get_tree().create_timer(_equipment_interval).timeout
   print("EQUIPMENT_CASE_END ",JSON.stringify({"ship":ship_id,"weapon":weapon_id,"fire":Input.is_action_pressed("fire"),"movement":player.velocity.length(),"bullets":get_tree().get_nodes_in_group("bullets").size()}))
 print("EQUIPMENT_MATRIX_COMPLETE combinations=96")
