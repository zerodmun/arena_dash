extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("review")
func review() -> void:
 Game.save_path="res://qa/splash-qa/test-save.cfg"
 var loading: ArenaLoadingScreen=load("res://scenes/loading.tscn").instantiate()
 loading.auto_transition=false
 get_tree().root.add_child(loading)
 var last:=0.0
 var frames:=0
 while not loading.ready_to_enter and not loading.failed and frames<600:
  await get_tree().process_frame
  check(loading.fraction>=last and loading.fraction<=1,"Measured progress stays monotonic and bounded")
  last=loading.fraction;frames+=1
 check(loading.ready_to_enter and loading.loaded.has(loading.MENU),"Actual threaded menu load completes")
 check(loading.loaded.size()==loading.jobs.size(),"Every startup job retrieved before ready")
 for dimensions in [Vector2i(1280,720),Vector2i(1440,720),Vector2i(1560,720),Vector2i(1600,720)]:
  get_tree().root.size=dimensions
  await get_tree().process_frame
  var vp:=get_viewport().get_visible_rect()
  var safe:=vp.grow(-32)
  loading._layout(safe)
  await get_tree().process_frame
  check(loading._background.get_global_rect().encloses(vp),"Background covers every viewport edge")
  check(loading._background.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED,"Artwork preserves aspect ratio")
  for c in [loading._logo,loading._title,loading._subtitle,loading._progress,loading._status,loading._retry,loading._ship]:
   check(safe.encloses(c.get_global_rect()),"Foreground respects simulated cutouts: "+c.get_class())
  Game.reduced_motion=true
  var pos:=loading._logo.position
  loading._process(.25)
  check(loading._logo.position==pos,"Reduced motion removes floating")
  Game.reduced_motion=false
 loading.free()
 var broken: ArenaLoadingScreen=load("res://scenes/loading.tscn").instantiate()
 broken.auto_transition=false;broken.jobs.assign(["res://missing-startup-resource.tscn"])
 get_tree().root.add_child(broken)
 for i in 4:await get_tree().process_frame
 check(broken.failed and broken._retry.visible and not broken._progress.visible,"Missing asset exposes retry without fake progress")
 broken.jobs.assign(["res://scenes/menu.tscn"]);broken._restart()
 frames=0
 while not broken.ready_to_enter and not broken.failed and frames<300:
  await get_tree().process_frame;frames+=1
 check(broken.ready_to_enter,"Retry recovers after resources become available")
 broken.free()
 print("LOADING SCREEN: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 SoundEffects.stop_all()
 await get_tree().create_timer(.2).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
