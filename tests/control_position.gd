extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message);push_error(message)
func touch(index: int,point: Vector2,down: bool) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=index;event.position=point;event.pressed=down
 get_viewport().push_input(event,true)
func drag(index: int,point: Vector2) -> void:
 var event:=InputEventScreenDrag.new()
 event.index=index;event.position=point
 get_viewport().push_input(event,true)
func settle() -> void:
 for frame in 5: await get_tree().process_frame
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://qa/control-position-save.cfg"
 Game.selected_map_id="cyber"
 Game.control_layout=TouchLayout.defaults()
 check(TouchLayout.sanitize({}).joystick.fixed,"Legacy saves retain anchored joystick")
 check(TouchLayout.sanitize({"joystick":{"fixed":"bad"}}).joystick.fixed,"Invalid fixed flag sanitized")
 for vp in [Vector2(1280,720),Vector2(1440,720),Vector2(1560,720),Vector2(1600,720)]:
  var usable:=Rect2(44,18,vp.x-100,vp.y-42)
  var area:=TouchLayout.allowed_area("joystick",vp,usable)
  for requested in [Vector2(-100,-100),Vector2(9999,9999),Vector2(vp.x*.21,vp.y*.2),Vector2(vp.x*.35,vp.y*.72)]:
   var data:=TouchLayout.defaults()
   check(TouchLayout.place(data,"joystick",requested,vp,usable),"Movement placement unrestricted within left half")
   var resolved:=TouchLayout.resolved(data,vp,usable)
   var radius:=TouchLayout.footprint_radius("joystick",resolved.joystick.diameter)
   check(area.grow(.01).encloses(Rect2(resolved.joystick.center-Vector2.ONE*radius,Vector2.ONE*radius*2)),"Entire movement footprint stays left and clear of cutouts")
   var shot: Dictionary=resolved.fire
   check(shot.center.x-shot.diameter*.5>=area.end.x,"Fire remains on the right")
 # Real gameplay and viewport events, including touches above the former reserved HUD area.
 Game.control_layout.joystick.position=Vector2(.25,.18)
 Game.set_mobile_ui(true)
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 scene.player.set_physics_process(false)
 scene.enemy_spawner.set_physics_process(false)
 await settle()
 scene.hud._apply_ui_mode(true)
 var joy: GameJoystick=scene.hud.joystick
 var vp:=get_viewport().get_visible_rect().size
 var anchor:=joy.base.global_position
 check(anchor.y<vp.y*.28,"Movement can be placed in the upper left gameplay area")
 touch(3,anchor+Vector2(20,0),true)
 drag(3,anchor+Vector2(200,0))
 check(joy.base.global_position.is_equal_approx(anchor) and joy.output.x>.99,"Fixed base stays anchored at full movement")
 var shot_center: Vector2=scene.hud.fire_button.get_global_rect().get_center()
 touch(8,shot_center,true)
 check(Input.is_action_pressed("fire") and joy.pressed,"Fixed movement and shooting use independent fingers")
 touch(8,Vector2.ZERO,false)
 check(joy.pressed and not Input.is_action_pressed("fire"),"Shooting release preserves movement")
 touch(3,Vector2.ZERO,false)
 touch(4,vp*Vector2(.35,.65),true)
 check(not joy.pressed,"Fixed mode ignores presses outside its configured circle")
 touch(4,Vector2.ZERO,false)
 Game.control_layout.joystick.fixed=false
 Game.save_settings()
 var selected: Vector2=Game.control_layout.joystick.position
 var start:=vp*Vector2(.35,.6)
 touch(3,start,true)
 check(joy.pressed and joy.base.global_position.is_equal_approx(joy._clamp_base(start)),"Dynamic base starts under finger within visible footprint bounds")
 drag(3,vp*Vector2(.49,.35))
 check(not joy.base.global_position.is_equal_approx(start) and joy.output.length()<=1.001,"Dynamic base follows drag with bounded output")
 var radius:=TouchLayout.footprint_radius("joystick",joy.size.x)
 check(joy._allowed.grow(.01).encloses(Rect2(joy.base.global_position-Vector2.ONE*radius,Vector2.ONE*radius*2)),"Dynamic base cannot escape permitted half")
 touch(8,shot_center,true)
 check(joy.pressed and Input.is_action_pressed("fire"),"Dynamic movement and shooting remain simultaneous")
 touch(3,Vector2.ZERO,false)
 check(Input.is_action_pressed("fire") and joy.base.global_position.is_equal_approx(anchor),"Movement release resets base without cancelling fire")
 touch(8,Vector2.ZERO,false)
 check(Game.control_layout.joystick.position==selected,"Gameplay gestures cannot edit saved position")
 var dialog:=ArcadeUI.settings(scene.hud)
 await settle()
 dialog._tabs.DISPLAY.pressed.emit()
 var gameplay: Button
 for child in dialog._content.get_children():
  if child is Button and child.text=="Gameplay": gameplay=child
 check(gameplay!=null,"Settings Display contains Gameplay")
 gameplay.pressed.emit()
 check(dialog._fixed_button!=null,"Display Gameplay exposes Fixed Control")
 dialog._fixed_button.pressed.emit()
 check(Game.control_layout.joystick.fixed,"Settings fixed toggle saves immediately")
 var before:=Game.control_layout.duplicate(true)
 var editor:=dialog.open_editor()
 await settle()
 if DisplayServer.get_name()!="headless" and "--screenshots" in OS.get_cmdline_user_args():
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://qa/rounded_control_editor.png")
 editor._drag("joystick",editor.preview.get_global_transform()*(editor.preview.size*Vector2(.33,.34)))
 editor._toggle_fixed()
 check(Game.control_layout==before,"Editor isolates draft from gameplay")
 editor.cancel();await settle()
 check(Game.control_layout==before,"Cancel preserves live settings")
 editor=dialog.open_editor();await settle()
 editor._drag("joystick",editor.preview.get_global_transform()*(editor.preview.size*Vector2(.31,.36)))
 editor._toggle_fixed()
 editor.save();await settle()
 check(Game.control_layout.joystick.position.distance_to(Vector2(.31,.36))<.01 and not Game.control_layout.joystick.fixed,"Apply saves arbitrary position and dynamic mode")
 var applied:=Game.control_layout.duplicate(true)
 Game.control_layout=TouchLayout.defaults();Game._load_save()
 check(Game.control_layout==applied,"Position and mode restored from disk")
 editor=dialog.open_editor();await settle();editor.reset_defaults()
 check(editor.draft==TouchLayout.defaults() and Game.control_layout==applied,"Reset changes draft until Apply")
 editor.cancel();await settle()
 dialog.close();await settle()
 check(not get_tree().paused and not joy.fixed_control,"Applied dynamic mode reaches live joystick after settings close")
 scene.free();Game.is_running=false;SoundEffects.stop_all()
 await get_tree().create_timer(.2).timeout
 print("CONTROL POSITION: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
