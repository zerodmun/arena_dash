extends Node
var failures: Array[String] = []
var levels: LevelSelect
func check(value: bool, message: String) -> void:
 if not value: failures.append(message); push_error(message)
func _ready() -> void: call_deferred("run")
func world_at(local: Vector2) -> Vector2:
 return (local-levels._offset)/levels._scene_scale
func wheel(at: Vector2, button: int) -> void:
 var event := InputEventMouseButton.new()
 event.button_index=button; event.pressed=true
 event.position=levels._map_view.global_position+at
 # Dispatch through Godot's input pipeline, including on the rendered desktop run.
 get_viewport().push_input(event,true)
func touch(index: int, at: Vector2, pressed: bool, canceled := false) -> void:
 var event := InputEventScreenTouch.new()
 event.index=index; event.position=levels._map_view.global_position+at
 event.pressed=pressed; event.canceled=canceled
 get_viewport().push_input(event,true)
func drag(index: int, at: Vector2) -> void:
 var event := InputEventScreenDrag.new()
 event.index=index; event.position=levels._map_view.global_position+at
 get_viewport().push_input(event,true)
func settle() -> void:
 await get_tree().create_timer(0.8).timeout
func capture(name: String) -> void:
 await get_tree().process_frame
 if "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://qa/galaxy_zoom_"+name+".png")
