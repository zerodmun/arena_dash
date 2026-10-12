extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message); push_error(message)
func settle(name: String) -> void:
 await get_tree().create_timer(0.35).timeout
 for i in 3: await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://qa/landscape_"+name+".png")
func bounds(control: Control,message: String) -> void:
 var rect:=control.get_global_rect()
 var vp:=get_viewport().get_visible_rect()
 check(vp.grow(1).encloses(rect),message+" fits landscape canvas "+str(rect))
func controls_inside(root: Control) -> void:
 for child in root.find_children("*","Button",true,false):
  if child.is_visible_in_tree():
   check(root.get_global_rect().grow(1).encloses(child.get_global_rect()),"Dialog button fits: "+child.text)
   check(child.size.y>=64,"Dialog touch target: "+child.text)
   check(child.alignment==HORIZONTAL_ALIGNMENT_CENTER and child.vertical_icon_alignment==VERTICAL_ALIGNMENT_CENTER,"Centered button content")
   for state in ["normal","hover","pressed","disabled","focus"]:
    var style:=child.get_theme_stylebox(state) as StyleBoxTexture
    check(style!=null,"Button uses rounded shared artwork")
    if style:
     check(style.texture.resource_path.begins_with(ArcadeUI.BUTTON_ART),"Consistent rounded face, border and state artwork")
     check(style.texture_margin_left==32 and style.texture_margin_top==30,"Capsule corners are preserved by nine-slicing")
     check(style.content_margin_top==style.content_margin_bottom,"Balanced vertical button padding")
     var icon_space:=40 if child.icon and not child.text.is_empty() else 0
     check(style.content_margin_right-style.content_margin_left==icon_space,"Icon reservation balances label at the button center")
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 for id: String in Game.SHIPS: Game.owned_ships[id]=true
 for id: String in Game.WEAPONS: Game.owned_weapons[id]=true
 check(ProjectSettings.get_setting("display/window/handheld/orientation")==DisplayServer.SCREEN_LANDSCAPE,"Native mobile orientation is fixed landscape")
 Game.save_path="res://qa/landscape-test-save.cfg"
 Game.completed_levels={}
 Game.last_completed_planet=""
 Game.selected_map_id="cyber"
 var original_audio:=Game.audio_enabled
 var original_motion:=Game.reduced_motion
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1440,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(960,540),Vector2i(720,1280)]:
  get_tree().root.size=resolution
  await get_tree().process_frame
  Game._update_device_detection()
  var suffix:="%dx%d" % [resolution.x,resolution.y]
  check(get_viewport().get_visible_rect().size.x>get_viewport().get_visible_rect().size.y,"Landscape canvas at "+suffix)
  var menu: Control=load("res://scenes/menu.tscn").instantiate()
  get_tree().root.add_child(menu)
  await settle("menu_"+suffix)
  bounds(menu._actions,"Menu actions")
  var vp:=get_viewport().get_visible_rect().size
  var safe:=ArcadeUI.map_safe_rect(Rect2(48,12,resolution.x-80,resolution.y-28),Vector2(resolution),vp) if resolution.x>resolution.y else Rect2(Vector2(48,12),vp-Vector2(80,28))
  menu._layout(safe)
  check(safe.encloses(menu._actions.get_global_rect()),"Home respects cutouts")
  check(not menu._hero.get_global_rect().intersects(menu._actions.get_global_rect()),"Home ship and actions remain separate")
  menu._layout()
  var dialog:=ArcadeUI.settings(menu)
  await settle("settings_"+suffix)
  bounds(dialog.panel,"Settings")
  dialog._layout(safe)
  check(safe.encloses(dialog.panel.get_global_rect()),"Settings respects cutouts")
  dialog._layout()
  var editor:=ControlLayoutEditor.new()
  dialog.add_child(editor)
  for frame in 4: await get_tree().process_frame
  editor._layout(safe)
  for frame in 2: await get_tree().process_frame
  check(safe.encloses(editor.panel.get_global_rect()),"Control editor respects cutouts")
  controls_inside(editor.panel)
  editor.cancel()
  await get_tree().process_frame
  controls_inside(dialog.panel)
  dialog.audio.pressed.emit()
  check(Game.audio_enabled!=original_audio,"Sound setting toggles")
  dialog.motion.pressed.emit()
  check(Game.reduced_motion!=original_motion,"Motion setting toggles")
  Game._load_save()
  check(Game.audio_enabled!=original_audio and Game.reduced_motion!=original_motion,"Settings persisted")
  dialog.audio.pressed.emit()
  dialog.motion.pressed.emit()
  dialog.close_button.pressed.emit()
  await get_tree().process_frame
  check(not get_tree().paused,"Settings closes without pausing menu")
  menu.free()
  var hangar: Hangar=load("res://scenes/hangar.tscn").instantiate()
  get_tree().root.add_child(hangar)
  get_tree().current_scene=hangar
  await settle("hangar_"+suffix)
  for c in [hangar._launch,hangar._identity,hangar._stats_panel,hangar._weapon_card,hangar._map_card,hangar._hero,hangar._prev,hangar._next]: bounds(c,"Hangar control")
  check(not hangar._launch.get_global_rect().intersects(hangar._hero.get_global_rect()),"Deployment and ship stage are separate")
  check(hangar.find_children("*","ScrollContainer",true,false).is_empty(),"Hangar has no bottom thumbnail list")
  var selected:=Game.selected_ship_id
  var preview_index:=hangar._ship_index
  var reached: Dictionary={}
  for ship in Game.SHIPS.size():
   hangar._next.pressed.emit()
   reached[Game.SHIPS.keys()[hangar._ship_index]]=true
  check(reached.size()==Game.SHIPS.size() and hangar._ship_index==preview_index and Game.selected_ship_id==selected,"Arrow preview reaches every ship and wraps without equipping")
  var key:=InputEventKey.new()
  key.pressed=true
  key.keycode=KEY_D
  hangar._unhandled_input(key)
  check(hangar._ship_index!=preview_index and Game.selected_ship_id==selected,"Keyboard ship preview remains available without equipping")
  hangar._drag_start=Vector2(300,200)
  hangar._dragging=true
  hangar._finish_swipe(Vector2(400,200))
  check(hangar._ship_index==preview_index and Game.selected_ship_id==selected,"Swipe preview returns without equipping")
  hangar._adapt_layout(safe)
  for c in [hangar._launch,hangar._identity,hangar._hero,hangar._prev,hangar._next]: check(safe.encloses(c.get_global_rect()),"Hangar respects cutouts")
  hangar._adapt_layout()
  hangar._open_popup("weapon")
  await settle("loadout_"+suffix)
  bounds(hangar._modal,"Loadout")
  hangar._layout_popup(safe)
  check(safe.encloses(hangar._modal.get_global_rect()),"Weapon dialog respects cutouts")
  hangar._layout_popup()
  controls_inside(hangar._modal)
  for id: String in Game.WEAPONS:
   hangar._popup_buttons[id].pressed.emit()
   check(hangar._preview.weapon_id==id,"Weapon browsing updates live preview without purchasing")
  hangar._confirm_button.pressed.emit()
  check(not hangar._overlay.visible,"Confirm closes loadout")
  dialog=ArcadeUI.help(hangar)
  await settle("help_"+suffix)
  bounds(dialog.panel,"Help")
  controls_inside(dialog.panel)
  var escape:=InputEventKey.new()
  escape.keycode=KEY_ESCAPE
  escape.pressed=true
  Input.parse_input_event(escape)
  for frame in 3: await get_tree().process_frame
  check(not hangar.has_node("FlightDialog"),"Escape closes manual without launching")
  hangar.free()
  var campaign: LevelSelect=load("res://scenes/level_select.tscn").instantiate()
  get_tree().root.add_child(campaign)
  await settle("campaign_"+suffix)
  bounds(campaign._briefing,"Campaign briefing")
  campaign._layout(safe)
  check(safe.encloses(campaign._briefing.get_global_rect()),"Campaign respects cutouts")
  for planet: PlanetButton in campaign.cards.values():
   if planet.visible:check(safe.encloses(planet.get_global_rect()),"Planet stays clear of cutouts")
  campaign._layout()
  for planet: PlanetButton in campaign.cards.values():
   if planet.visible:bounds(planet,"Campaign planet")
  campaign._select("toxic")
  check(campaign._deploy.disabled,"Locked world cannot deploy")
  campaign.free()
  Game.set_mobile_ui(true)
  var scene: Node2D=load("res://scenes/main.tscn").instantiate()
  get_tree().root.add_child(scene)
  get_tree().current_scene=scene
  scene.player.set_physics_process(false)
  await settle("hud_"+suffix)
  var hud: HUD=scene.hud
  bounds(hud.fire_button,"Touch fire")
  hud._on_fire_down()
  check(Input.is_action_pressed("fire"),"Touch fire works")
  hud._toggle_pause()
  check(not Input.is_action_pressed("fire") and not hud.joystick.pressed,"Pause resets touch input")
  await settle("pause_"+suffix)
  bounds(hud._pause_panel,"Pause")
  hud._layout_safe_ui(safe)
  check(safe.encloses(hud._pause_panel.get_global_rect()),"Pause respects cutouts")
  hud._apply_touch_layout()
  controls_inside(hud._pause_panel)
  dialog=ArcadeUI.settings(hud)
  await settle("paused_settings_"+suffix)
  bounds(dialog.panel,"Paused settings")
  dialog.close()
  await get_tree().process_frame
  check(get_tree().paused and hud._pause_panel.visible,"Closing settings preserves pause")
  hud._resume.pressed.emit()
  check(not get_tree().paused,"Resume button works")
  Game.lives=1
  Game.take_damage()
  await settle("defeat_"+suffix)
  var modal: PanelContainer=hud.game_over_panel.get_node("CenterContainer/Modal")
  bounds(modal,"Defeat")
  hud._layout_safe_ui(safe)
  for frame in 2: await get_tree().process_frame
  check(safe.encloses(modal.get_global_rect()),"Result dialog respects cutouts")
  hud._apply_touch_layout()
  controls_inside(modal)
  hud.restart_button.pressed.emit()
  check(Game.is_running and not hud.game_over_panel.visible,"Retry works")
  for kill in Campaign.target("cyber"): Game.record_enemy_kill()
  await settle("victory_"+suffix)
  bounds(modal,"Victory")
  controls_inside(modal)
  check(hud._next_level.visible and Game.is_level_unlocked("forest"),"Victory offers next planet")
  scene.free()
  Game.completed_levels={}
  Game.last_completed_planet=""
  await get_tree().process_frame
 Game.audio_enabled=original_audio
 Game.reduced_motion=original_motion
 Game.is_running=false
 SoundEffects.stop_all()
 print("LANDSCAPE UI: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 await get_tree().create_timer(0.2).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
