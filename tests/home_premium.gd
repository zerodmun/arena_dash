extends Node
var failures: Array[String]=[]
func check(ok: bool, message: String) -> void:
 if not ok:failures.append(message);push_error(message)
func _ready() -> void:run.call_deferred()
func run() -> void:
 Game.save_path=("user://home-premium-test.cfg" if OS.get_name()=="Android" else "res://qa/home-premium-test.cfg")
 var menu=load("res://scenes/menu.tscn").instantiate()
 get_tree().root.add_child(menu)
 for ship_id in Game.SHIPS:
  Game.owned_ships[ship_id]=true
  check(Game.select_ship(ship_id),"Select ship")
  check(menu._hero.texture.resource_path==Game.SHIPS[ship_id].texture,"Home follows selected artwork")
  check(menu._hero.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Home preserves proportions")
 var original:Vector2=menu._hero_base
 menu._process(1.0)
 check(menu._hero.position!=original,"Home floats")
 Game.reduced_motion=true;menu._process(.1)
 check(menu._hero.position==original,"Reduced motion respected")
 Game.reduced_motion=false
 Game._load_save()
 check(menu._hero.texture.resource_path==Game.get_current_ship().texture,"Saved aircraft restored")
 menu.queue_free()
 await get_tree().process_frame
 var h:Hangar=load("res://scenes/hangar.tscn").instantiate()
 get_tree().root.add_child(h)
 for language in ["en","id"]:
  I18n.set_language(language,false)
  for weapon_id in Game.WEAPONS:
   Game.selected_weapon_id=weapon_id;h._refresh()
   for i in 3:await get_tree().process_frame
   for frame in 3:await get_tree().process_frame
   var label:Label=h._weapon_card_label
   check(label.get_theme_font_size("font_size")>=16,"Readable weapon font")
   check(label.get_line_count()<=2 and h._weapon_card.get_global_rect().encloses(label.get_global_rect()),"Wrapped weapon label fits "+weapon_id+language)
   check(h._weapon_card.get_global_rect().encloses(label.get_global_rect()),"Label inside button")
 for id in ["plasma_lance","nova_burst"]:
  var w:Dictionary=Game.WEAPONS[id]
  var shots:=EquipmentCatalog.firing_pattern(w)
  check(shots.size()==(4 if id=="plasma_lance" else 5),"Premium projectile count")
  for i in shots.size():check(is_equal_approx(shots[i].angle,-shots[shots.size()-1-i].angle),"Symmetrical spread")
  check(EquipmentCatalog.firing_interval(Game.SHIPS.vortex,w)>=.24,"Premium firing bounded")
 check(Game.equipment_price("weapon","plasma_lance")==210*5,"Advanced price = five repeat first-world clears")
 check(Game.equipment_price("weapon","nova_burst")==210*8,"Elite price = eight repeat first-world clears")
 print("HOME_PREMIUM ",JSON.stringify({"failures":failures}))
 h.queue_free()
 for i in 3:await get_tree().process_frame
 get_tree().quit(0 if failures.is_empty() else 1)
