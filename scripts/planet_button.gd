class_name PlanetButton
extends Button
## Actual circular hit target and artwork, shared by campaign and hangar.
var planet_id := "cyber"
var planet_texture: Texture2D
var selected := false:
 set(value):
  if selected == value: return
  selected=value
  queue_redraw()
var _glow := 0.0
var _pulse := 0.0
func _ready() -> void:
 for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
  add_theme_stylebox_override(state, StyleBoxEmpty.new())
 text = ""
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 mouse_entered.connect(func() -> void: _glow = 1.0; queue_redraw())
 mouse_exited.connect(func() -> void: _glow = 0.0; queue_redraw())
 button_down.connect(func() -> void: set_process(true))
 button_up.connect(func() -> void: set_process(true))
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)
 configure(planet_id)
 I18n.changed.connect(func() -> void: configure(planet_id))
 set_process(false)
func configure(id: String) -> void:
 planet_id = id
 planet_texture = load(Campaign.planet(id))
 tooltip_text = Game.MAPS[id].name + I18n.t(" / Planet campaign")
 queue_redraw()
func _has_point(point: Vector2) -> bool:
 return point.distance_to(size * 0.5) <= minf(size.x, size.y) * 0.5
func _process(delta: float) -> void:
 var target:=1.0 if is_pressed() and not disabled else 0.0
 _pulse = target if Game.reduced_motion else move_toward(_pulse,target,delta*8)
 queue_redraw()
 if is_equal_approx(_pulse,target): set_process(false)
func _draw() -> void:
 var center := size * 0.5
 var radius := minf(size.x, size.y) * 0.48
 if radius <= 0: return
 var bright := selected or has_focus()
 var tint := ArcadeUI.CYAN if bright else Color("69748b")
 if disabled: tint = Color("5e6c80")
 for i in 6:
  draw_circle(center, radius - i * radius * 0.025, Color(tint, (0.035 + _glow * 0.012) * (0.5 if disabled else 1.0)))
 draw_circle(center + Vector2(0, radius * 0.06), radius * 0.81, Color("0c1728", 0.6))
 draw_arc(center, radius * (0.91 - _pulse * 0.035), 0, TAU, 72, Color(tint, 0.55 + _glow * 0.3), 2.2, true)
 draw_arc(center, radius * 0.98, -2.65, -0.9, 28, Color(ArcadeUI.CYAN,0.45), 2, true)
 if planet_texture:
  var extent := Vector2.ONE * radius * (1.63 - _pulse * 0.05)
  draw_texture_rect(planet_texture, Rect2(center - extent * 0.5, extent), false, Color(0.72, 0.73, 0.87) if disabled else Color(.85,.88,.92))
 if bright:
  draw_arc(center, radius, 0, TAU, 72, ArcadeUI.CYAN, 2.5, true)
