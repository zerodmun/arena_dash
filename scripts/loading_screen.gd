class_name ArenaLoadingScreen
extends Control
## Full-bleed presentation; percentages describe only the resource queue.
## Unknown-duration scene initialization is labelled without a percentage.
signal resources_ready
signal loading_failed(path: String)
@export var auto_transition := true
const MENU := "res://scenes/menu.tscn"
var jobs: Array[String] = []
var loaded: Dictionary = {}
var completed := 0
var fraction := 0.0
var failed := false
var ready_to_enter := false
var _active := ""
var _clock := 0.0
var _transitioning := false
var _started_ms := 0
var _background: TextureRect
var _logo: TextureRect
var _ship: TextureRect
var _title: Label
var _subtitle: Label
var _status: Label
var _progress: ProgressBar
var _retry: Button
var _logo_origin := Vector2.ZERO
var _ship_origin := Vector2.ZERO
var _stars: Control

func _ready() -> void:
 _started_ms=Time.get_ticks_msec()
 if OS.get_name()=="Android":DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
 _background=ArcadeUI.image("res://assets/ui/theme/space_landscape.svg",Vector2.ZERO)
 _background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 add_child(_background)
 _stars=Control.new()
 _stars.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _stars.draw.connect(_draw_stars)
 add_child(_stars)
 _logo=ArcadeUI.image("res://icon.svg",Vector2.ZERO)
 add_child(_logo)
 _ship=ArcadeUI.image("res://assets/player.svg",Vector2.ZERO)
 _ship.modulate=Color(0.7,0.85,1,0.45)
 add_child(_ship)
 _title=ArcadeUI.label("ARENA DASH",52,ArcadeUI.TEXT)
 _subtitle=ArcadeUI.label("FLIGHT COMMAND  /  CAMPAIGN OPERATIONS",18,ArcadeUI.CYAN)
 _status=ArcadeUI.label("Preparing flight systems…",20,ArcadeUI.MUTED)
 for label in [_title,_subtitle,_status]:
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  add_child(label)
 _progress=ProgressBar.new()
 _progress.show_percentage=false
 _progress.min_value=0;_progress.max_value=1
 var track:=StyleBoxFlat.new()
 track.bg_color=Color("14283f");track.set_corner_radius_all(10)
 track.border_color=Color("466478");track.set_border_width_all(1)
 var fill:=StyleBoxFlat.new()
 fill.bg_color=Color("88becf");fill.set_corner_radius_all(10)
 _progress.add_theme_stylebox_override("background",track)
 _progress.add_theme_stylebox_override("fill",fill)
 add_child(_progress)
 _retry=ArcadeUI.button("RETRY LOADING","",true)
 _retry.pressed.connect(_restart)
 _retry.visible=false
 add_child(_retry)
 get_viewport().size_changed.connect(_layout)
 _layout()
 if not Game.reduced_motion:
  _logo.modulate.a=0.35;_title.modulate.a=0.35
  var intro:=create_tween().set_parallel(true)
  intro.tween_property(_logo,"modulate:a",1.0,0.25)
  intro.tween_property(_title,"modulate:a",1.0,0.25)
 if jobs.is_empty():
  jobs.assign([MENU,"res://scenes/hangar.tscn","res://scenes/level_select.tscn","res://scenes/main.tscn",Game.get_current_ship().texture,Game.get_current_weapon().texture,Game.get_current_map().icon,"res://assets/future_updates/aircraft/player_booster.svg"])
  for file in ResourceLoader.list_directory("res://assets/ui/theme/buttons"):
   if file.ends_with(".svg"):jobs.append("res://assets/ui/theme/buttons/"+file)
 var distinct: Array[String]=[]
 for path: String in jobs:
  if not distinct.has(path):distinct.append(path)
 jobs=distinct
 # Present a first frame before resource requests; never impose a timed hold.
 _begin_loading.call_deferred()
 print("STARTUP: loading visible jobs=",jobs.size())

func _begin_loading() -> void:
 await get_tree().process_frame
 _request_next()

func _request_next() -> void:
 if failed or ready_to_enter:return
 if completed>=jobs.size():
  ready_to_enter=true
  fraction=1.0;_progress.value=1
  _status.text=I18n.t("Preparing navigation…")
  print("STARTUP: resources ready elapsed_ms=",Time.get_ticks_msec()-_started_ms)
  resources_ready.emit()
  if auto_transition:_enter_menu.call_deferred()
  return
 _active=jobs[completed]
 if not ResourceLoader.exists(_active):_fail(_active);return
 var result:=ResourceLoader.load_threaded_request(_active,"",false,ResourceLoader.CACHE_MODE_REUSE)
 if result!=OK:_fail(_active)

