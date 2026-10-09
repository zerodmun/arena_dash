class_name PlanetAtmosphere
extends Node2D
## Lightweight world-relative foreground particles provide parallax and biome motion.
var camera: Camera2D
var _time := 0.0
var _refresh := 0.0
func _process(delta: float) -> void:
 if not Game.is_running: return
 _time += delta
 _refresh += delta
 if _refresh > 0.05:
  _refresh = 0
  queue_redraw()
func _draw() -> void:
 if not camera: return
 var size := get_viewport_rect().size
 var map: String = Game.selected_map_id
 var tint: Color = Game.get_current_map().color
 var drift := Vector2(15, 8)
 if map == "glacier": drift = Vector2(24, 48); tint = Color("d8f3ff")
 elif map == "volcano": drift = Vector2(12, -40); tint = Color("ffba48")
 elif map == "desert": drift = Vector2(65, 12); tint = Color("ead1a0")
 var offset := camera.global_position * 0.18
 for i in 48:
  var p := Vector2(fposmod(i * 317.7 + _time * drift.x - offset.x, size.x), fposmod(i * 191.3 + _time * drift.y - offset.y, size.y)) - size * 0.5
  if map in ["coast", "desert"]:
   draw_line(p, p + Vector2(24, 4), Color(tint, 0.10), 1, true)
  else:
   draw_circle(p, 1.2 + i % 3 * 0.4, Color(tint, 0.20))
