class_name EnemySpawner
extends Node2D
@export var enemy_scene: PackedScene
@export var base_speed := 95.0
@export var initial_interval := 1.9
@export var min_interval := 0.65
@export var max_enemies := 14
@export var arena_rect := Rect2(140,140,6520,4120)
var _timer := 1.9
var _alive := 0
var _spawn_count := 0
var _boss_spawned := false
func _ready() -> void:
 Game.game_started.connect(_on_game_started)
func _on_game_started() -> void:
 var level:=Campaign.index(Game.selected_map_id)
 initial_interval=1.9-level*0.13
 base_speed=85.0+level*13
 max_enemies=14+level*2
 _timer=initial_interval
 _spawn_count=0
 _boss_spawned=false
func _physics_process(delta: float) -> void:
 if not Game.is_running: return
 if Campaign.has_boss(Game.selected_map_id) and not _boss_spawned and Game.enemies_destroyed>=Campaign.target(Game.selected_map_id)/2:
  var boss:=_spawn_enemy("boss")
  if boss: _boss_spawned=true
 _timer-=delta
 if _alive>=max_enemies:_timer=maxf(0.0,_timer)
 if _timer<=0 and _alive<max_enemies:
  _spawn_formation()
  _spawn_count+=1
  _timer+=maxf(min_interval,initial_interval-minf(_spawn_count*0.022,0.5))
func _spawn_formation() -> void:
 var level:=Campaign.index(Game.selected_map_id)
 var roster: Array=Campaign.ROSTERS[level]
 var count:=1 if level==0 or _spawn_count%3!=2 else (3 if level>=4 else 2)
 var anchor:=_pick_spawn_position()
 if not arena_rect.has_point(anchor): return
 var player:=get_tree().get_first_node_in_group("player") as Node2D
 var across: Vector2=(player.global_position-anchor).normalized().orthogonal() if player else Vector2.RIGHT
 for i in count:
  if _alive>=max_enemies: break
  var role: String=roster[(_spawn_count+i)%roster.size()]
  if level==0 and _spawn_count<3: role="pursuer"
  var offset:=across*(i-(count-1)*0.5)*150
  if Game.selected_map_id in ["coast","desert"]: offset+=across.orthogonal()*absf(i-(count-1)*0.5)*100
  _spawn_enemy(role,anchor+offset)
func _spawn_enemy(role: String="pursuer", location:=Vector2.INF) -> Enemy:
 if _alive>=max_enemies: return null
 var pos:=_pick_spawn_position() if location==Vector2.INF else location
 if not _safe(pos): return null
 var enemy:=enemy_scene.instantiate() as Enemy
 enemy.role=role
 enemy.is_boss=role=="boss"
 enemy.speed=base_speed+randf_range(0,25)+minf(_spawn_count*0.3,15)
 enemy.health=2 if role=="gunner" or role=="orbiter" else 1
 if enemy.is_boss:
  enemy.health=20+Campaign.index(Game.selected_map_id)*2
  enemy.speed=base_speed*0.8
 enemy.position=pos
 add_child(enemy)
 _alive+=1
 enemy.tree_exited.connect(func() -> void: _alive-=1)
 return enemy
func _safe(pos: Vector2) -> bool:
 if not arena_rect.has_point(pos): return false
 var player:=get_tree().get_first_node_in_group("player") as Node2D
 if player and pos.distance_to(player.global_position)<500: return false
 for cover in get_tree().get_nodes_in_group("moving_cover"):
  if pos.distance_to(cover.global_position)<170: return false
 return true
func _pick_spawn_position() -> Vector2:
 var player:=get_tree().get_first_node_in_group("player") as Node2D
 var origin:=player.global_position if player else arena_rect.get_center()
 for attempt in 64:
  var angle:=randf()*TAU
  var pos:=origin+Vector2.from_angle(angle)*randf_range(650,1100)
  if _safe(pos): return pos
 return Vector2.INF