func _process(delta: float) -> void:
 _clock+=delta
 if not Game.reduced_motion:
  _background.position=Vector2(-24+sin(_clock*0.12)*8,-24+cos(_clock*0.1)*6)
  _logo.position=_logo_origin+Vector2(0,sin(_clock*1.1)*4)
  _ship.position=_ship_origin+Vector2(sin(_clock*.4)*5,sin(_clock*.8)*8)
  _stars.queue_redraw()
 if failed or ready_to_enter or _active.is_empty():return
 var measured: Array=[]
 var state:=ResourceLoader.load_threaded_get_status(_active,measured)
 if state==ResourceLoader.THREAD_LOAD_FAILED:
  ResourceLoader.load_threaded_get(_active) # Retire the failed request so Retry can reload.
  _fail(_active);return
 if state==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:_fail(_active);return
 var current:=float(measured[0]) if not measured.is_empty() else 0.0
 fraction=clampf((completed+current)/maxi(1,jobs.size()),fraction,1.0)
 _progress.value=fraction
 _status.text=I18n.t("Loading flight assets • %d%%",[int(fraction*100)])
 if state==ResourceLoader.THREAD_LOAD_LOADED:
  # Only get after LOADED: this never waits for an unfinished resource thread.
  var resource:=ResourceLoader.load_threaded_get(_active)
  if resource==null:_fail(_active);return
  loaded[_active]=resource
  completed+=1;_active=""
  _request_next()

func _enter_menu() -> void:
 if _transitioning or not ready_to_enter or failed:return
 _transitioning=true
 var packed:=loaded.get(MENU) as PackedScene
 if packed==null:_transitioning=false;_fail(MENU);return
 Game.startup_resources=loaded.duplicate()
 var menu:=packed.instantiate() as Control
 if menu==null:_transitioning=false;_fail(MENU);return
 menu.process_mode=Node.PROCESS_MODE_DISABLED
 menu.modulate.a=0
 get_tree().root.add_child(menu)
 get_tree().root.move_child(self,-1)
 # Cross-fade over the already-rendered menu; no black intermediate frame.
 var transition:=create_tween().set_parallel(true)
 var duration:=0.12 if Game.reduced_motion else 0.22
 transition.tween_property(menu,"modulate:a",1.0,duration)
 transition.tween_property(self,"modulate:a",0.0,duration)
 await transition.finished
 menu.process_mode=Node.PROCESS_MODE_INHERIT
 get_tree().current_scene=menu
 print("STARTUP: menu ready elapsed_ms=",Time.get_ticks_msec()-_started_ms)
 queue_free()

func _fail(path: String) -> void:
 failed=true;_active=""
 _status.text=I18n.t("Unable to load flight systems. Please retry.")
 _progress.visible=false;_retry.visible=true
 print("STARTUP: load failed path=",path)
 loading_failed.emit(path)

func _restart() -> void:
 failed=false;ready_to_enter=false;completed=0;fraction=0
 _retry.visible=false;_progress.visible=true;_progress.value=0
 _request_next()

func _layout(available := Rect2()) -> void:
 var vp:=get_viewport_rect().size
 var safe:=available if available.has_area() else ArcadeUI.safe_rect(vp)
 _background.position=Vector2(-24,-24);_background.size=vp+Vector2(48,48)
 _stars.size=vp
 var center:=safe.get_center().x
 var logo_side:=minf(230,safe.size.y*.32)
 _logo.size=Vector2.ONE*logo_side
 _logo_origin=Vector2(center-logo_side*.5,safe.position.y+safe.size.y*.13)
 _logo.position=_logo_origin
 _title.position=Vector2(safe.position.x+24,safe.position.y+safe.size.y*.49)
 _title.size=Vector2(safe.size.x-48,66)
 _subtitle.position=Vector2(safe.position.x+24,safe.position.y+safe.size.y*.59)
 _subtitle.size=Vector2(safe.size.x-48,32)
 _ship.size=Vector2(110,150)
 _ship_origin=Vector2(center+safe.size.x*.25,safe.position.y+safe.size.y*.28)
 _ship.position=_ship_origin
 var width:=minf(520,safe.size.x-96)
 _progress.position=Vector2(center-width*.5,safe.end.y-104)
 _progress.size=Vector2(width,18)
 _status.position=Vector2(safe.position.x+24,safe.end.y-74)
 _status.size=Vector2(safe.size.x-48,40)
 _retry.position=Vector2(center-180,safe.end.y-156)
 _retry.custom_minimum_size=Vector2(360,64)
 _retry.size=Vector2(360,64)

func _draw_stars() -> void:
 for i in 24:
  var p:=Vector2(fposmod(i*137.3+_clock*(2+i%3),_stars.size.x),fposmod(i*83.7,_stars.size.y))
  _stars.draw_circle(p,0.8+(i%3)*.3,Color(0.55,0.74,0.9,.12+.12*(sin(_clock+i)*.5+.5)))
