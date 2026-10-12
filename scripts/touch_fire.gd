class_name TouchFire
extends TextureRect
## Finger ownership is independent from the joystick; preview never uses this script.
signal button_down
signal button_up
var _finger := -1
var _mouse := false
var _feedback: Tween
var disabled := false:
 set(value):
  if disabled==value: return
  disabled=value
  if disabled: reset()
  if is_node_ready(): _visual(_finger!=-1 or _mouse)
func _ready() -> void:
 texture=load("res://assets/ui/theme/buttons/fire_disabled.svg" if disabled else "res://assets/ui/theme/buttons/fire_normal.svg")
 button_down.connect(func() -> void: _visual(true))
 button_up.connect(func() -> void: _visual(false))
func _visual(held: bool) -> void:
 var state:="disabled" if disabled else "pressed" if held else "normal"
 texture=load("res://assets/ui/theme/buttons/fire_"+state+".svg")
 if _feedback: _feedback.kill()
 if Game.reduced_motion:
  self_modulate=Color.WHITE
  return
 _feedback=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 _feedback.tween_property(self,"self_modulate",Color(.94,.94,.94) if held else Color.WHITE,.07 if held else .16)
func _has_point(point: Vector2) -> bool:
 return point.distance_to(size*0.5)<=minf(size.x,size.y)*0.5
func _gui_input(event: InputEvent) -> void:
 if disabled or get_tree().paused or not Game.is_running: return
 if event is InputEventScreenTouch:
  if event.pressed and _finger==-1 and not _mouse:
   _finger=event.index
   PerfDiagnostics.mark_input()
   button_down.emit()
   accept_event()
  elif not event.pressed and event.index==_finger: reset(); accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and _finger==-1:
  if event.pressed and not _mouse: _mouse=true;PerfDiagnostics.mark_input();button_down.emit();accept_event()
  elif not event.pressed and _mouse: reset(); accept_event()
func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch and not event.pressed and event.index==_finger: reset()
 elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _mouse: reset()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: reset()
func reset() -> void:
 var held:=_finger!=-1 or _mouse
 _finger=-1
 _mouse=false
 if held: button_up.emit()