func run() -> void:
 Game.save_path="res://qa/galaxy-zoom-isolated.cfg"
 Game.map_zoom=1.0; Game.map_focus_planet=""; Game.completed_levels={}
 Game.selected_map_id="cyber"; Game.coins=1450
 levels=load("res://scenes/level_select.tscn").instantiate()
 get_tree().root.add_child(levels)
 await settle()
 levels._set_offset(Vector2(-650,-500))
 var anchor := Vector2(450,220)
 var world_before := world_at(anchor)
 wheel(anchor,MOUSE_BUTTON_WHEEL_UP)
 await get_tree().process_frame
 check(levels._zoom_target>1 and levels._zoom<levels._zoom_target,"Wheel queues smooth zoom rather than jumping")
 await settle()
 check(world_at(anchor).distance_to(world_before)<0.01,"Wheel preserves world position under cursor")
 wheel(anchor,MOUSE_BUTTON_WHEEL_DOWN)
 await settle()
 check(absf(levels._zoom-1.0)<0.001,"Reverse wheel restores scale")
 check(world_at(anchor).distance_to(world_before)<0.01,"Zoom-out cursor anchor remains fixed")
 # Simultaneous midpoint movement and scale change.
 var left := Vector2(440,200)
 var right := Vector2(640,200)
 touch(0,left,true); touch(1,right,true)
 var midpoint := (left+right)*0.5
 world_before=world_at(midpoint)
 drag(0,Vector2(390,215)); drag(1,Vector2(710,245))
 var new_midpoint := Vector2(550,230)
 check(absf(levels._zoom-Vector2(390,215).distance_to(Vector2(710,245))/200.0)<0.001,"Pinch changes scale continuously with finger distance")
 check(world_at(new_midpoint).distance_to(world_before)<0.01,"Pinch keeps world anchor beneath moving midpoint")
 check(levels._selected=="cyber","Pinch cannot select a planet")
 touch(0,Vector2(390,215),false)
 var offset_before := levels._offset
 drag(1,Vector2(740,260))
 check(levels._offset.distance_to(offset_before+Vector2(30,15))<0.01,"Remaining finger continues panning after pinch")
 touch(1,Vector2(740,260),false)
 check(levels._pointer==-2 and levels._touches.is_empty() and levels._selected=="cyber","Pinch lift suppresses taps and clears touch state")
 # A canceled single touch over a real planet must not select it.
 levels._focus_planet("forest",false)
 var planet_at: Vector2=levels._offset+LevelSelect.POINTS[1]*levels._scene_scale
 touch(2,planet_at,true); touch(2,planet_at,false,true)
 check(levels._selected=="cyber","Canceled touch never selects")
 # Mouse drag and wheel can run concurrently, without release becoming a tap.
 var mouse := InputEventMouseButton.new()
 mouse.button_index=MOUSE_BUTTON_LEFT; mouse.pressed=true
 mouse.position=levels._map_view.get_global_rect().get_center()
 get_viewport().push_input(mouse.duplicate(),true)
 wheel(levels._map_view.size*0.5,MOUSE_BUTTON_WHEEL_UP)
 var motion := InputEventMouseMotion.new()
 motion.position=mouse.position+Vector2(-50,-30)
 get_viewport().push_input(motion,true)
 mouse.pressed=false; mouse.position=motion.position
 get_viewport().push_input(mouse.duplicate(),true)
 await settle()
 check(levels._selected=="cyber" and levels._pointer==-2,"Zoom while mouse dragging cannot select")
 levels._request_zoom(100,levels._map_view.get_global_rect().get_center())
 await settle()
 check(levels._zoom==levels.maximum_zoom and levels._zoom_in.disabled,"Maximum zoom clamps and disables plus")
 levels._request_zoom(0.001,levels._map_view.get_global_rect().get_center())
 await settle()
 check(is_equal_approx(levels._zoom,levels._minimum_zoom()) and levels._zoom_out.disabled,"Minimum zoom clamps and disables minus")
 levels._zoom_in.pressed.emit()
 await settle()
 check(levels._zoom>levels._minimum_zoom(),"Fixed plus button zooms")
 levels._zoom_out.pressed.emit()
 await settle()
 check(is_equal_approx(levels._zoom,levels._minimum_zoom()),"Fixed minus button zooms out")
 levels._zoom_fit.pressed.emit()
 await settle()
 var world_rect := Rect2(levels._offset,LevelSelect.WORLD_SIZE*levels._scene_scale)
 check(Rect2(Vector2.ZERO,levels._map_view.size).grow(1).encloses(world_rect),"Fit contains entire world")
 check(levels._offset.distance_to((levels._map_view.size-world_rect.size)*0.5)<1,"Fit centers a world smaller than viewport")
 for id: String in Campaign.ORDER:
  check(levels.cards[id].size.x*levels._scene_scale>=48-0.01,"Overview hit target remains usable "+id)
 for label: Label in levels._names:
  check(label.get_theme_font_size("font_size")*levels._scene_scale>=12,"Names retain readable screen font")
 await capture("fit")
 # Every planet can be inspected at each scale; locked planets stay guarded.
 for zoom: float in [levels._minimum_zoom(),0.5,1.0,2.0]:
  levels._zoom_target=zoom
  levels._apply_zoom(zoom,levels._map_view.size*0.5)
  for id: String in Campaign.ORDER:
   levels._focus_planet(id,false)
   var at: Vector2=levels._offset+LevelSelect.POINTS[Campaign.index(id)]*levels._scene_scale
   touch(0,at,true); touch(0,at,false)
   check(levels._selected==id,"Tap inspects "+id+" at "+str(zoom))
   check(levels._deploy.disabled==(id!="cyber"),"Unlock guard unchanged at every scale")
  for i in Campaign.ORDER.size():
   check(not levels._names[i].get_global_rect().intersects(levels._ratings[i].get_global_rect()),"Names never overlap star indicators at "+str(zoom))
   check(levels._names[i].get_theme_font_size("font_size")*levels._names[i].scale.x*levels._scene_scale>=12,"Labels stay readable at "+str(zoom))
 await capture("maximum")
 for viewport_size in [Vector2(960,540),Vector2(1280,720),Vector2(1560,720),Vector2(1920,1080)]:
  var safe := Rect2(Vector2(30,10),viewport_size-Vector2(60,20))
  levels._layout(safe)
  levels._fit_map()
  await settle()
  check(Rect2(Vector2.ZERO,levels._map_view.size).grow(1).encloses(Rect2(levels._offset,LevelSelect.WORLD_SIZE*levels._scene_scale)),"Fit works in landscape "+str(viewport_size))
  for control: Control in [levels._zoom_in,levels._zoom_out,levels._zoom_fit,levels._zoom_readout]:
   check(safe.encloses(control.get_global_rect()),"Zoom controls respect safe area")
   check(not levels._map_view.get_global_rect().intersects(control.get_global_rect()),"Zoom controls stay outside planet viewport")
 # Save preference in an isolated file and preserve it when focusing a newly unlocked mission.
 levels._layout()
 levels._zoom_target=1.35; levels._apply_zoom(1.35,levels._map_view.size*0.5)
 levels.free()
 Game.map_zoom=1.0; Game._load_save()
 check(is_equal_approx(Game.map_zoom,1.35) and Game.coins==1450,"Preference persists without changing economy")
 for id: String in Campaign.ORDER.slice(0,8): Game.completed_levels[id]=3
 Game.map_focus_planet="lava"; Game.last_completed_planet="toxic"
 levels=load("res://scenes/level_select.tscn").instantiate()
 get_tree().root.add_child(levels)
 await settle()
 check(is_equal_approx(levels._zoom,1.35) and levels._selected=="lava" and not levels._deploy.disabled,"Advanced progression focus retains preferred zoom")
 await capture("preferred")
 Game.reduced_motion=true
 levels._request_zoom(0.5,levels._map_view.get_global_rect().get_center())
 check(is_equal_approx(levels._zoom,0.5),"Reduced motion applies zoom immediately")
 Game.reduced_motion=false
 levels.free(); SoundEffects.stop_all()
 await get_tree().create_timer(0.2).timeout
 print("GALAXY ZOOM: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
