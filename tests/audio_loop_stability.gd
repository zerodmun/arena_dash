extends Node
## Real-time mixer/combat soak; desktop results cannot certify Android callbacks.
var failures: Array[String] = []
var samples: Array[Dictionary] = []
func check(condition: bool, message: String) -> void:
 if not condition:
  failures.append(message)
  push_error(message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 var seconds := 12
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--seconds="): seconds = maxi(12,int(argument.trim_prefix("--seconds=")))
 Game.save_path = "res://qa/audio-loop-test-save.cfg"
 Game.audio_enabled = true
 Game.audio_volumes.Master = 0.006
 Game.apply_audio()
 var engine: AudioStreamWAV = SoundEffects._streams.engine
 var frames: int = engine.data.size() / (2 * (2 if engine.stereo else 1))
 check(engine.loop_end < frames,"Engine PCM endpoint is inside data")
 # Validate the loading guard with a fresh resource, never mutate active shared audio.
 var invalid := AudioStreamWAV.new()
 invalid.format = AudioStreamWAV.FORMAT_16_BITS
 invalid.mix_rate = 24000
 invalid.data = PackedByteArray([0,0,0,0,0,0,0,0])
 invalid.loop_mode = AudioStreamWAV.LOOP_FORWARD
 invalid.loop_end = 4
 SoundEffects._prepare_stream(invalid)
 check(invalid.loop_end == 3,"Guard rejects one-past-end PCM endpoint")
 Game.selected_map_id = "coast"
 Game.selected_weapon_id = "quantum_spread"
 var scene: Node2D = load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene)
 get_tree().current_scene = scene
 scene.player._invuln = 100000
 Input.action_press("fire")
 var started := Time.get_ticks_msec()
 var next_sample := 0
 var wraps := 0
 while Time.get_ticks_msec()-started < seconds*1000:
  Game.enemies_destroyed = 0
  await get_tree().process_frame
  if Engine.get_process_frames() % 15 == 0:
   SoundEffects._engine.seek(engine.get_length()-0.004)
   wraps += 1
  var elapsed := Time.get_ticks_msec()-started
  if elapsed >= next_sample:
   next_sample += 10000
   var sample := {"elapsed_ms":elapsed,"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":get_tree().get_node_count(),"audio_players":SoundEffects.get_child_count(),"enemies":get_tree().get_nodes_in_group("enemies").size(),"hostile":get_tree().get_nodes_in_group("enemy_shots").size(),"pcm_wrap_seeks":wraps,"audio_stage":SoundEffects.diagnostic_stage,"audio_background":SoundEffects._background,"engine_paused":SoundEffects._engine.stream_paused}
   samples.append(sample)
   check(sample.enemies <= 28 and sample.hostile <= 64,"Combat allocations remain bounded")
   check(sample.audio_players == 17,"Audio players remain pooled")
   if SoundEffects._allows("sfx") and not SoundEffects._background and not get_tree().paused:
    check(SoundEffects._engine.playing or SoundEffects._engine.stream_paused,"Engine loop survives repeated endpoint crossings")
   print("AUDIO SOAK: ",JSON.stringify(sample))
 Input.action_release("fire")
 var elapsed := (Time.get_ticks_msec()-started)/1000.0
 scene.free()
 Game.is_running = false
 SoundEffects.stop_all()
 var report := {"platform":OS.get_name(),"audio_driver":AudioServer.get_driver_name(),"elapsed_seconds":elapsed,"requested_seconds":seconds,"endpoint_crossing_seeks":wraps,"failures":failures,"samples":samples,"android_verified":OS.get_name()=="Android"}
 var file := FileAccess.open("res://qa/audio-loop-stability.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 print("AUDIO LOOP STABILITY: ","PASS" if failures.is_empty() else "FAIL"," / ",elapsed," seconds / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
