extends Node
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
 if not value: failures.append(message);push_error(message)
func luminance(color: Color) -> float:
 var linear:=color.srgb_to_linear()
 return linear.r*.2126+linear.g*.7152+linear.b*.0722
func contrast(a: Color,b: Color) -> float:
 var first:=luminance(a)
 var second:=luminance(b)
 return (maxf(first,second)+.05)/(minf(first,second)+.05)
func settle() -> void:
 await get_tree().create_timer(.2).timeout
 for frame in 3: await get_tree().process_frame
func touch(point: Vector2,pressed: bool) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=13;event.position=point;event.pressed=pressed
 get_viewport().push_input(event,true)
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://qa/button-design-test.cfg"
 Game.reduced_motion=false
 # Texture alpha verifies the complete face is rounded, including disabled/focus.
 for asset in ["secondary_normal","secondary_hover","secondary_pressed","primary_normal","primary_hover","primary_pressed","selected_normal","selected_hover","selected_pressed","disabled","focus"]:
  var style:=ArcadeUI.button_style(asset)
  var bitmap:=style.texture.get_image()
  check(bitmap.get_pixel(4,4).a<.01 and bitmap.get_pixel(251,59).a<.01,"Transparent rounded corners: "+asset)
  if asset!="focus":
   check(bitmap.get_pixel(128,12).a>.99 and bitmap.get_pixel(128,50).a>.99,"Continuous button face: "+asset)
   check(not bitmap.get_pixel(128,12).is_equal_approx(bitmap.get_pixel(128,50)),"Layered vertical shading: "+asset)
   if asset!="disabled":
    var foreground:=ArcadeUI.INK if asset.begins_with("primary") else Color("f0ebe2")
    check(contrast(foreground,bitmap.get_pixel(128,32))>=4.5,"Readable label contrast across interactive states: "+asset)
    if asset.ends_with("normal"):
     check(contrast(bitmap.get_pixel(128,32),Color("1c2b3d"))>=2.0,"Visible button face against dark panel: "+asset)
  check(style.content_margin_top==style.content_margin_bottom,"States retain centered baseline")
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 get_tree().root.add_child(root)
 var background:=ColorRect.new()
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.color=Color("101a2a");background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(background)
 var heading:=ArcadeUI.label("ROUNDED FLIGHT CONTROLS",30)
 heading.position=Vector2(40,28);root.add_child(heading)
 var variants: Array[String]=["secondary","primary","selected"]
 var states: Array[String]=["normal","hover","pressed","disabled","focus"]
 var first: Button
 for row in variants.size():
  var title:=ArcadeUI.label(variants[row].to_upper(),16,ArcadeUI.MUTED)
  title.position=Vector2(40,100+row*134);root.add_child(title)
  for col in states.size():
   var b:=ArcadeUI.button("CONTINUE","button_forward",row==1)
   ArcadeUI.style_button(b,row==1,row==2)
   b.position=Vector2(40+col*244,130+row*134)
   b.size=Vector2(224,64)
   root.add_child(b)
   if row==0 and col==0: first=b
   if states[col] in ["hover","pressed"]: b.add_theme_stylebox_override("normal",ArcadeUI.button_style(variants[row]+"_"+states[col],true))
   if states[col]=="disabled": b.disabled=true
   if states[col]=="focus":
    var outline:=Control.new()
    outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outline.mouse_filter=Control.MOUSE_FILTER_IGNORE
    b.add_child(outline)
    outline.draw.connect(func() -> void: outline.draw_style_box(ArcadeUI.button_style("focus",true),Rect2(Vector2.ZERO,outline.size)))
   var caption:=ArcadeUI.label(states[col].to_upper(),14,ArcadeUI.MUTED)
   caption.position=b.position+Vector2(0,76);caption.size.x=224;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(caption)
 var note:=ArcadeUI.label("64 PX TOUCH TARGETS   /   30 PX CURVES   /   SHARED STATES   /   NO RUNTIME SHADERS",17,ArcadeUI.MUTED)
 note.position=Vector2(40,565);root.add_child(note)
 await settle()
 if DisplayServer.get_name()!="headless" and "--screenshots" in OS.get_cmdline_user_args():
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png("res://qa/rounded_button_states.png")
 var rect:=first.get_global_rect()
 var fired: Array[int]=[0]
 first.pressed.connect(func() -> void: fired[0]+=1)
 touch(rect.get_center(),true);await settle()
 check(first.is_pressed() and first.self_modulate.r<1,"Press has tactile transition")
 check(first.get_global_rect()==rect,"Feedback never shifts layout or tap target")
 touch(rect.get_center(),false);await settle()
 check(fired[0]==1 and first.self_modulate.r>=1,"Release invokes existing action and restores feedback / "+str(fired[0])+" / "+str(first.self_modulate))
 first.disabled=true
 touch(rect.get_center(),true);touch(rect.get_center(),false);await settle()
 check(fired[0]==1,"Disabled state blocks actions")
 first.disabled=false;Game.reduced_motion=true
 touch(rect.get_center(),true);await settle()
 check(first.self_modulate==Color.WHITE,"Reduced motion suppresses transitions")
 touch(rect.get_center(),false)
 # Refreshing selected states must not accumulate handlers or feedback nodes.
 for repeat in 5: ArcadeUI.style_button(first,false,repeat%2==0)
 check(first.get_node("ButtonFeedback").get_parent()==first and first.get_child_count()==1,"Repeated restyling retains one feedback owner")
 root.free();SoundEffects.stop_all()
 await get_tree().create_timer(.2).timeout
 print("BUTTON DESIGN: ","PASS" if failures.is_empty() else "FAIL"," / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
