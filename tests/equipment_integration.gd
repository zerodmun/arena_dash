extends Node
var failures: Array[String]=[]
const NEW_SHIPS=["solaris","vortex","nemesis","chronos"]
const NEW_WEAPONS=["plasma_lance","nova_burst"]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("review")
func capture(name: String) -> void:
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://qa/equipment-qa/gameplay_"+name+".png")
func review() -> void:
 Game.save_path=("user://equipment-integration-review.cfg" if OS.get_name()=="Android" else "res://qa/equipment-integration-review.cfg")
 var restart:="--resume" in OS.get_cmdline_user_args()
 if restart:
  Game._load_save()
  check(Game.coins==9120 and Game.selected_ship_id=="chronos" and Game.selected_weapon_id=="nova_burst","Second process restores exact purchased balance/loadout")
  for id in NEW_SHIPS:check(Game.owns_equipment("ship",id),"Ship ownership survives process restart")
  for id in NEW_WEAPONS:check(Game.owns_equipment("weapon",id),"Weapon ownership survives process restart")
  finish();return
 var fresh:=ConfigFile.new()
 Game._load_economy(fresh,false)
 Game.selected_ship_id="valkyrie";Game.selected_weapon_id="plasma"
 for id in NEW_SHIPS:
  check(not Game.owns_equipment("ship",id) and not Game.select_ship(id),"New aircraft locked")
  check(Game.purchase_equipment("ship",id)=="insufficient" and Game.coins==0,"Insufficient aircraft cannot deduct")
 for id in NEW_WEAPONS:check(not Game.owns_equipment("weapon",id) and not Game.select_weapon(id),"New weapons locked")
 var legacy:=ConfigFile.new()
 Game._load_economy(legacy,true)
 check(Game.owned_ships.size()==12 and Game.owned_weapons.size()==4,"Migration keeps original free entitlements only")
 for id in NEW_SHIPS:check(not Game.owns_equipment("ship",id),"Migration does not gift new ships")
 for id in NEW_WEAPONS:check(not Game.owns_equipment("weapon",id),"Migration does not gift new weapons")
 var equipped_legacy:=ConfigFile.new()
 equipped_legacy.set_value("settings","ship","vortex")
 equipped_legacy.set_value("settings","weapon","plasma_lance")
 Game._load_economy(equipped_legacy,true)
 check(Game.owns_equipment("ship","vortex") and Game.owns_equipment("weapon","plasma_lance") and not Game.owns_equipment("ship","chronos"),"Explicit legacy loadout is preserved without gifting other new content")
 Game._load_economy(legacy,true)
 Game.coins=16000;Game._save_game()
 for id in NEW_SHIPS:
  var balance:=Game.coins
  check(Game.purchase_equipment("ship",id)=="purchased" and Game.coins==balance-Game.equipment_price("ship",id),"Exact aircraft price deducted")
  for i in 10:check(Game.purchase_equipment("ship",id)=="owned" and Game.coins==balance-Game.equipment_price("ship",id),"Rapid duplicate aircraft taps never deduct twice")
 for id in NEW_WEAPONS:
  var balance:=Game.coins
  check(Game.purchase_equipment("weapon",id)=="purchased" and Game.coins==balance-Game.equipment_price("weapon",id),"Exact weapon price deducted")
  for i in 10:check(Game.purchase_equipment("weapon",id)=="owned" and Game.coins==balance-Game.equipment_price("weapon",id),"Rapid duplicate weapon taps never deduct twice")
 var valid_path:=Game.save_path
 Game.save_path="res://qa/equipment-qa/missing-directory/save.cfg"
 check(not Game.select_ship("chronos") and Game.selected_ship_id=="valkyrie","Failed selection save retains previous aircraft")
 check(not Game.select_weapon("nova_burst") and Game.selected_weapon_id=="plasma","Failed selection save retains previous weapon")
 Game.save_path=valid_path
 var scene=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 for frame in 3:await get_tree().process_frame
 Game.set_mobile_ui(true)
 for id in NEW_SHIPS:
  Game.select_ship(id)
  scene.hud._on_start_pressed()
  check(Game.lives==Game.SHIPS[id].max_lives,"Mission starts with configured new-aircraft shields")
  check(scene.hud.ship_badge.text.contains(Game.SHIPS[id].name),"Gameplay HUD displays new aircraft")
  check(scene.player.sprite.texture.resource_path==Game.SHIPS[id].texture,"Actual gameplay uses supplied ship artwork")
  check(is_equal_approx(scene.player.base_scale,Game.SHIPS[id].visual_scale),"Gameplay uses ship scale")
  check(is_equal_approx(scene.player.get_node("CollisionShape2D").shape.radius,Game.SHIPS[id].collision_radius),"Gameplay collision matches config")
  check(scene.player.shoot_point.position==Game.SHIPS[id].muzzle,"Gameplay uses firing position")
  check(scene.player.speed==Game.SHIPS[id].speed,"Existing movement uses aircraft speed")
  scene.player._invuln=0;scene.player.sprite.visible=true
  await capture(id)
 scene.player.last_aim=Vector2.UP
 for id in NEW_WEAPONS:
  Game.select_weapon(id)
  for b in get_tree().get_nodes_in_group("bullets"):b.despawn()
  await get_tree().process_frame
  scene.hud._on_fire_down()
  scene.player.weapon_controller.cooldown=0
  scene.player._physics_process(.016)
  scene.hud._on_fire_up()
  var shots=get_tree().get_nodes_in_group("bullets")
  await capture(id)
  check(shots.size()==(5 if id=="nova_burst" else 4),"Touch fire creates actual configured projectile pattern")
  for b: Projectile in shots:b.set_physics_process(false)
  for b: Projectile in shots:
   check(b.weapon_id==id and b.damage==2 and b.speed==Game.WEAPONS[id].projectile_speed,"Projectile config/weapon/damage applied")
   check(b.sprite.texture.resource_path==Game.WEAPONS[id].texture,"Actual projectile uses supplied artwork")
   var enemy=load("res://scenes/enemy.tscn").instantiate()
   enemy.health=3;scene.add_child(enemy);enemy.set_physics_process(false)
   b.set_physics_process(false)
   b.global_position=Vector2(2000,-500)
   enemy.global_position=b.global_position+b.direction*100
   await get_tree().physics_frame
   await get_tree().physics_frame
   b._physics_process(.2)
   check(enemy.health==1,"Weapon damage reaches actual enemy")
   enemy.queue_free()
 # Every new shot has a fresh object and catalog snapshot.
 Game.selected_weapon_id="plasma"
 scene.player._shoot()
 var starter_shot: Projectile=get_tree().get_nodes_in_group("bullets")[-1]
 check(starter_shot.damage==1 and starter_shot.speed==680 and starter_shot.sprite.texture.resource_path==Game.WEAPONS.plasma.texture,"Fresh projectile uses starter values")
 Game.is_running=false;scene.queue_free()
 for frame in 3:await get_tree().process_frame
 Game.select_ship("chronos");Game.select_weapon("nova_burst")
 check(Game.coins==9120,"Final test balance is exact")
 # Existing positive ownership entries are retained even if granted by an earlier build.
 Game._load_save()
 for id in NEW_SHIPS:check(Game.owns_equipment("ship",id),"Versioned saves retain purchased new ships")
 finish()
func finish() -> void:
 SoundEffects.stop_all()
 print("EQUIPMENT INTEGRATION: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
