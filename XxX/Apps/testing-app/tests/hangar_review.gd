extends Node
var failures: Array[String] = []
func _ready() -> void:
 call_deferred("_review")
func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  push_error(message)
func _capture(name: String) -> void:
 await get_tree().create_timer(0.35).timeout
 for i in 4: await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://build/" + name + ".png")
func _review() -> void:
 Game.save_path = "res://build/ui-test-save.cfg"
 Game.completed_levels = {}
 Game.selected_map_id = "cyber"
 var menu: Control = load("res://scenes/menu.tscn").instantiate()
 get_tree().root.add_child(menu)
 await _capture("review_menu")
 menu.free()
 for resolution in [Vector2i(1920,1080), Vector2i(1280,720), Vector2i(1600,720), Vector2i(720,1280)]:
  get_tree().root.size = resolution
  await get_tree().process_frame
  Game._update_device_detection()
  var hangar: Hangar = load("res://scenes/hangar.tscn").instantiate()
  get_tree().root.add_child(hangar)
  get_tree().current_scene = hangar
  await _capture("review_hangar_%dx%d" % [resolution.x,resolution.y])
  for id: String in Game.SHIPS:
   hangar._select_ship(id)
   check(hangar._ship_image.texture.resource_path == Game.SHIPS[id].texture, "Selectable aircraft " + id)
  check(hangar._launch.get_global_rect().end.x <= hangar.size.x, "Launch in viewport")
  check(not hangar._launch.get_global_rect().intersects(hangar._roster_scroll.get_global_rect()), "Roster does not overlap launch")
  hangar._open_popup("weapon")
  for id: String in Game.WEAPONS:
   hangar._choose_popup_option(id)
   check(hangar._preview.weapon_id == id, "Live weapon preview " + id)
  await _capture("review_weapons_%dx%d" % [resolution.x,resolution.y])
  hangar._close_popup()
  check(not hangar._overlay.visible, "Weapon dialog closes")
  hangar.free()
  var levels: LevelSelect = load("res://scenes/level_select.tscn").instantiate()
  get_tree().root.add_child(levels)
  await _capture("review_campaign_%dx%d" % [resolution.x,resolution.y])
  check(levels.cards.size() == 8, "All eight planet cards")
  check(not levels.cards.cyber._has_point(Vector2.ZERO), "Planet corners do not accept clicks")
  check(levels.cards.cyber._has_point(levels.cards.cyber.size*0.5), "Planet center accepts clicks")
  levels._select("toxic")
  check(levels._deploy.disabled, "Locked node cannot deploy")
  levels._select("cyber")
  check(not levels._deploy.disabled, "Unlocked node can deploy")
  levels.free()
 get_tree().root.size = Vector2i(1920,1080)
 await get_tree().process_frame
 Game._update_device_detection()
 Game.set_mobile_ui(false)
 for map: String in Campaign.ORDER:
  Game.selected_map_id = map
  var scene: Node2D = load("res://scenes/main.tscn").instantiate()
  get_tree().root.add_child(scene)
  get_tree().current_scene = scene
  scene.player.set_physics_process(false)
  scene.player.sprite.visible = true
  await _capture("review_combat_" + map)
  scene.hud._toggle_pause()
  check(get_tree().paused, "Pause")
  await _capture("review_pause")
  scene.hud._toggle_pause()
  for i in Campaign.target(map): Game.record_enemy_kill()
  if Campaign.has_boss(map): Game.record_boss_defeat()
  await _capture("review_victory_" + map)
  scene.hud._on_start_pressed()
  Game.lives = 1
  Game.take_damage()
  await _capture("review_defeat")
  scene.free()
 get_tree().root.size = Vector2i(1280,720)
 await get_tree().process_frame
 Game._update_device_detection()
 Game.set_mobile_ui(true)
 Game.selected_map_id = "coast"
 var mobile: Node2D = load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(mobile)
 get_tree().current_scene = mobile
 await _capture("review_mobile_combat")
 check(mobile.hud.fire_button.visible and mobile.hud.joystick.visible, "Mobile controls available")
 mobile.hud._on_fire_down()
 check(Input.is_action_pressed("fire"), "Touch fire starts shooting")
 mobile.hud._on_fire_up()
 check(not Input.is_action_pressed("fire"), "Touch fire releases shooting")
 mobile.hud._toggle_pause()
 check(not mobile.hud.joystick.pressed and mobile.hud.fire_button.disabled, "Pause resets touch controls")
 mobile.hud._toggle_pause()
 mobile.free()
 print("HANGAR REVIEW: ", "PASS" if failures.is_empty() else "FAIL", " / ", failures.size(), " failures")
 SoundEffects.stop_all()
 await get_tree().create_timer(0.2).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
