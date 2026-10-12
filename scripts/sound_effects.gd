extends Node
## One persistent audio director. Effects are warmed once; music loads off the main thread.
const ROOT := "res://assets/audio/"
const MUSIC := {
 "menu": "music/command_menu.ogg", "hangar": "music/hangar_ambient.ogg",
 "campaign": "music/planet_exploration.ogg", "gameplay": "music/space_combat.ogg",
 "boss": "music/guardian_battle.ogg"
}
const EFFECTS := {
 "click": "ui/click.wav", "back": "ui/back.wav", "confirm": "ui/confirm.wav",
 "toggle": "ui/toggle.wav", "slider": "ui/slider.wav", "select": "ui/select.wav",
 "locked": "ui/locked.wav", "open": "ui/popup_open.wav", "close": "ui/popup_close.wav",
 "ion": "weapons/ion.wav", "plasma": "weapons/plasma.wav",
 "twin_laser": "weapons/twin_laser.wav", "quantum_spread": "weapons/quantum_spread.wav",
 "plasma_lance": "weapons/plasma.wav", "nova_burst": "weapons/quantum_spread.wav",
 "impact": "weapons/impact.wav", "hit": "spaceship/damage.wav",
 "critical": "spaceship/critical_warning.wav", "destroy": "spaceship/destruction.wav",
 "enemy_shoot": "enemies/laser.wav", "charge": "enemies/charge.wav",
 "explosion": "enemies/explosion.wav", "boss_attack": "enemies/guardian_attack.wav",
 "boss_destroy": "enemies/guardian_destruction.wav", "pickup": "gameplay/reward.wav",
 "start": "gameplay/mission_start.wav", "star": "gameplay/star.wav",
 "unlock": "gameplay/level_unlock.wav", "victory": "music/victory.ogg",
 "complete": "music/mission_complete.ogg", "defeat": "music/defeat.ogg"
}
const UI_EVENTS := ["click","back","confirm","toggle","slider","select","locked","open","close"]
const MAX_PLAYERS := 8
var diagnostic_stage := "full"
var _players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _cooldowns: Dictionary = {}
var _last_ui_time := -10000
var _music_tween: Tween
var _music_index := 0
var music_key := ""
var _wanted_music := ""
var _pending_loads: Dictionary = {}
var _engine: AudioStreamPlayer
var _warning: AudioStreamPlayer
var _sting: AudioStreamPlayer
var _paused := false
var _background := false
var _result_generation := 0
var _next_was_locked := false
var _save_timer: Timer
var played_events: Dictionary = {}

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 if OS.is_debug_build():
  for argument in OS.get_cmdline_user_args() + OS.get_cmdline_args():
   if argument.begins_with("--audio-stage="):
    var stage := argument.trim_prefix("--audio-stage=")
    if stage in ["off","ui","music","sfx","full"]: diagnostic_stage = stage
 print("AUDIO: stage=",diagnostic_stage," driver=",AudioServer.get_driver_name())
 for bus in ["Music","UI","SFX"]:
  if AudioServer.get_bus_index(bus) < 0:
   AudioServer.add_bus()
   var index := AudioServer.bus_count - 1
   AudioServer.set_bus_name(index,bus)
   AudioServer.set_bus_send(index,"Master")
 for id: String in EFFECTS:
  _streams[id] = _prepare_stream(load(ROOT + EFFECTS[id]))
 for i in MAX_PLAYERS: _players.append(_player("SFX"))
 for i in 3: _ui_players.append(_player("UI"))
 for i in 2: _music_players.append(_player("Music"))
 _engine = _player("SFX")
 _streams["engine"] = _prepare_stream(load(ROOT + "ambient/engine_loop.wav"))
 _engine.stream = _streams.engine
 _engine.volume_db = -27
 _warning = _player("SFX")
 _sting = _player("Music")
 Game.preferences_changed.connect(apply_settings)
 Game.game_started.connect(_mission_start)
 Game.game_over.connect(_mission_failed)
 Game.mission_completed.connect(_mission_complete)
 Game.boss_status_changed.connect(_boss_changed)
 Game.ship_selected.connect(func(_id: String) -> void: play("select"))
 Game.weapon_selected.connect(func(_id: String) -> void: play("select"))
 Game.map_selected.connect(func(_id: String) -> void: play("select"))
 Game.lives_changed.connect(_lives_changed)
 get_tree().node_added.connect(_node_added)
 _save_timer = Timer.new()
 _save_timer.one_shot = true
 _save_timer.wait_time = 0.3
 add_child(_save_timer)
 _save_timer.timeout.connect(Game.save_settings)
 apply_settings()

