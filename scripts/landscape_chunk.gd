class_name LandscapeChunk
extends Node2D
## Each chunk holds cached draw commands. Rivers use world coordinates at edges.
const SIZE := Vector2(1700, 1100)
var biome := "cyber"
var coordinate := Vector2i.ZERO
func _draw() -> void:
 var info: Dictionary = Game.MAPS[biome]
 var rng := RandomNumberGenerator.new()
 rng.seed = 91827 + coordinate.x * 7919 + coordinate.y * 104729 + Campaign.index(biome) * 31
 var base: Color = info.floor_color
 draw_rect(Rect2(Vector2.ZERO, SIZE), base)
 if biome in ["coast", "volcano", "glacier", "toxic"]:
  for river in 8:
   var path := PackedVector2Array()
   var world_y := river * 650.0 + 230
   for x in range(0, 1721, 20):
    var world_x := position.x + x
    var y := world_y + sin(world_x * 0.002 + river) * 130 + cos(world_x * 0.006) * 30 - position.y
    path.append(Vector2(x, y))
   var tint := Color("35b6bf")
   if biome == "volcano": tint = Color("ef6a1a")
   elif biome == "glacier": tint = Color("8adfe8")
   elif biome == "toxic": tint = Color("83ca21")
   draw_polyline(path, Color(tint, 0.14), 115, true)
   draw_polyline(path, Color(tint, 0.24), 70, true)
   draw_polyline(path, Color(tint, 0.65), 28, true)
 if biome == "cyber":
  for x in range(0, 1701, 100): draw_line(Vector2(x, 0), Vector2(x, 1100), Color(info.color, 0.13), 1)
  for y in range(0, 1101, 100): draw_line(Vector2(0, y), Vector2(1700, y), Color(info.color, 0.13), 1)
 for i in 90:
  var pos := Vector2(rng.randf_range(20, 1680), rng.randf_range(20, 1080))
  var radius := rng.randf_range(16, 100)
  match biome:
   "forest":
    draw_circle(pos, radius, Color("123922"))
    draw_circle(pos - Vector2(8, 12), radius * 0.7, Color("1c5130"))
    draw_arc(pos, radius * 0.7, 0.3, 2.4, 14, Color("33885a"), 2, true)
   "desert":
    var dune := PackedVector2Array()
    for step in 20: dune.append(pos + Vector2(step * 12, sin(step / 19.0 * PI) * -35))
    draw_polyline(dune, Color("b89562"), 6, true)
    draw_polyline(dune, Color("e0be87", 0.4), 2, true)
   "space":
    draw_circle(pos, rng.randf_range(1, 3), Color("c3ddff", rng.randf_range(0.3, 0.9)))
   "volcano":
    draw_circle(pos, radius, Color("271d1a"))
    draw_arc(pos, radius, 0, 2.5, 12, Color("4a3124"), 2, true)
   "coast":
    if i % 4 == 0:
     draw_circle(pos, radius, Color("256575"))
     draw_circle(pos, radius * 0.7, Color("b7a67c"))
     draw_circle(pos - Vector2(5, 8), radius * 0.45, Color("d5c799"))
   "glacier":
    draw_line(pos, pos + Vector2(radius, -radius * 0.4), Color("559cbe", 0.5), 5, true)
   "toxic":
    draw_rect(Rect2(pos, Vector2(radius, radius * 0.6)), Color("233629"), false, 2)
   "cyber":
    draw_circle(pos, 4, Color(info.color, 0.65))
    draw_line(pos, pos + Vector2(radius, 0), Color(info.color, 0.25), 2)
