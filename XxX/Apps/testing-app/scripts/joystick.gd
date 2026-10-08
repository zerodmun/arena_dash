class_name GameJoystick
extends Control
## GameJoystick: smooth floating touch/mouse joystick.
## Displays at ergonomic resting position when idle, highlights and follows touch on drag.

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
	_default_pos = Vector2(clampf(vp.x * 0.12, 180.0, 260.0), vp.y - clampf(vp.y * 0.20, 180.0, 240.0))
	if not pressed and base and knob:
		base.global_position = _default_pos
		knob.global_position = _default_pos


func _gui_input(event: InputEvent) -> void:
	var pos: Vector2
	if event is InputEventScreenTouch:
		pos = _to_canvas(event.position)
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			base.global_position = pos
			modulate.a = 1.0
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
			base.global_position = pos
			modulate.a = 1.0
			_update_knob(pos)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _touch_index == -2:
			_reset()
	elif event is InputEventMouseMotion and _touch_index == -2:
		pos = _to_canvas(event.position)
		_update_knob(pos)


func _to_canvas(local_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * local_pos


func _update_knob(world_pos: Vector2) -> void:
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
	modulate.a = 0.65
	if base and knob:
		base.global_position = _default_pos
		knob.global_position = _default_pos