# Godot 4.7.2's WAV mixer includes loop_end in its decode range.
# Validate once before playback, never mutate an active stream on the audio thread.
func _prepare_stream(stream: AudioStream) -> AudioStream:
 if stream is AudioStreamWAV and stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
  if stream.format in [AudioStreamWAV.FORMAT_8_BITS,AudioStreamWAV.FORMAT_16_BITS]:
   var bytes_per_frame := (2 if stream.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if stream.stereo else 1)
   var frames: int = stream.data.size() / bytes_per_frame
   if frames < 2:
    push_error("Looping PCM requires at least two frames: " + stream.resource_path)
    return null
   stream.loop_begin = clampi(stream.loop_begin,0,frames-2)
   stream.loop_end = clampi(stream.loop_end,stream.loop_begin+1,frames-1)
 return stream

func _allows(kind: String) -> bool:
 return diagnostic_stage == "full" or diagnostic_stage == kind

func set_volume(bus: String, value: float) -> void:
 if not Game.audio_volumes.has(bus): return
 Game.audio_volumes[bus] = clampf(value,0,1)
 apply_settings()
 _save_timer.start()

func _player(bus: String) -> AudioStreamPlayer:
 var player := AudioStreamPlayer.new()
 player.bus = bus
 player.process_mode = Node.PROCESS_MODE_ALWAYS
 player.max_polyphony = 1
 add_child(player)
 return player

func apply_settings() -> void:
 for bus: String in Game.audio_volumes:
  var index := AudioServer.get_bus_index(bus)
  if index >= 0:
   var value := float(Game.audio_volumes[bus])
   AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001)) + (-8 if bus == "Music" and get_tree().paused else 0))
   AudioServer.set_bus_mute(index,value <= 0 or (bus == "Master" and not Game.audio_enabled))

func _node_added(node: Node) -> void:
 if node is BaseButton: _wire_button.call_deferred(node.get_instance_id())
 elif node is HSlider: _wire_slider.call_deferred(node.get_instance_id())

func _wire_slider(instance_id: int) -> void:
 var slider := instance_from_id(instance_id) as HSlider
 if not is_instance_valid(slider) or slider.has_meta("audio_wired"): return
 slider.set_meta("audio_wired",true)
 slider.value_changed.connect(func(_value: float) -> void: play("slider",-18))

func _wire_button(instance_id: int) -> void:
 var button := instance_from_id(instance_id) as BaseButton
 if not is_instance_valid(button) or button.is_queued_for_deletion() or button.has_meta("audio_wired"): return
 button.set_meta("audio_wired",true)
 button.pressed.connect(func() -> void:
  if is_instance_valid(button): play(_button_event(button)))

func _button_event(button: BaseButton) -> String:
 if button.has_meta("audio_event"): return str(button.get_meta("audio_event"))
 if button is CheckBox or button is CheckButton: return "toggle"
 if button is Button:
  for catalog in [Game.SHIPS,Game.WEAPONS]:
   for item: Dictionary in catalog.values():
    if button.text == item.name: return "select"
  var path: String = button.icon.resource_path if button.icon else ""
  if "close" in path or "back" in path or "home" in path: return "back"
  if "play" in path or "forward" in path: return "confirm"
  if "audio" in path: return "toggle"
 return "click"

