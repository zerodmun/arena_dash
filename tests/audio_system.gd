extends Node
var failures: Array[String]=[]
var _capture: AudioEffectCapture
func check(value: bool, message: String) -> void:
 if not value: failures.append(message); push_error(message)
func _ready() -> void: call_deferred("run")
func settle(seconds := 0.8) -> void:
 await get_tree().create_timer(seconds,true).timeout
func run() -> void:
 Game.save_path="res://qa/audio-test-save.cfg"
 if "--reload" in OS.get_cmdline_user_args():
  Game._load_save()
  check(is_equal_approx(Game.audio_volumes.Master,0.42) and is_equal_approx(Game.audio_volumes.Music,0.31) and is_equal_approx(Game.audio_volumes.UI,0.27) and is_equal_approx(Game.audio_volumes.SFX,0.63),"Volumes restored in a fresh process")
  check(not Game.audio_enabled and AudioServer.is_bus_mute(0),"Mute restored in a fresh process")
  finish(); return
 Game.audio_enabled=true;Game.apply_audio()
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/manifest.json"))
 for asset: Dictionary in manifest.assets:
  check(ResourceLoader.exists(asset.path),"Imported resource: "+asset.path)
  var stream: AudioStream=load(asset.path)
  check(stream and stream.get_length()>0,"Audio contains samples: "+asset.path)
  if stream is AudioStreamOggVorbis: check(stream.loop==asset.loop,"Music loop flag: "+asset.path)
  if stream is AudioStreamWAV: check((stream.loop_mode!=AudioStreamWAV.LOOP_DISABLED)==asset.loop,"Effect loop flag: "+asset.path)
 for bus in ["Master","Music","UI","SFX"]: check(AudioServer.get_bus_index(bus)>=0,"Bus exists: "+bus)
 _capture=AudioEffectCapture.new()
 AudioServer.add_bus_effect(0,_capture)
 SoundEffects.enter_screen("hangar")
 await settle()
 check(SoundEffects.music_key=="hangar","Hangar music started")
 var samples:=_capture.get_buffer(_capture.get_frames_available())
 var audible:=false
 for sample in samples:
  if sample.length_squared()>0.0000001: audible=true;break
 check(audible,"Audio signal reaches Master bus")
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 _capture=null
 var player: AudioStreamPlayer=SoundEffects._music_players[SoundEffects._music_index]
 var position:=player.get_playback_position()
 SoundEffects.music("hangar")
 await settle(0.2)
 check(SoundEffects._music_players[SoundEffects._music_index]==player and player.get_playback_position()>=position,"Same music continues without restarting")
 SoundEffects.music("menu");SoundEffects.music("campaign");SoundEffects.music("hangar")
 await settle()
 check(SoundEffects.music_key=="hangar","Rapid navigation keeps latest requested music")
 var count:=0
 for voice in SoundEffects._music_players:
  if voice.playing: count+=1
 check(count==1,"Crossfade releases outgoing music")
 # Exercise an actual decoder wrap without waiting through a full soundtrack.
 player.seek(player.stream.get_length()-0.12)
 await settle(0.3)
 check(player.playing and player.get_playback_position()<1.0,"Music loops across its endpoint")
 Game.selected_map_id="cyber";Game.completed_levels={};Game.selected_weapon_id="plasma"
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 scene.enemy_spawner.set_physics_process(false);scene.pickup_spawner.set_physics_process(false)
 scene.player.set_physics_process(false)
 await settle()
 check(SoundEffects.music_key=="gameplay" and SoundEffects._engine.playing,"Mission music and engine")
 for weapon: String in Game.WEAPONS:
  SoundEffects._cooldowns.clear()
  Game.selected_weapon_id=weapon;scene.player._shoot()
  check(SoundEffects.played_events.has(weapon),"Weapon event: "+weapon)
  await settle(0.2)
 var enemy: Enemy=load("res://scenes/enemy.tscn").instantiate()
 enemy.role="gunner";scene.add_child(enemy);enemy.set_physics_process(false)
 enemy._fire_volley();check(SoundEffects.played_events.has("enemy_shoot"),"Enemy volley event")
 SoundEffects._cooldowns.clear();enemy.kill()
 check(SoundEffects.played_events.has("explosion"),"Enemy destruction event")
 for i in 1000:SoundEffects.play("impact")
 check(SoundEffects._players.size()==8 and SoundEffects.get_child_count()==17,"Player allocation remains bounded")
 get_tree().paused=true
 await settle(0.1)
 check(SoundEffects._engine.stream_paused,"Pause suspends engine")
 SoundEffects._cooldowns.clear();SoundEffects.play("click")
 check(SoundEffects.played_events.has("click"),"UI responds while paused")
 SoundEffects._background=true
 await settle(0.1)
 check(SoundEffects._music_players[SoundEffects._music_index].stream_paused,"Background suspends music even inside pause menu")
 SoundEffects._background=false;get_tree().paused=false
 await settle(0.1)
 check(not SoundEffects._engine.stream_paused,"Resume restores engine")
 Game.boss_health=20;Game.boss_defeated=false;Game.boss_status_changed.emit()
 await settle()
 check(SoundEffects.music_key=="boss","Guardian encounter music")
 Game.boss_health=0;Game.boss_defeated=true;Game.boss_status_changed.emit()
 await settle()
 check(SoundEffects.music_key=="gameplay","Guardian defeat returns to combat music")
 for rating in [1,2,3]:
  Game.last_attempt_stars=rating
  if rating==3: Game.completed_levels["cyber"]=3
  SoundEffects._cooldowns.clear();SoundEffects.played_events.erase("star")
  Game.is_running=false;Game.mission_completed.emit()
  await settle(1.6)
  check(SoundEffects.played_events.get("star",0)==rating,"Result star cadence: "+str(rating))
  check(not SoundEffects._engine.playing,"Results stop engine")
  if rating==3: check(SoundEffects.played_events.has("unlock"),"Newly unlocked planet cue")
 Game.game_over.emit()
 check(SoundEffects._sting.stream==SoundEffects._streams.defeat,"Failure jingle")
 Game.is_running=false
 var dialog:=ArcadeUI.settings(scene)
 await settle(0.1);dialog._show_category("AUDIO")
 for i in 4:await get_tree().process_frame
 var values:={"Master":42,"Music":31,"UI":27,"SFX":63}
 for bus: String in values:
  var slider:=dialog.panel.find_child(bus+"Volume",true,false) as HSlider
  check(slider!=null,"Settings slider: "+bus)
  slider.value=values[bus]
  check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)),linear_to_db(values[bus]/100.0)),"Immediate bus volume: "+bus)
  check(dialog.panel.get_global_rect().encloses(slider.get_global_rect()),"Slider fits settings panel: "+bus)
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
  for locale in ["en","id"]:
   I18n.set_language(locale,false)
   await settle(0.3)
   RenderingServer.force_draw()
   get_viewport().get_texture().get_image().save_png("res://qa/audio_settings_"+locale+".png")
 await settle(0.4)
 var cfg:=ConfigFile.new();cfg.load(Game.save_path)
 check(is_equal_approx(cfg.get_value("audio","Master",0),0.42),"Debounced slider save")
 Game.audio_enabled=false;Game.save_settings()
 dialog.close();scene.free()
 finish()
func finish() -> void:
 SoundEffects.stop_all()
 await settle(0.2)
 print("AUDIO SYSTEM: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
