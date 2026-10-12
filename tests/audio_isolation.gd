extends Node
var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
 if not condition:
  failures.append(message)
  push_error(message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 Game.save_path = "res://qa/audio-isolation-save.cfg"
 Game.audio_enabled = true
 SoundEffects.stop_all()
 SoundEffects._cooldowns.clear()
 SoundEffects.music("gameplay")
 SoundEffects.play("click")
 SoundEffects.play("ion")
 SoundEffects.play_hit()
 SoundEffects._mission_start()
 SoundEffects._jingle("victory")
 await get_tree().create_timer(1.0).timeout
 var stage: String = SoundEffects.diagnostic_stage
 check(SoundEffects._allows("sfx") == (stage in ["full","sfx"]),"SFX gate")
 check(SoundEffects._allows("music") == (stage in ["full","music"]),"Music gate")
 check(SoundEffects._allows("ui") == (stage in ["full","ui"]),"UI gate")
 check(SoundEffects._engine.playing == SoundEffects._allows("sfx"),"Engine obeys diagnostic isolation")
 check((SoundEffects.music_key == "gameplay") == SoundEffects._allows("music"),"Music obeys diagnostic isolation")
 check(SoundEffects.played_events.has("click") == SoundEffects._allows("ui"),"UI event obeys isolation")
 check(SoundEffects.played_events.has("ion") == SoundEffects._allows("sfx"),"Weapon event obeys isolation")
 check(SoundEffects._sting.playing == SoundEffects._allows("music"),"Results obey music isolation")
 SoundEffects.stop_all()
 print("AUDIO ISOLATION: ",stage," ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
