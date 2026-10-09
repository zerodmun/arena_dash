class_name LayoutHandle
extends TextureRect
signal dragged(id: String,center: Vector2)
signal selected(id: String)
var control_id := "fire"
var _finger := -1
var _mouse := false
var _offset := Vector2.ZERO
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  _mouse=event.pressed
  if _mouse: _offset=event.position-size*0.5; selected.emit(control_id)
  accept_event()
 elif event is InputEventMouseMotion and _mouse:
  dragged.emit(control_id,get_global_transform()*(event.position-_offset))
  accept_event()
 elif event is InputEventScreenTouch:
  if event.pressed and _finger==-1:
   _finger=event.index
   _offset=event.position-size*0.5
   selected.emit(control_id)
  elif event.index==_finger: _finger=-1
  accept_event()
 elif event is InputEventScreenDrag and event.index==_finger:
  dragged.emit(control_id,get_global_transform()*(event.position-_offset))
  accept_event()
func stop_drag() -> void:
 _finger=-1
 _mouse=false

func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch and not event.pressed and event.index==_finger: stop_drag()
 elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _mouse: stop_drag()
