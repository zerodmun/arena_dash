extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message); push_error(message)
func settle(name: String) -> void:
 await get_tree().create_timer(0.35).timeout
 for i in 3: await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://build/landscape_"+name+".png")
func bounds(control: Control,message: String) -> void:
 var rect:=control.get_global_rect()
 var vp:=get_viewport().get_visible_rect()
 check(vp.grow(1).encloses(rect),message+" fits landscape canvas "+str(rect))
func controls_inside(root: Control) -> void:
 for child in root.find_children("*","Button",true,false):
  if child.is_visible_in_tree():
   check(root.get_global_rect().grow(1).encloses(child.get_global_rect()),"Dialog button fits: "+child.text)
   check(child.size.y>=64,"Dialog touch target: "+child.text)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 Game.save_path="res://build/landscape-test-save.cfg"
 Game.completed_levels={}
 Game.last_completed_planet=""
 Game.selected_map_id="cyber"
 var original_audio:=Game.audio_enabled
 var original_motion:=Game.reduced_motion
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1600,720),Vector2i(960,540),Vector2i(720,1280)]:
  get_tree().root.size=resolution
  await get_tree().process_frame
  Game._update_device_detection()
  var suffix:="%dx%d" % [resolution.x,resolution.y]
  check(get_viewport().get_visible_rect().size.x>get_viewport().get_visible_rect().size.y,"Landscape canvas at "+suffix)
  var menu: Control=load("res://scenes/menu.tscn").instantiate()
  get_tree().root.add_child(menu)
  await settle("menu_"+suffix)
  bounds(menu._actions,"Menu actions")
  var dialog:=ArcadeUI.settings(menu)
  await settle("settings_"+suffix)
  bounds(dialog.panel,"Settings")
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
  for c in [hangar._launch,hangar._identity,hangar._stats_panel,hangar._weapon_card,hangar._map_card,hangar._roster_scroll]: bounds(c,"Hangar control")
  check(not hangar._launch.get_global_rect().intersects(hangar._roster_scroll.get_global_rect()),"Deployment and roster are separate")
  hangar._open_popup("weapon")
  await settle("loadout_"+suffix)
  bounds(hangar._modal,"Loadout")
  controls_inside(hangar._modal)
  for id: String in Game.WEAPONS:
   hangar._popup_buttons[id].pressed.emit()
   check(Game.selected_weapon_id==id and hangar._preview.weapon_id==id,"Weapon selection + preview")
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
  for planet: PlanetButton in campaign.cards.values(): bounds(planet,"Campaign planet")
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
