extends Node2D
var failures: Array[String]=[]
var checks:=0
func check(value: bool,message: String) -> void:
 checks+=1
 if not value: failures.append(message);push_error(message)
func clear_shots() -> void:
 for bullet in get_tree().get_nodes_in_group("bullets"):bullet.despawn()
 await get_tree().process_frame
 await get_tree().physics_frame
func _ready() -> void: run.call_deferred()
func run() -> void:
 Game.save_path=("user://movement-firing-test.cfg" if OS.get_name()=="Android" else "res://qa/movement-firing-test.cfg")
 Game.is_running=true
 get_tree().current_scene=self
 var manager:=ProjectileManager.new();add_child(manager)
 var player:=load("res://scenes/player.tscn").instantiate() as Player
 add_child(player);player.set_physics_process(false)
 # Transformed parent catches world/local errors in pooled AND fallback spawning.
 position=Vector2(110,70);rotation=.2
 var headings:=[Vector2.UP,Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN,Vector2(-1,-1).normalized(),Vector2(1,1).normalized(),Vector2.LEFT,Vector2.UP]
 for ship_id in Game.SHIPS:
  Game.selected_ship_id=ship_id
  for weapon_id in Game.WEAPONS:
   Game.selected_weapon_id=weapon_id;player.apply_customization()
   for heading in headings:
    await clear_shots()
    player.global_position=Vector2(1000,1000)
    # Requested direction differs during a turn; firing must follow the real nose.
    player.last_aim=-heading
    player.global_rotation=heading.angle()+PI/2
    player.global_position+=heading*8
    player._shoot()
    var bullets:=get_tree().get_nodes_in_group("bullets")
    var pattern:String=Game.WEAPONS[weapon_id].pattern
    check(bullets.size()==int(Game.WEAPONS[weapon_id].get("projectile_count",3 if pattern=="spread" else 2 if pattern in ["twin","burst"] else 1)),"Pattern "+ship_id+"/"+weapon_id)
    for bullet in bullets:
     check(bullet.direction.dot(heading)>cos(deg_to_rad(25)),"Shot tracks rotating world muzzle")
     check(bullet.global_position.distance_to(player.shoot_point.global_position)<=32.1,"World muzzle coordinates")
     check(bullet.shooter==player and (bullet.collision_mask&2)==0,"Owner excluded")
     var pos:Vector2=bullet.global_position
     manager.impact(bullet,{"collider_id":player.get_instance_id(),"point":player.global_position})
     check(bullet.active,"Self-contact cannot explode/despawn")
     bullet._physics_process(.01)
     check(bullet.global_position.distance_to(pos+bullet.direction*bullet.speed*.01)<.01,"World velocity independent of player")
 await clear_shots()
 Game.selected_ship_id="valkyrie";Game.selected_weapon_id="ion";player.apply_customization()
 player.global_position=Vector2(500,500);player.global_rotation=0
 var wall:=StaticBody2D.new();wall.collision_layer=1;wall.collision_mask=0
 var col:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(150,20);col.shape=shape;wall.add_child(col);add_child(wall)
 wall.global_position=player.shoot_point.global_position
 await get_tree().physics_frame;await get_tree().physics_frame
 player._shoot();check(get_tree().get_nodes_in_group("bullets").is_empty(),"Embedded muzzle never creates age-zero impact")
 wall.global_position=Vector2(500,465)
 await get_tree().physics_frame;await get_tree().physics_frame
 player._shoot();check(get_tree().get_nodes_in_group("bullets").is_empty(),"Blocked corridor cannot teleport a shot through cover")
 wall.global_position=Vector2(500,300)
 wall.reset_physics_interpolation()
 await get_tree().physics_frame;await get_tree().physics_frame
 player._shoot();check(get_tree().get_nodes_in_group("bullets").size()==1,"Clear muzzle fires normally")
 for i in 40:await get_tree().physics_frame
 check(get_tree().get_nodes_in_group("bullets").is_empty(),"Real terrain impact still consumes shot")
 await clear_shots()
 # Only the manager route exists, including under a transformed world parent.
 wall.global_position=Vector2(300,300)
 await get_tree().physics_frame;await get_tree().physics_frame
 player._shoot()
 for bullet in get_tree().get_nodes_in_group("bullets"):
  check(bullet.global_position.distance_to(player.shoot_point.global_position)<.01,"Centralized global muzzle")
  check(bullet.direction.dot(Vector2.UP)>.999,"Centralized global heading")
 print("MOVEMENT_FIRING ",JSON.stringify({"combinations":96,"headings_per_combination":8,"checks":checks,"failures":failures}))
 Game.is_running=false
 await clear_shots()
 player.queue_free();manager.queue_free();wall.queue_free()
 for i in 3:await get_tree().process_frame
 get_tree().quit(0 if failures.is_empty() else 1)
