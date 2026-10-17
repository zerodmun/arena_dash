extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func settle() -> void:
 await get_tree().create_timer(0.32).timeout
func back() -> void:
 Navigation.request_back()
 await settle()
func run() -> void:
 Game.save_path="res://qa/back-navigation-save.cfg"
 var runner:=self
 get_tree().current_scene=null
 Navigation.go_to(Navigation.HOME)
 await settle()
 check(not get_tree().quit_on_go_back,"Android automatic quitting disabled")
 Navigation.go_to("res://scenes/hangar.tscn")
 await settle()
 Navigation.go_to("res://scenes/level_select.tscn")
 await settle()
 check(Navigation.history==[Navigation.HOME,"res://scenes/hangar.tscn"],"Nested scene history")
 await back()
 check(Navigation._current=="res://scenes/hangar.tscn","Map returns to actual Hangar")
 var hangar:=get_tree().current_scene
 hangar._open_popup("weapon")
 await back()
 check(not hangar._overlay.visible and Navigation._current==hangar.scene_file_path,"Weapon/shop popup closes first")
 var dialog:=ArcadeUI.settings(hangar)
 await settle()
 dialog._show_category("DISPLAY")
 dialog._display_section="GAMEPLAY"
 dialog._show_category("DISPLAY")
 var editor:=dialog.open_editor()
 await settle()
 var layout:=Game.control_layout.duplicate(true)
 editor.draft.joystick.opacity=0.2
 await back()
 check(not is_instance_valid(editor) and is_instance_valid(dialog),"Topmost editor closes before settings")
 check(Game.control_layout==layout,"Back discards only unsaved control draft")
 await back()
 check(dialog._display_section.is_empty(),"Nested settings returns to Display")
 var cancel:=InputEventAction.new()
 cancel.action="ui_cancel"
 cancel.pressed=true
 Input.parse_input_event(cancel)
 await settle()
 check(not is_instance_valid(dialog),"ui_cancel closes settings to owning screen")
 var escape:=InputEventKey.new()
 escape.pressed=true
 escape.keycode=KEY_ESCAPE
 Input.parse_input_event(escape)
 await settle()
 check(Navigation._current==Navigation.HOME and Navigation.history.is_empty(),"Escape returns Home and clears history")
 await back()
 check(is_instance_valid(Navigation._toast) and Navigation._exit_deadline>0,"First Home Back shows warning")
 I18n.set_language("id",false)
 check(I18n.t("Swipe back again to exit")=="Geser kembali sekali lagi untuk keluar","Indonesian warning")
 await get_tree().create_timer(2.05).timeout
 check(Navigation._exit_deadline==0 and not is_instance_valid(Navigation._toast),"Exit window expires")
 Navigation.go_to("res://scenes/level_select.tscn")
 await settle()
 Navigation.request_back()
 Navigation.request_back()
 await settle()
 check(Navigation._current==Navigation.HOME and Navigation._exit_deadline==0,"Repeated Back does not reach exit warning")
 Navigation.go_to("res://scenes/hangar.tscn")
 await settle()
 Navigation.go_to(Navigation.PLAY)
 await settle()
 var hud:=get_tree().current_scene.get_node("HUD")
 await back()
 check(get_tree().paused,"Gameplay Back pauses")
 dialog=ArcadeUI.settings(hud)
 await settle()
 await back()
 check(get_tree().paused,"Closing pause settings retains pause")
 await back()
 check(not get_tree().paused,"Pause Back resumes")
 for rating in [2,3]:
  if rating==3:
   Navigation.go_to(Navigation.PLAY)
   await settle()
   hud=get_tree().current_scene.get_node("HUD")
  Game.enemies_destroyed=Campaign.target(Game.selected_map_id)
  Game.boss_defeated=true
  Game.mission_damage=0 if rating==3 else 999
  Game.mission_elapsed=10.0
  Game.complete_mission()
  var coins:=Game.coins
  var stars:=Game.best_stars(Game.selected_map_id)
  check(hud.game_over_panel.visible,"Real completion displays results")
  await back()
  check(Navigation._current=="res://scenes/hangar.tscn" and Game.coins==coins,"Result Back preserves rewards and launch screen")
  var saved:=ConfigFile.new()
  check(saved.load(Game.save_path)==OK,"Rewards saved before navigation")
  check(int(saved.get_value("economy","coins",-1))==coins and Game.best_stars(Game.selected_map_id)==stars,"Saved coins and mission stars survive result Back")
 # External direct scene replacement is tracked without keeping freed nodes.
 get_tree().change_scene_to_file("res://scenes/level_select.tscn")
 await settle()
 check(Navigation.history==[Navigation.HOME,"res://scenes/hangar.tscn"],"External scene replacement history")
 Navigation.go_to("res://scenes/hangar.tscn")
 await settle()
 check(Navigation.history==[Navigation.HOME],"Returning to visited scene removes cycles")
 print("BACK NAVIGATION: ","PASS" if failures.is_empty() else failures)
 SoundEffects.stop_all()
 await get_tree().process_frame
 runner.get_tree().quit(0 if failures.is_empty() else 1)
func _ready() -> void:
 run.call_deferred()
