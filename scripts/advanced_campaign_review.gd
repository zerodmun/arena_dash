class_name AdvancedCampaignReview
extends Node
## Explicit debug QA harness. The ordinary Android preset never invokes this.
signal finished(success: bool)
var failures: Array[String]=[]
var results: Array[Dictionary]=[]
var output := "user://advanced_campaign"
var seconds_per_world := 12.0
var quit_when_finished := false
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:
 call_deferred("run")
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await get_tree().process_frame
 RenderingServer.force_draw()
 get_viewport().get_texture().get_image().save_png(output+"_"+name+".png")
func run() -> void:
 Game.save_path=output+"_save.cfg"
 Game.completed_levels={}
 Game.rewarded_planets={}
 Game.coins=0
 Game.owned_ships={"falcon":true,"aurora":true,"valkyrie":true,"titan":true}
 Game.selected_ship_id="titan"
 Game.selected_weapon_id="plasma"
 for id: String in Campaign.ORDER.slice(0,8):Game.completed_levels[id]=3
 check(Campaign.ORDER.size()==15,"Exactly seven appended levels")
 check(not Game.is_level_unlocked("ice"),"Advanced worlds stay locked behind three stars")
 for locale in ["en","id"]:
  I18n.set_language(locale,false)
  await get_tree().change_scene_to_file("res://scenes/level_select.tscn")
  await get_tree().scene_changed
  var levels: LevelSelect=get_tree().current_scene
  levels._select("lava")
  check(levels.cards.size()==15 and levels._centers.size()==15,"Continuous map contains all fifteen planets")
  check(not levels._deploy.disabled,"Level 9 unlocks from saved original chain")
  check(levels._title.text.contains(I18n.t(Game.MAPS.lava.name)),"Advanced title localized")
  for id: String in Campaign.ORDER.slice(8):
   check(ResourceLoader.exists(Campaign.planet(id)),"Planet resource "+id)
   for key in ["icon","tile","overlay"]:check(ResourceLoader.exists(Game.MAPS[id][key]),"Map resource "+id+" / "+key)
  await get_tree().create_timer(0.4).timeout
  await capture("selection_"+locale)
 I18n.set_language("en",false)
 for id: String in Campaign.ORDER.slice(8):
  check(Game.select_level(id),"Sequential advanced selection "+id)
  await get_tree().change_scene_to_file("res://scenes/main.tscn")
  await get_tree().scene_changed
  var scene: Node2D=get_tree().current_scene
  scene.player._invuln=100000
  Input.action_press("fire")
  await get_tree().create_timer(seconds_per_world).timeout
  Input.action_release("fire")
  check(scene.enemy_spawner.max_enemies<=30,"Bounded active enemies "+id)
  await capture(id)
  var sample: Dictionary=PerfDiagnostics.report() if PerfDiagnostics.enabled else {}
  scene.enemy_spawner.set_physics_process(false)
  scene._clear_entities()
  await get_tree().process_frame
  var role_results: Array[String]=[]
  for role: String in Campaign.ROSTERS[Campaign.index(id)]:
   var enemy: Enemy=scene.enemy_spawner._spawn_enemy(role)
   if enemy:
    check(enemy.sprite.texture.resource_path==Campaign.enemy_art(id,role),"Advanced enemy artwork "+id+" / "+role)
    check(enemy.health==Campaign.enemy_health(id,role),"Progressive armor "+id+" / "+role)
    role_results.append(role)
  var before:=Game.coins
  # Exercise the real boss defeat and mission award path with controlled QA objectives.
  scene.enemy_spawner.set_physics_process(false)
  Game.enemies_destroyed=Campaign.target(id)
  Game.mission_damage=0
  Game.mission_elapsed=Campaign.par_time(id)-1
  var boss: Enemy=scene.enemy_spawner._spawn_enemy("boss")
  check(boss!=null,"Advanced guardian spawns "+id)
  if boss:boss.hit(boss.health)
  check(Game.mission_won and Game.best_stars(id)==3,"Guardian defeat records three-star clear "+id)
  check(Game.coins-before==460+10*Campaign.index(id),"First completion award "+id)
  check(Game.rewarded_planets.get(id,false),"First completion claim saved "+id)
  var awarded:=Game.coins
  Game.complete_mission()
  check(Game.coins==awarded,"Repeated completion cannot duplicate award "+id)
  Game._load_save()
  check(Game.best_stars(id)==3 and Game.coins==awarded,"Advanced state survives reload "+id)
  results.append({"map":id,"roles_checked":role_results,"reward":awarded-before,"performance":sample})
  print("ADVANCED_WORLD ",JSON.stringify(results[-1]))
  await get_tree().create_timer(0.25).timeout
 Game.is_running=false
 SoundEffects.stop_all()
 var file:=FileAccess.open(output+"_results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"failures":failures,"worlds":results,"save_isolated":Game.save_path},"  "))
 print("ADVANCED CAMPAIGN: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().change_scene_to_file("res://scenes/level_select.tscn")
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().current_scene._select("dark_void")
 await capture("completed")
 finished.emit(failures.is_empty())
 if quit_when_finished:get_tree().quit(0 if failures.is_empty() else 1)
