class_name GameJoystick
extends Control
## Saved touch/mouse joystick with independent finger ownership.

@export var max_radius := 105.0

@onready var base: Node2D = $Base
@onready var knob: Node2D = $Knob

var pressed := false
var output := Vector2.ZERO

var _touch_index := -1
var _default_pos := Vector2(220, 880)


func _ready() -> void:
    add_to_group("joystick")
    get_viewport().size_changed.connect(_update_default_pos)
    _update_default_pos()
    _reset()


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        _reset()


func _update_default_pos() -> void:
    var vp := get_viewport_rect().size
    apply_layout(TouchLayout.resolved(Game.control_layout,vp).joystick)
    if not pressed and base and knob:
        base.global_position = _default_pos
        knob.global_position = _default_pos


func _gui_input(event: InputEvent) -> void:
    if get_tree().paused or not Game.is_running: return
    var pos: Vector2
    if event is InputEventScreenTouch:
        pos = _to_canvas(event.position)
        if event.pressed and _touch_index == -1:
            _touch_index = event.index
            modulate.a = Game.control_layout.joystick.opacity
            _update_knob(pos)
        elif not event.pressed and event.index == _touch_index:
            _reset()
    elif event is InputEventScreenDrag:
        if event.index == _touch_index:
            pos = _to_canvas(event.position)
            _update_knob(pos)
    elif event is InputEventMouseButton:
        pos = _to_canvas(event.position)
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _touch_index == -1:
            _touch_index = -2
            modulate.a = Game.control_layout.joystick.opacity
            _update_knob(pos)
        elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _touch_index == -2:
            _reset()
    elif event is InputEventMouseMotion and _touch_index == -2:
        pos = _to_canvas(event.position)
        _update_knob(pos)


func _to_canvas(local_pos: Vector2) -> Vector2:
    return get_global_transform_with_canvas() * local_pos


func _update_knob(world_pos: Vector2) -> void:
    PerfDiagnostics.mark_input()
    var delta := world_pos - base.global_position
    if delta.length() > max_radius:
        delta = delta.normalized() * max_radius
    knob.global_position = base.global_position + delta
    output = delta / max_radius
    pressed = true


func _reset() -> void:
    _touch_index = -1
    pressed = false
    output = Vector2.ZERO
    modulate.a = Game.control_layout.joystick.opacity
    if base and knob:
        base.global_position = _default_pos
        knob.global_position = _default_pos

func apply_layout(data: Dictionary) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    size=Vector2.ONE*data.diameter
    position=data.center-size*0.5
    _default_pos=data.center
    max_radius=data.diameter*0.36
    if is_instance_valid(base):
        $Base/BaseVisual.scale=Vector2.ONE*data.diameter/$Base/BaseVisual.texture.get_width()
        $Knob/KnobVisual.scale=Vector2.ONE*data.diameter*0.4/$Knob/KnobVisual.texture.get_width()
        _reset()
func _has_point(point: Vector2) -> bool:
    return point.distance_to(size*0.5)<=size.x*0.5

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not event.pressed and event.index==_touch_index: _reset()
    elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _touch_index==-2: _reset()
