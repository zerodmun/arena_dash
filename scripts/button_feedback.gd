extends Node
## Short input-driven transitions. No layout, hit-target, or per-frame idle work.
var _button: Button
var _tween: Tween
var _held := false
var _hovered := false
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 _button=get_parent() as Button
 _button.button_down.connect(func() -> void: _held=true;_animate())
 _button.button_up.connect(func() -> void: _held=false;_animate())
 _button.mouse_entered.connect(func() -> void: _hovered=true;_animate())
 _button.mouse_exited.connect(func() -> void: _hovered=false;_animate())
 _button.focus_entered.connect(_animate)
 _button.focus_exited.connect(_animate)
 _button.visibility_changed.connect(_reset)
 _button.theme_changed.connect(_style_changed)
 Game.preferences_changed.connect(_animate)
func _style_changed() -> void:
 if _button.disabled: _reset()
func _reset() -> void:
 _held=false
 _hovered=false
 if _tween: _tween.kill()
 _button.self_modulate=Color.WHITE
func _animate() -> void:
 if _tween: _tween.kill()
 if Game.reduced_motion or _button.disabled or not _button.is_visible_in_tree():
  _button.self_modulate=Color.WHITE
  return
 var light:=.94 if _held else 1.035 if _hovered or _button.has_focus() else 1.0
 _tween=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 _tween.tween_property(_button,"self_modulate",Color(light,light,light,1),.07 if _held else .16)
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and is_instance_valid(_button): _reset()
