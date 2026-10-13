extends Node
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
 if not value: failures.append(message); push_error(message)
func _ready() -> void: call_deferred("run")
func mouse(levels: LevelSelect, at: Vector2, down: bool) -> void:
 var event := InputEventMouseButton.new()
 event.position = at
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = down
 levels._input(event)
func move_mouse(levels: LevelSelect, at: Vector2) -> void:
 var event := InputEventMouseMotion.new()
 event.position = at
 levels._input(event)
func capture(name: String) -> void:
 await get_tree().create_timer(0.4).timeout
 await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://qa/continuous_map_"+name+".png")
func run() -> void:
 Game.save_path = "res://qa/continuous-map-isolated.cfg"
 Game.completed_levels = {}
 Game.rewarded_planets = {}
 Game.map_focus_planet = ""
 Game.map_zoom = 1.0
 Game.selected_map_id = "cyber"
 Game.coins = 1234
 Game.owned_ships = {"valkyrie":true,"titan":true}
 Game.owned_weapons = {"plasma":true}
 Game.selected_ship_id = "titan"
 var levels: LevelSelect = load("res://scenes/level_select.tscn").instantiate()
 get_tree().root.add_child(levels)
 check(levels.cards.size()==15 and levels._centers.size()==15,"All planets occupy one world")
 check(levels._selected=="cyber" and Game.latest_unlocked_planet()=="cyber","New player focuses first mission")
 check(levels._map_view.clip_contents,"Map clips below fixed HUD")
 for i in LevelSelect.POINTS.size():
  for j in range(i+1,LevelSelect.POINTS.size()):
   check(LevelSelect.POINTS[i].distance_to(LevelSelect.POINTS[j])>320,"Planet artwork and labels have spacing")
 await capture("new_player")
 # Real mouse event path: a tap inspects a locked world; dragging from it never selects.
 levels._focus_planet("forest",false)
 var at: Vector2 = levels._map_view.global_position + levels._offset + LevelSelect.POINTS[1]*levels._scene_scale
 mouse(levels,at,true); mouse(levels,at,false)
 check(levels._selected=="forest" and levels._deploy.disabled,"Tap inspects locked mission without launch")
 levels._select("cyber")
 mouse(levels,at,true); move_mouse(levels,at+Vector2(-100,-70)); mouse(levels,at+Vector2(-100,-70),false)
 check(levels._selected=="cyber" and levels._velocity.length()>0,"Mouse drag does not tap and retains momentum")
 var offset := levels._offset
 levels._process(0.016)
 check(levels._offset!=offset,"Momentum moves world after release")
 # Real touch path and second finger exclusion.
 levels._focus_planet("space",false)
 at = levels._map_view.get_global_rect().get_center()
 var touch := InputEventScreenTouch.new()
 touch.index=0; touch.position=at; touch.pressed=true
 levels._input(touch)
 var second := InputEventScreenTouch.new()
 second.index=1; second.position=at; second.pressed=true
 levels._input(second)
 check(levels._pinch_ids.size()==2,"Second finger begins map pinch")
 var drag := InputEventScreenDrag.new()
 drag.index=0; drag.position=at+Vector2(70,80)
 levels._input(drag)
 touch.position=drag.position; touch.pressed=false
 levels._input(touch)
 second.pressed=false; levels._input(second)
 check(levels._selected=="cyber" and levels._pointer==-2,"Touch dragging suppresses selection")
 levels._zoom_target=1.0
 levels._apply_zoom(1.0,levels._map_view.size*0.5)
 levels._set_offset(Vector2(-500,-500))
 for movement in [Vector2(100,0),Vector2(-100,0),Vector2(0,100),Vector2(0,-100)]:
  offset=levels._offset
  levels._set_offset(offset+movement)
  check(levels._offset==offset+movement,"World pans freely "+str(movement))
 levels._set_offset(Vector2(9999,9999))
 check(levels._offset==Vector2.ZERO,"Upper and left boundaries clamp")
 levels._set_offset(Vector2(-9999,-9999))
 check(levels._offset==-(LevelSelect.WORLD_SIZE*levels._scene_scale-levels._map_view.size).max(Vector2.ZERO),"Lower and right boundaries clamp")
 # Original final level unlocks lava; every advanced mission saves stars and economy.
 for id: String in Campaign.ORDER.slice(0,7): Game.completed_levels[id]=3
 check(Game.latest_unlocked_planet()=="toxic" and not Game.is_level_unlocked("lava"),"Original final mission gates advanced chain")
 for id: String in Campaign.ORDER.slice(7):
  check(Game.select_level(id),"Global selection reaches "+id)
  Game.start()
  Game.enemies_destroyed=Campaign.target(id); Game.boss_defeated=true
  Game.mission_damage=0; Game.mission_elapsed=Campaign.par_time(id)
  var coins_before := Game.coins
  Game.complete_mission()
  check(Game.best_stars(id)==3 and Game.coins==coins_before+460+10*Campaign.index(id),"Stars and first-clear coins "+id)
  var next: String = Campaign.ORDER[mini(Campaign.index(id)+1,14)]
  check(Game.is_level_unlocked(next) and Game.map_focus_planet==next,"Camera target and unlock "+id)
  Game._load_save()
  check(Game.best_stars(id)==3 and Game.owned_ships.has("titan") and Game.owned_weapons.has("plasma"),"Isolated reload preserves progression and equipment")
 levels.free()
 levels=load("res://scenes/level_select.tscn").instantiate()
 get_tree().root.add_child(levels)
 await get_tree().create_timer(0.8).timeout
 check(levels._selected=="dark_void" and levels.cards.dark_void.selected,"Reopened map prioritizes latest mission")
 await capture("advanced")
 levels._focus_planet("cyber",false); levels._select("cyber")
 check(not levels._deploy.disabled,"Completed planets remain playable")
 for viewport_size in [Vector2(960,540),Vector2(1280,720),Vector2(1560,720),Vector2(1920,1080)]:
  levels._layout(Rect2(Vector2(30,10),viewport_size-Vector2(60,20)))
  check(not levels._map_view.get_global_rect().intersects(levels._briefing.get_global_rect()),"Map avoids briefing "+str(viewport_size))
  for id: String in Campaign.ORDER:
   levels._focus_planet(id,false)
   check(levels._map_view.get_global_rect().encloses(levels.cards[id].get_global_rect()),"Every planet can be centered "+id)
 levels.free()
 # Run a gameplay completion and wait for the automatic results-to-map transition.
 for id: String in Campaign.ORDER.slice(0,8): Game.completed_levels[id]=3
 Game.completed_levels.erase("lava")
 Game.selected_map_id="lava"
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene); get_tree().current_scene=scene
 Game.start(); Game.enemies_destroyed=Campaign.target("lava"); Game.boss_defeated=true
 Game.mission_damage=0; Game.mission_elapsed=0
 Game.complete_mission()
 check(scene.hud._next_level.visible and not scene.hud._next_level.disabled,"Advanced results offer next mission")
 await get_tree().create_timer(4.8).timeout
 check(get_tree().current_scene is LevelSelect,"Three-star results return automatically to the continuous map")
 if get_tree().current_scene is LevelSelect:
  check(get_tree().current_scene._selected=="ice","Automatic return highlights next advanced mission")
 SoundEffects.stop_all()
 print("CONTINUOUS PLANET MAP: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