func play(id: String, volume_db := -12.0, pitch := 1.0) -> void:
 if not Game.audio_enabled or not _streams.has(id) or _streams[id] == null: return
 var ui := id in UI_EVENTS
 if not _allows("ui" if ui else "sfx"): return
 if not ui and (get_tree().paused or _background): return
 var now := Time.get_ticks_msec()
 if ui and now - _last_ui_time < 25: return
 var interval := 55 if ui else 85
 if id in ["explosion","impact","enemy_shoot"]: interval = 110
 if id == "slider": interval = 100
 if now - int(_cooldowns.get(id,-10000)) < interval: return
 _cooldowns[id] = now
 var players := _ui_players if ui else _players
 # Drop a low-priority effect when busy, never cut a damage warning or UI response.
 for player in players:
  if not player.playing:
   player.stream = _streams[id]
   player.volume_db = volume_db
   player.pitch_scale = pitch
   player.set_meta("started_at",now)
   player.set_meta("event",id)
   player.play()
   if ui: _last_ui_time = now
   played_events[id] = int(played_events.get(id,0)) + 1
   return
 if id in ["critical","destroy","boss_destroy"] or Game.WEAPONS.has(id):
  var player: AudioStreamPlayer
  var oldest := now+1
  for candidate in _players:
   if candidate.get_meta("event","") in ["critical","destroy","boss_destroy"]: continue
   if int(candidate.get_meta("started_at",0)) < oldest:
    player = candidate
    oldest = int(candidate.get_meta("started_at",0))
  if player == null: return
  player.stream = _streams[id]
  player.volume_db = volume_db
  player.pitch_scale = pitch
  player.set_meta("started_at",now)
  player.set_meta("event",id)
  player.play()
  played_events[id] = int(played_events.get(id,0)) + 1

func play_shoot() -> void:
 play(Game.selected_weapon_id,-14,randf_range(0.97,1.03))
func play_explosion() -> void:
 play("explosion",-10,randf_range(0.94,1.06))
func play_pickup() -> void:
 play("pickup",-10)
func play_hit() -> void:
 if Game.audio_enabled and _allows("sfx"):
  _warning.stream = _streams.hit
  _warning.volume_db = -8
  _warning.play()
  played_events["hit"] = int(played_events.get("hit",0)) + 1

func music(key: String) -> void:
 if not _allows("music") or not MUSIC.has(key): return
 _wanted_music = key
 if key == music_key: return
 var path: String = ROOT + MUSIC[key]
 if not _pending_loads.has(key):
  if ResourceLoader.load_threaded_request(path,"AudioStream",false,ResourceLoader.CACHE_MODE_REUSE) == OK:
   _pending_loads[key] = path

func _process(delta: float) -> void:
 for key: String in _pending_loads.keys():
  var path: String = _pending_loads[key]
  var status := ResourceLoader.load_threaded_get_status(path)
  if status == ResourceLoader.THREAD_LOAD_LOADED:
   var stream := ResourceLoader.load_threaded_get(path) as AudioStream
   _pending_loads.erase(key)
   if key == _wanted_music and stream: _transition_music(key,stream)
  elif status == ResourceLoader.THREAD_LOAD_FAILED:
   push_error("Music load failed: " + path)
   _pending_loads.erase(key)
 var pause := get_tree().paused or _background
 if pause != _paused:
  _paused = pause
  for player in _players: player.stream_paused = pause
  _engine.stream_paused = pause
  _warning.stream_paused = pause
  for player in _music_players: player.stream_paused = _background
  _sting.stream_paused = _background
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(maxf(float(Game.audio_volumes.Music),0.0001)) + (-8 if get_tree().paused else 0))
 for player in _music_players: player.stream_paused = _background
 _sting.stream_paused = _background
 for player in _ui_players: player.stream_paused = _background
 if _engine.playing and not pause:
  var player := get_tree().get_first_node_in_group("player") as Player
  var moving := player.velocity.length() / maxf(player.speed,1) if player else 0.0
  _engine.pitch_scale = lerpf(_engine.pitch_scale,0.9+moving*0.25,minf(1,delta*5))
  _engine.volume_db = lerpf(_engine.volume_db,-30+moving*7,minf(1,delta*5))

