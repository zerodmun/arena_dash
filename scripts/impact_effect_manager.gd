class_name ImpactEffectManager
extends Node2D
## Single-use receipts and fresh emitters; no delayed pooled particle completion.
var _receipts: Dictionary={}
var created:=0
func impact(projectile_id: int, point: Vector2, color: Color) -> void:
 if _receipts.has(projectile_id) or not point.is_finite():return
 _receipts[projectile_id]=true
 var burst:=ExplosionParticles.new()
 add_child(burst)
 burst.activate(point,color,projectile_id,"projectile_impact")
 created+=1
 SoundEffects.play("impact",-19)
func cleanup() -> void:
 for child in get_children():
  child.visible=false;child.queue_free()
 _receipts.clear()
