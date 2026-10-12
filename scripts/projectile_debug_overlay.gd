class_name ProjectileDebugOverlay
extends Node2D
## Temporary QA markers; never instantiated by normal builds.
func _ready() -> void:
 z_index=20
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
 var tick:=Engine.get_physics_frames()
 for marker in ProjectileTrace.markers:
  if tick-marker.tick>24:continue
  var col:=Color("69ffff") if marker.event=="spawn" else Color("ffbd69")
  var p:=Vector2(marker.position[0],marker.position[1])
  draw_circle(p,4,col,false,1.5)
  draw_line(p-Vector2(7,0),p+Vector2(7,0),col,1)
  draw_line(p-Vector2(0,7),p+Vector2(0,7),col,1)
