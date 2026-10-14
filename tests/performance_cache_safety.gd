extends Node
var failures: Array[String]=[]
func check(value: bool, message: String) -> void:
 if not value: failures.append(message);push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
 Game.save_path="res://qa/performance-audit/cache-safety.cfg"
 Game.completed_levels={}
 for id: String in Campaign.ORDER: Game.completed_levels[id]=3
 Game.selected_ship_id="valkyrie";Game.selected_weapon_id="plasma"
 var cache:=Game.warm_mission_assets("cyber")
 for id: String in Campaign.ORDER:
  check(await cache.wait_until_ready(id),"Mission textures load: "+id)
  check(cache.map_id==id and cache._pending.is_empty(),"Mission queue settles: "+id)
  check(cache.retained.size()<=12,"Only one bounded mission is retained: "+id)
  for texture in cache.retained.values(): check(texture is Texture2D,"Retained resources are textures")
 # Changing selection during a live request must retire old work and settle the latest.
 cache.warm("lava");cache.warm("ice");cache.warm("dark_void")
 check(await cache.wait_until_ready("dark_void"),"Rapid selection retires superseded requests")
 var data:=WeaponData.from_catalog("nova_burst")
 check(data==WeaponData.from_catalog("nova_burst"),"Catalog snapshots reuse validated data")
 check(data.pattern.is_read_only() and data.pattern[0].is_read_only(),"Cached firing pattern is immutable")
 check(data.pattern==EquipmentCatalog.firing_pattern(Game.WEAPONS.nova_burst),"Cached pattern exactly matches catalog")
 var map:LevelSelect=load("res://scenes/level_select.tscn").instantiate()
 get_tree().root.add_child(map)
 await get_tree().create_timer(0.8).timeout
 check(not map.is_processing(),"Settled map has no idle process callback")
 map._request_zoom(1.5,map._map_view.get_global_rect().get_center())
 check(map.is_processing(),"Zoom wakes map processing")
 await get_tree().create_timer(0.8).timeout
 check(not map.is_processing() and is_equal_approx(map._zoom,1.5),"Zoom settles and sleeps")
 map.free()
 # Exercise the actual asynchronous deployment path for every original and advanced level.
 var packed:PackedScene=load("res://scenes/hangar.tscn")
 for id: String in Campaign.ORDER:
  Game.selected_map_id=id
  var hangar:Hangar=packed.instantiate()
  get_tree().root.add_child(hangar);get_tree().current_scene=hangar
  await hangar._deploy()
  await get_tree().scene_changed
  var scene:=get_tree().current_scene
  check(scene.scene_file_path=="res://scenes/main.tscn" and Game.selected_map_id==id,"Real deployment: "+id)
  check(cache.map_id==id and cache._pending.is_empty(),"Deployment finishes texture queue: "+id)
  scene.enemy_spawner.set_physics_process(false)
  scene.pickup_spawner.set_physics_process(false)
  var effects:ImpactEffectManager=scene.get_node("ProjectileManager").effects
  effects.impact(999,Vector2(3400,2200),Color.CYAN)
  effects.impact(999,Vector2(3400,2200),Color.CYAN)
  check(effects.created==1,"Live impact receipt rejects duplicates")
  await get_tree().create_timer(1.2).timeout
  check(effects._receipts.is_empty(),"Completed effects release receipts")
  scene.free();Game.is_running=false
  await get_tree().process_frame
 SoundEffects.stop_all()
 await get_tree().create_timer(0.2).timeout
 print("PERFORMANCE CACHE SAFETY: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
