extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:
 call_deferred("review")
func review() -> void:
 Game.save_path=("user://coin-economy-review.cfg" if OS.get_name()=="Android" else "res://qa/coin-economy-review.cfg")
 # A second process confirms actual persisted balances/ownership.
 var previous:=ConfigFile.new()
 if OS.get_name()=="Android" and previous.load(Game.save_path)==OK and previous.get_value("qa","verified",false):
  Game._load_save()
  check(Game.coins==1110,"Android restart restores coins")
  check(Game.owns_equipment("ship","titan") and Game.owns_equipment("weapon","twin_laser"),"Android restart restores ownership")
  check(Game.selected_ship_id=="titan" and Game.selected_weapon_id=="twin_laser","Android restart restores loadout")
  finish("ANDROID RESTART")
  return
 DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
 Game.completed_levels={}
 Game._load_save()
 check(Game.coins==0,"New game zero coins")
 check(Game.owns_equipment("ship","valkyrie") and not Game.owns_equipment("ship","titan"),"Starter aircraft and locked aircraft")
 check(Game.purchase_equipment("ship","titan")=="insufficient" and Game.coins==0,"Insufficient purchase cannot deduct")
 Game.select_ship("titan")
 check(Game.selected_ship_id=="valkyrie","Locked equipment cannot equip")
 Game.start();Game.enemies_destroyed=Campaign.target("cyber");Game.boss_defeated=true
 Game.complete_mission()
 check(Game.last_coin_reward==460 and Game.coins==460,"Three-star first completion 460 coins")
 Game.complete_mission()
 check(Game.coins==460,"Same mission cannot claim twice")
 Game.start();Game.enemies_destroyed=Campaign.target("cyber");Game.boss_defeated=true;Game.complete_mission()
 check(Game.last_coin_reward==210 and Game.coins==670,"Repeat mission excludes first-clear bonus")
 check(Game.purchase_equipment("ship","titan")=="purchased" and Game.coins==520,"Aircraft debit and ownership")
 check(Game.purchase_equipment("ship","titan")=="owned" and Game.coins==520,"Duplicate purchase no debit")
 check(Game.purchase_equipment("weapon","twin_laser")=="purchased" and Game.coins==320,"Weapon debit and ownership")
 check(Game.purchase_equipment("weapon","not-real")=="invalid" and Game.purchase_equipment("bad","titan")=="invalid","Unknown purchases rejected")
 Game.select_ship("titan");Game.select_weapon("twin_laser")
 Game.coins=0;Game.owned_ships={};Game.owned_weapons={};Game._load_save()
 check(Game.coins==320 and Game.owns_equipment("ship","titan"),"Reload restores actual saved balance/ownership")
 check(Game.best_stars("cyber")==3,"Coin system preserves mission stars")
 var real_path:=Game.save_path
 Game.save_path="res://missing-directory/unwritable.cfg"
 check(Game.purchase_equipment("ship","phantom")=="save_failed" and Game.coins==320 and not Game.owns_equipment("ship","phantom"),"Failed write rolls transaction back")
 Game.save_path=real_path
 var malformed:=ConfigFile.new()
 malformed.set_value("economy","version",1);malformed.set_value("economy","coins",-50);malformed.set_value("economy","ships",{"invalid":true});malformed.save(Game.save_path)
 Game._load_save()
 check(Game.coins==0 and not Game.owns_equipment("ship","invalid"),"Invalid saved coins/ownership sanitized")
 var legacy:=ConfigFile.new()
 legacy.set_value("stats","high_score",9999);legacy.set_value("settings","ship","titan");legacy.set_value("settings","weapon","twin_laser");legacy.set_value("campaign","completed",{"cyber":3});legacy.save(Game.save_path)
 Game._load_save()
 check(Game.high_score==9999 and Game.coins==460,"Migration credits mission coins, keeps combat record separate")
 check(Game.owned_ships.size()==12 and Game.owned_weapons.size()==4,"Legacy free equipment remains available")
 Game._load_save()
 check(Game.coins==460,"Migration cannot grant again")
 # Leave a distinctive snapshot for the second Android process.
 Game.coins=1110;Game.select_ship("titan");Game.select_weapon("twin_laser")
 var marker:=ConfigFile.new();marker.load(Game.save_path);marker.set_value("qa","verified",true);marker.save(Game.save_path)
 # Preserve marker for restart by avoiding further save calls.
 Game._score_dirty=false
 finish("COIN ECONOMY")
func finish(stage: String) -> void:
 print(stage+": "+("PASS" if failures.is_empty() else "FAIL")+" / "+str(failures.size())+" failures")
 SoundEffects.stop_all()
 get_tree().quit(0 if failures.is_empty() else 1)
