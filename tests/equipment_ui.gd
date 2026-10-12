extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("review")
func capture(name: String) -> void:
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  await get_tree().create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://qa/equipment-qa/"+name+".png")
func review() -> void:
 Game.save_path=("user://equipment-ui-review.cfg" if OS.get_name()=="Android" else "res://qa/equipment-ui-review.cfg")
 for width in [1280,1440,1560,1600]:
  get_tree().root.size=Vector2i(width,720)
  for frame in 3:await get_tree().process_frame
  for lang in ["en","id"]:
   Game._load_economy(ConfigFile.new(),false)
   Game.selected_ship_id="valkyrie";Game.selected_weapon_id="plasma"
   I18n.set_language(lang,false)
   var h: Hangar=load("res://scenes/hangar.tscn").instantiate()
   get_tree().root.add_child(h);get_tree().current_scene=h
   h._select_ship("chronos")
   for frame in 3:await get_tree().process_frame
   check(h._purchase.icon!=null and h._launch.disabled,"Locked aircraft has lock badge and cannot deploy")
   h._purchase.pressed.emit()
   check(Game.coins==0 and not Game.owns_equipment("ship","chronos"),"Insufficient UI purchase does not debit or unlock")
   await capture("locked_%d_%s" % [width,lang])
   Game.coins=2000;h._refresh()
   h._purchase.pressed.emit()
   check(Game.coins==600 and Game.owns_equipment("ship","chronos") and Game.selected_ship_id=="valkyrie","UI purchase unlocks exactly once without silently equipping")
   for frame in 3:await get_tree().process_frame
   check(h._purchase.text==I18n.t("SELECT AIRCRAFT") and not h._launch.disabled,"Purchase changes to Select; owned aircraft can deploy")
   h._purchase.pressed.emit()
   check(Game.selected_ship_id=="chronos" and Game.coins==600 and h._purchase.disabled,"Select equips without another deduction")
   await capture("owned_%d_%s" % [width,lang])
   # Fund the weapon purchase separately: Nova Burst's current price exceeds
   # the 600 coins remaining after the aircraft purchase.
   Game.coins=Game.equipment_price("weapon","nova_burst")
   h._open_popup("weapon")
   for frame in 3:await get_tree().process_frame
   h._choose_popup_option("nova_burst")
   check(h._popup_buttons.nova_burst.icon!=null,"Locked weapon has lock badge")
   await capture("weapon_locked_%d_%s" % [width,lang])
   h._confirm_button.pressed.emit()
   check(Game.coins==0 and Game.owns_equipment("weapon","nova_burst") and Game.selected_weapon_id=="plasma","Weapon purchase deducts exact price and retains current equipment")
   check(h._overlay.visible and h._confirm_button.text==I18n.t("EQUIP WEAPON"),"Purchase changes to Equip")
   h._confirm_button.pressed.emit()
   check(Game.selected_weapon_id=="nova_burst" and not h._overlay.visible,"Weapon equips and dialog closes")
   Game._load_save()
   check(Game.coins==0 and Game.selected_ship_id=="chronos" and Game.selected_weapon_id=="nova_burst","Purchased UI configuration persists")
   h._open_popup("weapon")
   for frame in 3:await get_tree().process_frame
   var safe:=ArcadeUI.safe_rect(get_viewport().get_visible_rect().size)
   check(safe.encloses(h._modal.get_global_rect()),"Six-weapon editor fits landscape")
   for b: Button in h._popup_buttons.values():
    check(h._modal.get_global_rect().encloses(b.get_global_rect()),"All weapon option buttons remain inside modal")
    for line in b.text.split("\n"):
     var required:=b.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x+32+(84 if b.icon else 0)
     check(required<=b.size.x,"Localized weapon name/state fits its button")
   h._close_popup();h.queue_free()
   for frame in 3:await get_tree().process_frame
 SoundEffects.stop_all()
 print("EQUIPMENT UI: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
