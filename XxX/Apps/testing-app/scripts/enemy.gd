class_name Enemy
extends CharacterBody2D
## Readable roles: pursuit, predictive flanks, standoff fire, charges and guardians.
const DIE_SCORE := 10
const BASE_SCALE := 0.25
@export var speed := 115.0
var health := 1
var role := "pursuer"
var is_boss := false
var _player: Node2D
var _dead := false
var _wobble_time := 0.0
var _attack_timer := 3.0
var _warning := 0.0
var _aim := Vector2.DOWN
var _dash := 0.0
var _phase := 0.0
var _orbit_sign := 1.0
var _max_health := 1
var _was_warning:=false
var _angles: Array[float]=[]
@onready var sprite: Sprite2D = $Sprite2D
func _ready() -> void:
 add_to_group("enemies")
 _player = get_tree().get_first_node_in_group("player") as Node2D
 _phase = randf()*TAU
 _orbit_sign = -1 if randf()<0.5 else 1
 _attack_timer = Campaign.attack_interval(Game.selected_map_id)+randf_range(0.4,1.4)
 _max_health = health
 _angles=_volley_angles()
 if role in ["flanker","charger"]:
  sprite.texture = preload("res://assets/future_updates/aircraft/player_wedge.svg")
  sprite.modulate = Color("ffa2bc")
 elif role == "orbiter":
  sprite.texture = preload("res://assets/future_updates/aircraft/player_saucer.svg")
  sprite.modulate = Color("d0a6ff")
 elif is_boss:
  sprite.texture = preload("res://assets/future_updates/aircraft/player_booster.svg")
  sprite.modulate = Color("ff8cba")
  var collision: CollisionShape2D = $CollisionShape2D
  collision.shape = collision.shape.duplicate()
  (collision.shape as CircleShape2D).radius = 70
  Game.boss_health = health
  Game.boss_max_health = health
  Game.boss_status_changed.emit()
func _physics_process(delta: float) -> void:
 if not Game.is_running:
  velocity=Vector2.ZERO
  return
 if not is_instance_valid(_player): return
 _phase += delta
 var vector := _player.global_position-global_position
 var heading := vector.normalized()
 var tangent := heading.orthogonal()*_orbit_sign
 var desired := heading
 if role == "flanker": desired=(vector+_player.velocity*0.55+tangent*220*sin(_phase)).normalized()
 elif role in ["gunner","orbiter","boss"]:
  var distance := 420.0 if is_boss else 330.0
  desired = heading*clampf((vector.length()-distance)/180,-0.6,1)+tangent*(0.8 if role=="orbiter" else 0.45)
 elif role == "charger":
  if _dash>0: desired=_aim; _dash-=delta
  elif _warning>0: desired=Vector2.ZERO
 velocity=desired.limit_length()*speed*(2.2 if _dash>0 else 1.0)
 move_and_slide()
 _wobble_time += delta*6
 var scale_factor := 0.42 if is_boss else BASE_SCALE
 sprite.scale=Vector2.ONE*scale_factor*(1+sin(_wobble_time)*0.035)
 sprite.rotation=heading.angle()+PI/2
 if role != "pursuer":
  _attack_timer-=delta
  if _warning>0:
   _warning-=delta
   if _warning<=0:
    if role=="charger": _dash=0.6
    else: _fire_volley()
  elif _attack_timer<=0:
   _aim=heading
   _warning=0.85 if role=="charger" else 0.7
   _attack_timer=Campaign.attack_interval(Game.selected_map_id)*(0.7 if is_boss else 1.0)
 if _warning>0 or _warning<=0 and _was_warning:
  queue_redraw()
 _was_warning=_warning>0
func _draw() -> void:
 if _warning>0:
  draw_arc(Vector2.ZERO,85 if is_boss else 48,0,TAU,32,Color("ffca70",0.85),3,true)
  for angle in _angles:
   draw_line(Vector2.ZERO,_aim.rotated(angle)*360,Color(1,0.35,0.4,0.3),3,true)
 if is_boss:
  draw_rect(Rect2(-70,-100,140,8),Color("291a39"))
  draw_rect(Rect2(-70,-100,140*maxf(0,float(health)/_max_health),8),Color("ff7898"))
func _fire_volley() -> void:
 if not Game.is_running:return
 var angles := _angles
 var count:=get_tree().get_nodes_in_group("enemy_shots").size()
 var root:=get_tree().current_scene
 var cache:=root.get_node_or_null("CombatPool")
 for angle in angles:
  if count>=64:break
  count+=1
  var dir:=_aim.rotated(angle)
  var pos:=global_position+dir*(85 if is_boss else 60)
  if cache:
   cache.hostile(pos,dir,220+Campaign.index(Game.selected_map_id)*10,2 if is_boss else 1)
   continue
  var shot:=EnemyShot.new()
  shot.direction=_aim.rotated(angle)
  shot.speed=220+Campaign.index(Game.selected_map_id)*10
  shot.damage=2 if is_boss else 1
  shot.position=global_position+shot.direction*(85 if is_boss else 60)
  get_tree().current_scene.add_child(shot)
func _volley_angles() -> Array[float]:
 if is_boss:
  match Game.selected_map_id:
   "coast": return [-0.35,0.0,0.35]
   "desert": return [-0.12,0.0,0.12]
   "volcano": return [0.0,PI/4,PI/2,3*PI/4,PI,5*PI/4,3*PI/2,7*PI/4]
   "glacier": return [-0.45,-0.15,0.15,0.45]
   _: return [-0.55,-0.27,0.0,0.27,0.55]
 if role=="orbiter": return [-0.28,0.28]
 return [0.0]
func hit() -> void:
 if _dead or not Game.is_running: return
 health-=1
 queue_redraw()
 if is_boss:
  Game.boss_health=maxi(0,health)
  Game.boss_status_changed.emit()
 if health<=0: kill()
 else:
  var original:=sprite.modulate
  sprite.modulate=Color(3,3,3)
  create_tween().tween_property(sprite,"modulate",original,0.12)
func kill() -> void:
 if _dead: return
 _dead=true
 Game.add_score(150 if is_boss else DIE_SCORE)
 Game.record_enemy_kill()
 if is_boss: Game.record_boss_defeat()
 Game.request_screen_shake(9 if is_boss else 4)
 SoundEffects.play_explosion()
 var root:=get_tree().current_scene
 if root:
  ExplosionParticles.spawn(root,global_position,Color("ff8a63"))
  FloatingText.spawn(root,global_position,"+150" if is_boss else "+10",Color("ffd166"))
 queue_free()
