extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func _ready() -> void:call_deferred("review")
func review() -> void:
 Game.save_path="res://qa/coin-ui-test.cfg"
 Game._load_economy(ConfigFile.new(),false)
 Game.selected_ship_id="valkyrie";Game.selected_weapon_id="plasma"
 for locale in ["en","id"]:
  I18n.set_language(locale,false)
  for width in [1280,1440,1560,1600]:
   var h: Hangar=load("res://scenes/hangar.tscn").instantiate()
   get_tree().root.add_child(h)
   var safe:=Rect2(32,12,width-64,696)
   h._select_ship("titan")
   h._adapt_layout(safe)
   for i in 5:await get_tree().process_frame
   check(h._header_title.position.x==56,"Title aligns to safe content margin")
   check(safe.encloses(h._header.get_global_rect()),"Coin/nav row in safe area")
   check(safe.encloses(h._launch.get_global_rect()),"Unlock button safe")
   check(not h._launch.get_global_rect().intersects(h._mission_label.get_global_rect()),"Unlock has clear mission spacing")
   var font:=h._purchase.get_theme_font("font")
   for line in h._purchase.text.split("\n"):
    check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,h._purchase.get_theme_font_size("font_size")).x+48<=h._purchase.size.x,"Localized aircraft purchase text fits")
   check(Game.selected_ship_id=="valkyrie","Locked browsing does not equip")
   h._open_popup("weapon")
   h._choose_popup_option("quantum_spread")
   for i in 5:await get_tree().process_frame
   check(Game.selected_weapon_id=="plasma" and h._preview.weapon_id=="quantum_spread","Locked weapon preview is independent of equipped loadout")
   var btn:=h._confirm_button
   check(btn.get_theme_font("font").get_string_size(btn.text,HORIZONTAL_ALIGNMENT_LEFT,-1,btn.get_theme_font_size("font_size")).x+32<=btn.size.x,"Localized weapon purchase text fits")
   h._confirm_loadout()
   check(Game.coins==0 and Game.selected_weapon_id=="plasma" and h._overlay.visible,"Insufficient purchase stays in editor without debit")
   h._close_popup();h.free()
 print("COIN UI: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 SoundEffects.stop_all()
 await get_tree().create_timer(.2).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
