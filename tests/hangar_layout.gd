extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("review")
func review() -> void:
 Game.save_path="res://qa/hangar-layout-qa/test-save.cfg"
 for ship: String in Game.SHIPS:Game.owned_ships[ship]=true
 for weapon: String in Game.WEAPONS:Game.owned_weapons[weapon]=true
 var h: Hangar=load("res://scenes/hangar.tscn").instantiate()
 get_tree().root.add_child(h)
 get_tree().current_scene=h
 for dimensions in [Vector2i(1280,720),Vector2i(1440,720),Vector2i(1560,720),Vector2i(1600,720)]:
  get_tree().root.size=dimensions
  for frame in 3:await get_tree().process_frame
  for language in ["en","id"]:
   I18n.set_language(language,false)
   Game.coins=999999999;h._refresh()
   for frame in 3:await get_tree().process_frame
   var safe:=get_viewport().get_visible_rect().grow(-32)
   h._adapt_layout(safe)
   for frame in 3:await get_tree().process_frame
   var controls=[h._header,h._header_title,h._identity,h._stats_panel,h._weapon_card,h._hero,h._prev,h._next,h._counter,h._purchase,h._map_card,h._map_card_label,h._mission_label,h._launch]
   for c: Control in controls:check(safe.encloses(c.get_global_rect()),"Safe-area containment "+str(dimensions)+" "+language+" "+c.get_class())
   for i in controls.size():
    for j in range(i+1,controls.size()):check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"Major controls do not overlap: "+str(i)+" / "+str(j))
   check(is_equal_approx(h._hero.get_global_rect().get_center().x,safe.get_center().x),"Spaceship centered in usable viewport")
   check(is_equal_approx(h._weapon_card.position.y,h._launch.position.y),"Footer actions align")
   check(h._launch.size==Vector2(352,108),"Deploy remains prominent")
   check(h._coin_base.get_parent()==h._header and h._coin_base.get_theme_stylebox("panel") is StyleBoxTexture,"Wallet uses existing panel artwork")
   check(h._coin_base.get_global_rect().encloses(h._record.get_global_rect()),"Large balances fit their base")
   for b: Button in [h._prev,h._next,h._purchase,h._weapon_card,h._launch]:
    for state in ["normal","pressed","hover","focus","disabled"]:
     var face:=b.get_theme_stylebox(state) as StyleBoxTexture
     check(face!=null and face.texture.resource_path.begins_with(ArcadeUI.BUTTON_ART),"Existing rounded button system preserved")
   for weapon: String in Game.WEAPONS:
    Game.selected_weapon_id=weapon;h._refresh()
    for frame in 3:await get_tree().process_frame
    check(h._weapon_icon.texture.resource_path==Game.WEAPONS[weapon].texture,"Correct equipped weapon artwork: "+weapon)
    check(h._weapon_icon.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Weapon aspect ratio preserved")
    check(h._weapon_icon.size.y>=90,"Weapon uses full button height")
    check(h._weapon_card.get_global_rect().encloses(h._weapon_icon.get_global_rect()),"Artwork stays inside button")
    check(not h._weapon_icon.get_global_rect().intersects(h._weapon_card_label.get_global_rect()),"Weapon image and name do not overlap")
    check(h._weapon_card.get_global_rect().encloses(h._weapon_status.get_global_rect()),"Localized weapon status stays inside button")
    check(h._weapon_status.text==I18n.t("EQUIPPED"),"Equipped status localized")
   h._select_ship("valkyrie")
   for frame in 3:await get_tree().process_frame
   # Refresh reflows safely; explicitly reapply the synthetic insets afterward.
   h._adapt_layout(safe)
   if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
    await get_tree().create_timer(.3).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("res://qa/hangar-layout-qa/hangar_%dx%d_%s.png" % [dimensions.x,dimensions.y,language])
 Game.coins=460
 I18n.set_language("en",false)
 h._adapt_layout()
 for id: String in Game.SHIPS:
  h._select_ship(id)
  for frame in 3:await get_tree().process_frame
  for label: Label in [h._ship_name,h._ship_class,h._counter]:
   var text:=I18n.t(label.text)
   check(label.get_theme_font("font").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x<=label.size.x,"Aircraft label fits: "+id)
  if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
   await get_tree().create_timer(.3).timeout
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png("res://qa/hangar-layout-qa/aircraft_"+id+".png")
  check(h._ship_image.texture.resource_path==Game.SHIPS[id].texture,"Every aircraft preview remains selectable")
 h._open_popup("weapon")
 for frame in 3:await get_tree().process_frame
 for id: String in Game.WEAPONS:
  h._choose_popup_option(id)
  check(h._preview.weapon_id==id,"Weapon live preview remains functional")
 h._close_popup()
 check(not h._overlay.visible,"Loadout closes")
 h.queue_free()
 for frame in 3:await get_tree().process_frame
 SoundEffects.stop_all()
 print("HANGAR LAYOUT: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