func _transition_music(key: String, stream: AudioStream) -> void:
 if _music_tween: _music_tween.kill()
 var outgoing := _music_players[_music_index]
 _music_index = 1 - _music_index
 var incoming := _music_players[_music_index]
 incoming.stop()
 incoming.stream = stream
 incoming.volume_db = -60
 incoming.play()
 incoming.stream_paused = _background
 music_key = key
 _music_tween = create_tween().set_parallel(true)
 _music_tween.tween_property(outgoing,"volume_db",-60.0,0.65)
 _music_tween.tween_property(incoming,"volume_db",-15.0,0.65)
 _music_tween.chain().tween_callback(func() -> void: outgoing.stop(); outgoing.stream = null)

func _mission_start() -> void:
 var next := Campaign.index(Game.selected_map_id)+1
 _next_was_locked = next < Campaign.ORDER.size() and not Game.is_level_unlocked(Campaign.ORDER[next])
 _result_generation += 1
 stop_gameplay()
 _sting.stop()
 _cooldowns.clear()
 music("gameplay")
 play("start",-12)
 _engine.stream = _streams.engine
 if _allows("sfx") and _engine.stream: _engine.play()

func _boss_changed() -> void:
 if not Game.is_running: return
 music("boss" if Game.boss_health > 0 and not Game.boss_defeated else "gameplay")

func _lives_changed(value: int) -> void:
 if value == 1 and Game.is_running: play("critical",-8)

func stop_gameplay() -> void:
 for player in _players: player.stop(); player.stream = null
 if _engine: _engine.stop()
 if _warning: _warning.stop()

func enter_screen(key: String) -> void:
 _result_generation += 1
 stop_gameplay()
 if _sting: _sting.stop()
 music(key)

func _fade_music() -> void:
 _wanted_music = ""
 music_key = ""
 if _music_tween: _music_tween.kill()
 _music_tween = create_tween().set_parallel(true)
 for player in _music_players:
  _music_tween.tween_property(player,"volume_db",-60.0,0.35)
  _music_tween.tween_callback(func() -> void: player.stop(); player.stream = null).set_delay(0.35)

func _jingle(id: String) -> void:
 if not _allows("music"): return
 _sting.stream = _streams[id]
 _sting.volume_db = -10
 _sting.play()

func _mission_failed() -> void:
 _result_generation += 1
 stop_gameplay()
 _fade_music()
 play("destroy",-7)
 _jingle("defeat")

func _mission_complete() -> void:
 _result_generation += 1
 var generation := _result_generation
 stop_gameplay()
 _fade_music()
 _jingle("victory" if Game.last_attempt_stars == 3 else "complete")
 for star in Game.last_attempt_stars:
  await get_tree().create_timer(0.35,true).timeout
  if generation != _result_generation: return
  play("star",-12,1.0+star*0.12)
 var next := Campaign.index(Game.selected_map_id)+1
 if Game.last_attempt_stars == 3 and _next_was_locked and next < Campaign.ORDER.size() and Game.is_level_unlocked(Campaign.ORDER[next]):
  await get_tree().create_timer(0.4,true).timeout
  if generation == _result_generation: play("unlock",-12)

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
  _background = true
  if is_instance_valid(_save_timer) and not _save_timer.is_stopped():
   _save_timer.stop()
   Game.save_settings()
 elif what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN]: _background = false

func stop_all() -> void:
 _result_generation += 1
 _wanted_music = ""
 music_key = ""
 if _music_tween: _music_tween.kill()
 stop_gameplay()
 for player in _music_players: player.stop(); player.stream = null
 for player in _ui_players: player.stop(); player.stream = null
 if _sting: _sting.stop(); _sting.stream = null
 if _warning: _warning.stream = null
 if _engine: _engine.stream = null

func _exit_tree() -> void:
 stop_all()
 # Consume pending threaded requests at shutdown so their resources are released.
 for path: String in _pending_loads.values(): ResourceLoader.load_threaded_get(path)
 _pending_loads.clear()
 _streams.clear()
 for player in [_engine,_warning,_sting]:
  if is_instance_valid(player): player.stream = null
 _music_tween = null
