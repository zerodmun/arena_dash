class_name GameJoystick
extends Control
## One movement finger; saved fixed base or a floating base confined to the left half.
@export var max_radius := 105.0
@onready var base: Node2D = $Base
@onready var knob: Node2D = $Knob
var pressed := false
var output := Vector2.ZERO
var fixed_control := true
var _touch_index := -1
var _default_pos := Vector2(220,880)
var _allowed := Rect2()
func _ready() -> void:
 add_to_group("joystick")
 get_viewport().size_changed.connect(_update_default_pos)
 _update_default_pos()
 _reset()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: _reset()
func _update_default_pos() -> void:
 apply_layout(TouchLayout.resolved(Game.control_layout,get_viewport_rect().size).joystick)
func _can_interact() -> bool:
 return is_visible_in_tree() and Game.is_running and not get_tree().paused
func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  if not event.pressed and event.index==_touch_index: _reset();return
  if event.pressed and _touch_index==-1 and _can_interact(): _begin(event.index,_canvas_point(event.position))
 elif event is InputEventScreenDrag and event.index==_touch_index and _can_interact():
  _update_knob(_canvas_point(event.position))
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if not event.pressed and _touch_index==-2: _reset();return
  if event.pressed and _touch_index==-1 and _can_interact(): _begin(-2,_canvas_point(event.position))
 elif event is InputEventMouseMotion and _touch_index==-2 and _can_interact():
  _update_knob(_canvas_point(event.position))
  get_viewport().set_input_as_handled()
func _canvas_point(point: Vector2) -> Vector2:
 return get_canvas_transform().affine_inverse()*point
func _begin(index: int,point: Vector2) -> void:
 if not _allowed.has_point(point): return
 if fixed_control and point.distance_to(_default_pos)>size.x*.5: return
 _touch_index=index
 if not fixed_control: base.global_position=_clamp_base(point)
 _update_knob(point)
 get_viewport().set_input_as_handled()
func _clamp_base(point: Vector2) -> Vector2:
 var radius:=TouchLayout.footprint_radius("joystick",size.x)
 return point.clamp(_allowed.position+Vector2.ONE*radius,_allowed.end-Vector2.ONE*radius)
func _update_knob(world_pos: Vector2) -> void:
 PerfDiagnostics.mark_input()
 var delta:=world_pos-base.global_position
 if not fixed_control and delta.length()>max_radius:
  base.global_position=_clamp_base(world_pos-delta.normalized()*max_radius)
  delta=world_pos-base.global_position
 delta=delta.limit_length(max_radius)
 knob.global_position=base.global_position+delta
 output=delta/max_radius
 pressed=true
func _reset() -> void:
 _touch_index=-1
 pressed=false
 output=Vector2.ZERO
 modulate=Color(.8,.86,.9,Game.control_layout.joystick.opacity)
 if is_instance_valid(base) and is_instance_valid(knob):
  base.global_position=_default_pos
  knob.global_position=_default_pos
func apply_layout(data: Dictionary) -> void:
 set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 size=Vector2.ONE*data.diameter
 position=data.center-size*.5
 _default_pos=data.center
 _allowed=TouchLayout.allowed_area("joystick",get_viewport_rect().size)
 fixed_control=bool(data.get("fixed",true))
 max_radius=data.diameter*.36
 if is_instance_valid(base):
  $Base/BaseVisual.scale=Vector2.ONE*data.diameter/$Base/BaseVisual.texture.get_width()
  $Knob/KnobVisual.scale=Vector2.ONE*data.diameter*.4/$Knob/KnobVisual.texture.get_width()
  _reset()
func _has_point(point: Vector2) -> bool:
 return point.distance_to(size*.5)<=size.x*.5
