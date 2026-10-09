extends Node
var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
 if not condition: failures.append(message); push_error(message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 Game.save_path="res://build/campaign-test-save.cfg"
 Game.completed_levels={}
 Game.last_completed_planet=""
 var previous_interval:=5.0
 var previous_speed:=0.0
 for id: String in Campaign.ORDER:
  Game.selected_map_id=id
  Game.selected_ship_id="titan"
  var scene: Node2D=load("res://scenes/main.tscn").instantiate()
  get_tree().root.add_child(scene)
  get_tree().current_scene=scene
  var player: Player=scene.player
  player.set_physics_process(false)
  var spawner: EnemySpawner=scene.enemy_spawner
  spawner.set_physics_process(false)
  check(spawner.initial_interval<previous_interval and spawner.base_speed>previous_speed,"Gradual difficulty "+id)
  previous_interval=spawner.initial_interval
  previous_speed=spawner.base_speed
  var roles: Array=Campaign.ROSTERS[Campaign.index(id)]
  for role: String in roles:
   var enemy:=spawner._spawn_enemy(role)
   check(enemy!=null,"Safe spawn for "+id+" / "+role)
   if not enemy: continue
   check(enemy.position.distance_to(player.position)>=500,"No unavoidable spawn damage")
   enemy.set_physics_process(false)
   enemy._physics_process(0.1)
   check(enemy.velocity.length()<=enemy.speed*2.3,"Bounded movement speed")
   if role!="pursuer":
    enemy._attack_timer=0
    enemy._physics_process(0.1)
    check(enemy._warning>0,"Attack telegraph / "+role)
    var shots_before:=get_tree().get_nodes_in_group("enemy_shots").size()
    enemy._physics_process(0.2)
    check(get_tree().get_nodes_in_group("enemy_shots").size()==shots_before,"Warning does not shoot immediately")
    enemy._physics_process(0.7)
    if role=="charger": check(enemy._dash>0,"Charger commits to announced direction")
    else: check(get_tree().get_nodes_in_group("enemy_shots").size()>shots_before,"Role fires its volley")
   enemy.queue_free()
   await get_tree().process_frame
  # Exercise actual hostile projectile physics and invulnerability.
  scene._clear_entities()
  await get_tree().process_frame
  player._invuln=0
  var lives_before:=Game.lives
  var shot:=EnemyShot.new()
  shot.position=player.position+Vector2(0,120)
  shot.direction=Vector2.UP
  scene.add_child(shot)
  for frame in 40: await get_tree().physics_frame
  check(Game.lives==lives_before-1,"Hostile projectile collision")
  player.receive_hit(1)
  check(Game.lives==lives_before-1,"Invulnerability prevents stacked damage")
  player._invuln=0
  player.receive_hit(2)
  check(Game.lives==lives_before-3,"Guardian damage is bounded to two shields")
  Game.lives=5
  Game.mission_damage=0 # Start a clean rating fixture after the damage/invulnerability checks.
  if Campaign.has_boss(id):
   Game.enemies_destroyed=Campaign.target(id)/2
   spawner._physics_process(0.01)
   var guardians:=get_tree().get_nodes_in_group("enemies").filter(func(e: Enemy) -> bool: return e.is_boss)
   check(guardians.size()==1,"One guardian encounter per mission")
   if not guardians.is_empty():
    var boss: Enemy=guardians[0]
    boss.set_physics_process(false)
    check(Game.boss_max_health==boss.health,"Boss HUD health")
    var expected_count: int={"coast":3,"desert":3,"volcano":8,"glacier":4,"toxic":5}[id]
    check(boss._volley_angles().size()==expected_count,"Planet-specific guardian volley")
    boss._attack_timer=0
    boss._physics_process(0.1)
    check(boss._warning>0,"Guardian volley is telegraphed")
    var shots_before:=get_tree().get_nodes_in_group("enemy_shots").size()
    boss._physics_process(0.8)
    check(get_tree().get_nodes_in_group("enemy_shots").size()==shots_before+expected_count,"Guardian fires its complete pattern")
    Game.enemies_destroyed=Campaign.target(id)
    Game._check_mission_completion()
    check(not Game.mission_won,"Drone objective alone cannot skip guardian")
    for hit in boss.health: boss.hit()
    check(Game.boss_defeated and Game.mission_won,"Guardian defeat completes mission")
  else:
   for kill in Campaign.target(id): Game.record_enemy_kill()
  check(Game.last_completed_planet==id,"Completion records last successful planet")
  scene.free()
  await get_tree().process_frame
 # A replay of an older world must replace the latest completion, not the highest unlocked ID.
 Game.selected_map_id="forest"
 Game.start()
 for kill in Campaign.target("forest"): Game.record_enemy_kill()
 check(Game.hangar_planet()=="forest","Replay updates circular hangar planet")
 Game._save_game()
 Game.last_completed_planet=""
 Game.completed_levels={}
 Game._load_save()
 check(Game.hangar_planet()=="forest" and Game.completed_levels.size()==8,"Completion order survives reopen")
 var hangar: Hangar=load("res://scenes/hangar.tscn").instantiate()
 get_tree().root.add_child(hangar)
 check(hangar._map_card.planet_id=="forest","Reopened hangar uses replayed planet artwork")
 check(not hangar._map_card._has_point(Vector2.ZERO),"Hangar button has circular hit area")
 hangar.free()
 # Older saves lacking completion-order metadata migrate without losing unlocks.
 var cfg:=ConfigFile.new()
 cfg.load(Game.save_path)
 cfg.erase_section_key("campaign","last_completed")
 cfg.save(Game.save_path)
 Game._load_save()
 check(Game.hangar_planet()=="toxic","Legacy save migration")
 Game.is_running=false
 print("CAMPAIGN COMBAT: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 SoundEffects.stop_all()
 await get_tree().create_timer(0.2).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
