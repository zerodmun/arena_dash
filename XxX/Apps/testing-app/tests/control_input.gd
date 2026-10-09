extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message);push_error(message)
func touch(index: int,point: Vector2,pressed: bool) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=index;event.position=point;event.pressed=pressed
 get_viewport().push_input(event,true)
func drag(index: int,point: Vector2) -> void:
 var event:=InputEventScreenDrag.new()
 event.index=index;event.position=point
 get_viewport().push_input(event,true)
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://build/control-input-test.cfg"
 Game.selected_map_id="cyber"
 Game.control_layout=TouchLayout.defaults()
 Game.set_mobile_ui(true)
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene)
 get_tree().current_scene=scene
 scene.player.set_physics_process(false)
 for i in 4: await get_tree().process_frame
 var hud: HUD=scene.hud
 hud._apply_ui_mode(true)
 var movement:=hud.joystick.get_global_rect().get_center()
 var firing:=hud.fire_button.get_global_rect().get_center()
 touch(3,movement,true)
 drag(3,movement+Vector2(40,0))
 touch(8,firing,true)
 if PerfDiagnostics.enabled:
  scene.player.set_physics_process(true)
  await get_tree().physics_frame
  await get_tree().process_frame
  scene.player.set_physics_process(false)
  check(PerfDiagnostics.report().input_samples>0,"Debug input consumption latency sampled")
  print("PERF INPUT ",JSON.stringify(PerfDiagnostics.report()))
 check(hud.joystick.output.x>0 and Input.is_action_pressed("fire"),"Viewport routes independent movement/fire fingers")
 touch(8,Vector2.ZERO,false)
 check(hud.joystick.pressed and not Input.is_action_pressed("fire"),"Fire releases outside resized hit region without cancelling movement")
 touch(3,Vector2.ZERO,false)
 check(not hud.joystick.pressed,"Movement releases outside hit region")
 var dialog:=ArcadeUI.settings(hud)
 for i in 4: await get_tree().process_frame
 var editor:=dialog.open_editor()
 for i in 4: await get_tree().process_frame
 get_tree().root.size=Vector2i(1600,720)
 Game._update_device_detection()
 for i in 4: await get_tree().process_frame
 check(is_equal_approx(editor._frame.ratio,get_viewport().get_visible_rect().size.aspect()),"Open editor adapts preview aspect ratio on resize")
 var start: Vector2=editor.handles.fire.get_global_rect().get_center()
 var target:=editor.preview.get_global_transform()*(editor.preview.size*Vector2(0.65,0.65))
 touch(5,start,true)
 drag(5,target)
 touch(5,target,false)
 check(editor.draft.fire.position.distance_to(Vector2(0.65,0.65))<0.01,"Viewport touch drag edits preview")
 check(not hud.joystick.pressed and not Input.is_action_pressed("fire"),"Editor touch does not affect live flight")
 editor.cancel()
 for i in 3: await get_tree().process_frame
 dialog.close()
 for i in 3: await get_tree().process_frame
 scene.free()
 SoundEffects.stop_all()
 print("CONTROL INPUT: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
