extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("run")
func complete(id: String,stars: int) -> void:
 Game.selected_map_id=id
 Game.selected_ship_id="titan"
 Game.start()
 Game.mission_damage=3 if stars<3 else 0
 Game.mission_elapsed=Campaign.par_time(id)+1 if stars==1 else Campaign.par_time(id)
 Game.enemies_destroyed=Campaign.target(id)
 Game.boss_defeated=true
 Game.complete_mission()
func settle(name: String) -> void:
 await get_tree().create_timer(0.35).timeout
 for i in 4:await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://build/progression_"+name+".png")
func run() -> void:
 Game.save_path="res://build/three-star-test.cfg"
 Game.completed_levels={}
 Game.last_completed_planet=""
 check(Game.is_level_unlocked("cyber"),"Level one starts unlocked")
 check(not Game.select_map("toxic") and not Game.select_level("forest"),"Both selection APIs reject locked worlds")
 Game.selected_map_id="toxic";Game.start()
 check(Game.selected_map_id=="cyber","Direct assignment cannot bypass start guard")
 Game.complete_mission()
 check(not Game.mission_won,"Completion requires actual mission objectives")
 for i in Campaign.ORDER.size():
  var id: String=Campaign.ORDER[i]
  check(Game.is_level_unlocked(id),"Previous three-star clear unlocks "+id)
  for stars in [1,2,3]:
   complete(id,stars)
   check(Game.last_attempt_stars==stars and Game.best_stars(id)==stars,"Rating and best saved "+id+" / "+str(stars))
   check(Game.is_level_cleared(id)==(stars==3),"Partial attempt is not a full clear")
   if i+1<Campaign.ORDER.size():
    check(Game.is_level_unlocked(Campaign.ORDER[i+1])==(stars==3),"Strict unlock "+id+" / "+str(stars))
    if stars<3:check(not Game.select_map(Campaign.ORDER[i+1]),"Direct map rejection after partial clear")
   Game._load_save()
   check(Game.best_stars(id)==stars,"Rating survives CFG reload")
  complete(id,1)
  check(Game.best_stars(id)==3 and Game.last_attempt_stars==1,"Replay preserves best but reports actual attempt")
 # Both independent bonus criteria; boundary includes exact allowed damage/time for every craft/world.
 for id: String in Campaign.ORDER:
  for ship: String in Game.SHIPS:
   var budget:=Campaign.damage_budget(ship)
   var limit:=Campaign.par_time(id)
   check(Campaign.rating(id,ship,budget,limit)==3,"Achievable inclusive three-star boundary")
   check(Campaign.rating(id,ship,budget+1,limit)==2,"Damage bonus independent")
   check(Campaign.rating(id,ship,budget,limit+0.01)==2,"Time bonus independent")
 # Legacy attempts keep their ratings; orphan later clears cannot bypass the full prerequisite chain.
 var cfg:=ConfigFile.new()
 cfg.set_value("campaign","completed",{"cyber":2,"forest":3,"space":3,"toxic":99,"fake":3,"desert":NAN})
 cfg.set_value("campaign","last_completed","forest")
 cfg.set_value("settings","map","space")
 cfg.save(Game.save_path)
 Game._load_save()
 check(Game.best_stars("cyber")==2 and Game.best_stars("forest")==3,"Legacy ratings preserved without promotion")
 check(not Game.is_level_unlocked("forest") and not Game.is_level_unlocked("space"),"Orphan ratings cannot bypass chain")
 check(Game.selected_map_id=="cyber" and Game.hangar_planet()=="cyber","Legacy selection/latest clear migrated safely")
 check(Game.best_stars("toxic")==0 and not Game.completed_levels.has("fake"),"Invalid save ratings do not unlock anything")
 # Render partial/full results in both languages and validate button behavior and actual-vs-best stars.
 for locale in ["en","id"]:
  I18n.set_language(locale)
  Game.completed_levels={}
  Game.selected_map_id="cyber"
  var scene: Node2D=load("res://scenes/main.tscn").instantiate()
  get_tree().root.add_child(scene);get_tree().current_scene=scene
  scene.player.set_physics_process(false)
  for stars in [1,2,3,1]:
   complete("cyber",stars)
   await settle(locale+"_"+str(stars)+"_best"+str(Game.best_stars("cyber")))
   var hud: HUD=scene.hud
   check(hud._stars.get_child_count()==3,"Exactly three result star slots")
   check(hud._next_level.disabled==(stars<3),"Next disabled for partial attempt")
   check(hud.kills_label.text==I18n.t("Attempt: %d / 3 stars  •  Best: %d / 3",[stars,Game.best_stars("cyber")]),"Bilingual actual/best feedback")
   check(get_viewport().get_visible_rect().encloses(hud._progress_feedback.get_global_rect()),"Progress feedback fits viewport")
  scene.free()
  var levels: LevelSelect=load("res://scenes/level_select.tscn").instantiate()
  get_tree().root.add_child(levels)
  levels._select("cyber")
  check(levels._title.text.contains(I18n.t("THREE-STAR CLEAR")),"Campaign full-clear status")
  await settle("campaign_"+locale)
  levels.free()
 Game.is_running=false
 SoundEffects.stop_all()
 print("THREE-STAR PROGRESSION: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
