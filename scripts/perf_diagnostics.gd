extends Node
## Opt-in debug diagnostics. Release exports do not sample, monitor input or measure rendering.
const CAPACITY := 7200
var enabled := false
var _frames:=PackedFloat64Array()
var _latencies:=PackedFloat64Array()
var _count:=0
var _input_count:=0
var _last:=0
var _pending_input:=0
var _interval:=0.0
var snapshot: Dictionary={}
func _ready() -> void:
 enabled=OS.is_debug_build() and "--perf" in OS.get_cmdline_user_args()
 process_mode=Node.PROCESS_MODE_ALWAYS
 set_process(enabled)
 set_process_input(enabled)
 if not enabled:return
 _frames.resize(CAPACITY);_latencies.resize(CAPACITY)
 _last=Time.get_ticks_usec()
 RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
func mark_input() -> void:
 if enabled and _pending_input==0:_pending_input=Time.get_ticks_usec()
func consume_input() -> void:
 if not enabled or _pending_input==0:return
 _latencies[_input_count%CAPACITY]=(Time.get_ticks_usec()-_pending_input)/1000.0
 _input_count+=1
 _pending_input=0
func _process(delta: float) -> void:
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
 return {"fps":Engine.get_frames_per_second(),"frame_average_ms":avg,"frame_p95_ms":percentile(frames,0.95),"frame_p99_ms":percentile(frames,0.99),"frame_worst_ms":percentile(frames,1),"spikes_over_25ms":spikes,"samples":frames.size(),"physics_update_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"render_cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(rid),"render_gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(rid),"input_to_physics_p95_ms":percentile(latency,0.95),"input_samples":latency.size(),"enemies":get_tree().get_nodes_in_group("enemies").size(),"projectiles":get_tree().get_nodes_in_group("bullets").size()+get_tree().get_nodes_in_group("enemy_shots").size(),"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
func percentile(values: PackedFloat64Array,fraction: float) -> float:
 return values[int((values.size()-1)*fraction)] if not values.is_empty() else 0.0

func _input(event: InputEvent) -> void:
 if not Game.is_running or get_tree().paused:return
 if event is InputEventKey and event.pressed and not event.echo:
  for action in ["fire","move_left","move_right","move_up","move_down"]:
   if event.is_action(action):mark_input();break
