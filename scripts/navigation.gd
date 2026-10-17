extends Node
## One Back dispatcher for OS notifications and input; history contains paths, never nodes.
const HOME := "res://scenes/menu.tscn"
const PLAY := "res://scenes/main.tscn"
const LOADING := "res://scenes/loading.tscn"
const EXIT_WINDOW_MS := 2000
var history: Array[String] = []
var _current := ""
var _transitioning := false
var _last_back_ms := -1000
var _exit_deadline := 0
var _toast: CanvasLayer

func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 get_tree().quit_on_go_back=false

func _process(_delta: float) -> void:
 _sync_scene()
 if _exit_deadline > 0 and Time.get_ticks_msec() >= _exit_deadline:
  _reset_exit()

func _sync_scene() -> void:
 var scene:=get_tree().current_scene
 if not is_instance_valid(scene):return
 var path:=scene.scene_file_path
 if path==_current:return
 _record(path)

func _record(path: String) -> void:
 if path==HOME:
  history.clear()
 elif path in history:
  history.resize(history.find(path))
 elif _current not in ["",LOADING,PLAY] and _current!=path:
  history.append(_current)
 _current=path
 _reset_exit()

func go_to(path: String) -> void:
 if _transitioning:return
 _sync_scene()
 if path==_current:return
 var error:=get_tree().change_scene_to_file(path)
 if error!=OK:
  push_error("Navigation failed: "+path)
  return
 _transitioning=true
 _record(path)
 _finish_transition()

func _finish_transition() -> void:
 await get_tree().scene_changed
 _transitioning=false

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:request_back()
 elif what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:_reset_exit()

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_BACK]):
  get_viewport().set_input_as_handled()
  if not event.is_echo():request_back()

func request_back() -> void:
 var now:=Time.get_ticks_msec()
 # Coalesce OS/key duplicates and rapid repeats, including while paused.
 if _transitioning or now-_last_back_ms<250:return
 _last_back_ms=now
 _sync_scene()
 var scene:=get_tree().current_scene
 if not is_instance_valid(scene):return
 if _close_top(get_tree().root):
  _reset_exit()
  return
 if _current==LOADING:return
 if _current==HOME:
  if _exit_deadline>now:
   Game.flush_save()
   get_tree().quit()
  else:
   _exit_deadline=now+EXIT_WINDOW_MS
   _show_exit_notice()
  return
 SoundEffects.play("back")
 go_to(history.back() if not history.is_empty() else HOME)

func _close_top(node: Node) -> bool:
 # Children last-added are topmost; deeper editors/dialogs take priority.
 var children:=node.get_children()
 children.reverse()
 for child in children:
  if not child.is_queued_for_deletion() and _close_top(child):return true
 if node.has_method("navigation_back") and not node.is_queued_for_deletion():
  return node.navigation_back()
 return false

func _reset_exit() -> void:
 _exit_deadline=0
 if is_instance_valid(_toast):_toast.queue_free()
 _toast=null

func _show_exit_notice() -> void:
 if is_instance_valid(_toast):_toast.queue_free()
 _toast=CanvasLayer.new()
 _toast.layer=200
 add_child(_toast)
 var center:=CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 center.anchor_top=0.78
 center.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _toast.add_child(center)
 var panel:=PanelContainer.new()
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",ArcadeUI.panel(16))
 center.add_child(panel)
 var label:=ArcadeUI.label("Swipe back again to exit",20,ArcadeUI.CYAN)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_child(label)
