extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message);push_error(message)
func settle(name: String) -> void:
 await get_tree().create_timer(0.3).timeout
 for i in 4: await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://build/l10n_"+name+".png")
func bounds(control: Control,message: String) -> void:
 check(get_viewport().get_visible_rect().grow(1).encloses(control.get_global_rect()),message+" / "+str(control.get_global_rect()))
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://build/localization-controls-test.cfg"
 Game.completed_levels={}
 Game.last_completed_planet=""
 Game.selected_map_id="cyber"
 Game.control_layout=TouchLayout.defaults()
 check(I18n.catalogs.en.keys().size()==I18n.catalogs.id.keys().size(),"Translation key parity")
 for key: String in I18n.catalogs.en:
  check(I18n.catalogs.id.has(key) and not I18n.catalogs.id[key].is_empty(),"Translation coverage "+key)
 I18n.set_language("id")
 Game._load_save()
 check(I18n.language=="id","Language preference restored")
 for resolution in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(960,540)]:
  get_tree().root.size=resolution
  await get_tree().process_frame
  Game._update_device_detection()
  for locale in ["en","id"]:
   I18n.set_language(locale)
   Game.completed_levels={}
   var suffix:="%s_%dx%d" % [locale,resolution.x,resolution.y]
   var menu: Control=load("res://scenes/menu.tscn").instantiate()
   get_tree().root.add_child(menu)
   await settle("menu_"+suffix)
   bounds(menu._actions,"Menu bounds")
   var dialog:=ArcadeUI.settings(menu)
   await settle("settings_"+suffix)
   bounds(dialog.panel,"Settings bounds")
   for category in ["LANGUAGE","AUDIO","GRAPHICS","CONTROLS"]:
    dialog._show_category(category)
    await settle("settings_"+category+"_"+suffix)
    bounds(dialog.panel,"Category bounds "+category)
   dialog._show_category("GENERAL")
   var editor:=dialog.open_editor()
   await settle("editor_"+suffix)
   bounds(editor.panel,"Editor bounds")
   check(not Input.is_action_pressed("fire"),"Preview does not fire")
   var original: Dictionary=Game.control_layout.duplicate(true)
   editor._drag("fire",editor.preview.get_global_transform()*(editor.preview.size*Vector2(0.68,0.62)))
   check(editor.draft.fire.position!=original.fire.position,"Fire drag updates draft")
   editor._select("joystick")
   editor.size_slider.value=120
   editor.opacity_slider.value=55
   check(is_equal_approx(editor.draft.joystick.size,1.2) and is_equal_approx(editor.draft.joystick.opacity,0.55),"Independent size/opacity")
   var blocked: Vector2=editor.draft.fire.position
   var joy_center: Vector2=TouchLayout.resolved(editor.draft,editor.preview.size).joystick.center
   editor._drag("fire",editor.preview.get_global_transform()*joy_center)
   check(editor.draft.fire.position==blocked,"Overlap rejected")
   editor._drag("fire",editor.preview.get_global_transform()*Vector2(-200,-200))
   var clipped: Dictionary=TouchLayout.resolved(editor.draft,editor.preview.size).fire
   check(TouchLayout.safe_area(editor.preview.size).grow(0.1).encloses(Rect2(clipped.center-Vector2.ONE*clipped.diameter*0.5,Vector2.ONE*clipped.diameter)),"Safe-area clamp")
   editor.cancel()
   for i in 3: await get_tree().process_frame
   check(Game.control_layout==original,"Cancel does not save")
   editor=dialog.open_editor()
   await settle("editor_save_"+suffix)
   editor._drag("fire",editor.preview.get_global_transform()*(editor.preview.size*Vector2(0.7,0.68)))
   editor._select("fire")
   editor.size_slider.value=110
   editor.opacity_slider.value=60
   editor.save()
   for i in 3: await get_tree().process_frame
   var saved: Dictionary=Game.control_layout.duplicate(true)
   Game.control_layout=TouchLayout.defaults()
   Game._load_save()
   check(Game.control_layout==saved,"Layout survives restart")
   I18n.set_language("id" if locale=="en" else "en")
   check(TranslationServer.translate("SETTINGS")==I18n.t("SETTINGS"),"Instant engine translation")
   I18n.set_language(locale)
   dialog.close()
   for i in 3: await get_tree().process_frame
   menu.free()
   var hangar: Hangar=load("res://scenes/hangar.tscn").instantiate()
   get_tree().root.add_child(hangar)
   await settle("hangar_"+suffix)
   check(hangar._ship_class.text==I18n.t(Game.get_current_ship()["class"]),"Aircraft classification localized")
   hangar._open_popup("weapon")
   await settle("weapon_"+suffix)
   bounds(hangar._modal,"Weapon bounds")
   hangar.free()
   var levels: LevelSelect=load("res://scenes/level_select.tscn").instantiate()
   get_tree().root.add_child(levels)
   await settle("campaign_"+suffix)
   levels._select("toxic")
   check(levels._detail.text.contains(I18n.t("Earn 3 stars on %s to unlock this orbit.",[Game.MAPS.glacier.name])),"Locked mission translated")
   levels.free()
   Game.set_mobile_ui(true)
   var scene: Node2D=load("res://scenes/main.tscn").instantiate()
   get_tree().root.add_child(scene)
   get_tree().current_scene=scene
   scene.player.set_physics_process(false)
   await settle("flight_"+suffix)
   var hud: HUD=scene.hud
   var resolved:=TouchLayout.resolved(saved,get_viewport().get_visible_rect().size)
   check(hud.fire_button.position.is_equal_approx(resolved.fire.center-hud.fire_button.size*0.5),"Saved fire position applied")
   check(is_equal_approx(hud.fire_button.modulate.a,0.6),"Saved opacity applied")
   bounds(hud.fire_button,"Customized Fire bounds")
   # Independent fingers: moving index 3 and firing index 8 at the same time.
   var move:=InputEventScreenTouch.new();move.index=3;move.pressed=true;move.position=hud.joystick.size*0.5
   hud.joystick._gui_input(move)
   var drag:=InputEventScreenDrag.new();drag.index=3;drag.position=hud.joystick.size*0.5+Vector2(30,0)
   hud.joystick._gui_input(drag)
   var fire:=InputEventScreenTouch.new();fire.index=8;fire.pressed=true;fire.position=hud.fire_button.size*0.5
   hud.fire_button._gui_input(fire)
   check(hud.joystick.pressed and hud.joystick.output.x>0 and Input.is_action_pressed("fire"),"Simultaneous joystick and fire")
   var release:=InputEventScreenTouch.new();release.index=8;release.pressed=false
   hud.fire_button._input(release)
   check(not Input.is_action_pressed("fire") and hud.joystick.pressed,"Fire release does not cancel movement")
   hud._toggle_pause()
   check(not hud.joystick.pressed,"Pause resets customized joystick")
   await settle("pause_"+suffix)
   hud._toggle_pause()
   Game.lives=1;Game.take_damage()
   await settle("defeat_"+suffix)
   check(hud.final_score_label.text==I18n.t("Final Score: %d",[Game.score]),"Localized defeat score")
   hud._on_start_pressed()
   for i in Campaign.target("cyber"): Game.record_enemy_kill()
   await settle("victory_"+suffix)
   scene.free()
   Game.is_running=false
   Game.control_layout=TouchLayout.defaults()
 # Corrupt or old preferences must not produce invalid geometry.
 var sanitized:=TouchLayout.sanitize({"fire":{"position":Vector2(INF,NAN),"size":999,"opacity":-3}})
 check(sanitized.fire.size==1.4 and sanitized.fire.opacity==0.35 and sanitized.fire.position.is_finite(),"Corrupt preference validation")
 Game.is_running=false
 var parent:=Control.new();get_tree().root.add_child(parent)
 var settings:=ArcadeUI.settings(parent)
 var reset_editor:=settings.open_editor()
 await settle("reset")
 reset_editor.draft.fire.size=1.4
 reset_editor.reset_defaults()
 check(reset_editor.draft==TouchLayout.defaults(),"Reset restores defaults")
 reset_editor.save()
 for i in 3: await get_tree().process_frame
 settings.close()
 for i in 3: await get_tree().process_frame
 parent.free()
 check(Game.control_layout==TouchLayout.defaults(),"Reset persists when saved")
 SoundEffects.stop_all()
 print("LOCALIZATION + CONTROLS: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 await get_tree().create_timer(0.2).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
