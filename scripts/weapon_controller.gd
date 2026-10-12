class_name WeaponController
extends RefCounted
## The only player firing clock. Called once by Player after movement/rotation.
var aircraft: Player
var cooldown:=0.25
var sequence:=0
var selected_weapon:=""
func _init(owner_aircraft: Player) -> void:
 aircraft=owner_aircraft
func reset() -> void:
 cooldown=0.25
 selected_weapon=Game.selected_weapon_id
func tick(delta: float, pressed: bool) -> bool:
 if not Game.is_running:return false
 selected_weapon=Game.selected_weapon_id
 cooldown-=delta
 if not pressed:cooldown=maxf(cooldown,0.0)
 if pressed and cooldown<=0:
  var fired:=request_fire()>0
  cooldown=maxf(-delta,cooldown)+aircraft.fire_rate
  return fired
 return false
func request_fire() -> int:
 if not is_instance_valid(aircraft) or not aircraft.is_inside_tree() or not Game.is_running:return 0
 var root:=aircraft.get_tree().current_scene
 if root==null:return 0
 var manager:=root.get_node_or_null("ProjectileManager") as ProjectileManager
 if manager==null:return 0
 # A new sequence exists only for this immediate request, never a timer callback.
 selected_weapon=Game.selected_weapon_id
 sequence+=1
 return manager.fire(self,sequence)
