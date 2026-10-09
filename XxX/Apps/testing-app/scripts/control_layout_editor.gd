class_name ControlLayoutEditor
extends CanvasLayer
signal finished(saved: bool)
var draft: Dictionary
var selected_id := "fire"
var panel: PanelContainer
var preview: Control
var _frame: AspectRatioContainer
var handles: Dictionary={}
var size_slider: HSlider
var opacity_slider: HSlider
var _size_label: Label
var _opacity_label: Label
var _status: Label
var _selected_buttons: Dictionary={}
var _syncing := false
func _ready() -> void:
 name="ControlLayoutEditor"
 layer=110
 process_mode=Node.PROCESS_MODE_ALWAYS
 draft=TouchLayout.sanitize(Game.control_layout)
 Input.action_release("fire")
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(root)
 var dim:=ColorRect.new()
 dim.color=Color(0.025,0.015,0.09,0.9)
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(dim)
 panel=PanelContainer.new()
 panel.add_theme_stylebox_override("panel",ArcadeUI.surface(20))
 root.add_child(panel)
 var box:=VBoxContainer.new()
 box.add_theme_constant_override("separation",12)
 panel.add_child(box)
 box.add_child(ArcadeUI.label("CUSTOMIZE FLIGHT CONTROLS",28,ArcadeUI.GOLD))
 var instructions:=ArcadeUI.label("Drag a control in the preview. Keep clear of the HUD and other controls.",18,ArcadeUI.MUTED)
 instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 box.add_child(instructions)
 var columns:=HBoxContainer.new()
 columns.add_theme_constant_override("separation",20)
 columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(columns)
 var frame:=AspectRatioContainer.new()
 _frame=frame
 frame.ratio=get_viewport().get_visible_rect().size.aspect()
 frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
 columns.add_child(frame)
 preview=Control.new()
 preview.custom_minimum_size=Vector2(600,338)
 frame.add_child(preview)
 var bg:=ArcadeUI.image(Game.get_current_map().icon,Vector2.ZERO)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 preview.add_child(bg)
 var aircraft:=ArcadeUI.image(Game.get_current_ship().texture,Vector2.ZERO)
 aircraft.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 aircraft.anchor_left=0.43;aircraft.anchor_top=0.4;aircraft.anchor_right=0.57;aircraft.anchor_bottom=0.69
 preview.add_child(aircraft)
 var safe:=PanelContainer.new()
 safe.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 safe.anchor_bottom=0.28
 safe.add_theme_stylebox_override("panel",ArcadeUI.surface(10))
 safe.mouse_filter=Control.MOUSE_FILTER_IGNORE
 preview.add_child(safe)
 var label:=ArcadeUI.label("HUD / RESERVED AREA",16,ArcadeUI.GOLD)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 safe.add_child(label)
 for id: String in TouchLayout.IDS:
  var handle:=LayoutHandle.new()
  handle.control_id=id
  handle.texture=load("res://assets/ui/controls/control_fire.svg" if id=="fire" else "res://assets/ui/controls/control_joystick_base.svg")
  handle.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  handle.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  handle.mouse_default_cursor_shape=Control.CURSOR_DRAG
  handle.tooltip_text="Drag here to reposition"
  handle.selected.connect(_select)
  handle.dragged.connect(_drag)
  preview.add_child(handle)
  handles[id]=handle
  if id=="joystick":
   var knob:=ArcadeUI.image("res://assets/ui/controls/control_joystick_knob.svg",Vector2.ZERO)
   knob.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   knob.anchor_left=0.3;knob.anchor_top=0.3;knob.anchor_right=0.7;knob.anchor_bottom=0.7
   handle.add_child(knob)
 var side:=VBoxContainer.new()
 side.custom_minimum_size.x=280
 side.add_theme_constant_override("separation",10)
 columns.add_child(side)
 for pair in [["fire","FIRE"],["joystick","MOVEMENT"]]:
  var button:=ArcadeUI.button(pair[1])
  button.pressed.connect(func() -> void: _select(pair[0]))
  side.add_child(button)
  _selected_buttons[pair[0]]=button
 _size_label=ArcadeUI.label("",18,ArcadeUI.CYAN)
 side.add_child(_size_label)
 size_slider=ArcadeUI.slider(80,140,1)
 side.add_child(size_slider)
 _opacity_label=ArcadeUI.label("",18,ArcadeUI.CYAN)
 side.add_child(_opacity_label)
 opacity_slider=ArcadeUI.slider(35,100,1)
 side.add_child(opacity_slider)
 _status=ArcadeUI.label("",16,ArcadeUI.GOLD)
 _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _status.size_flags_vertical=Control.SIZE_EXPAND_FILL
 side.add_child(_status)
 size_slider.value_changed.connect(_set_size)
 opacity_slider.value_changed.connect(_set_opacity)
 var actions:=HBoxContainer.new()
 actions.add_theme_constant_override("separation",16)
 actions.alignment=BoxContainer.ALIGNMENT_END
 box.add_child(actions)
 var buttons: Array[Button]=[]
 for text in ["RESET TO DEFAULT","CANCEL","SAVE LAYOUT"]:
  var button:=ArcadeUI.button(text,"",text=="SAVE LAYOUT")
  button.custom_minimum_size.x=240
  actions.add_child(button)
  buttons.append(button)
 buttons[0].pressed.connect(reset_defaults)
 buttons[1].pressed.connect(cancel)
 buttons[2].pressed.connect(save)
 I18n.changed.connect(_refresh)
 preview.resized.connect(_refresh)
 get_viewport().size_changed.connect(_layout)
 _layout()
 for i in 3: await get_tree().process_frame
 _layout()
 _refresh()
 var focusables: Array[Control]=[_selected_buttons.fire,_selected_buttons.joystick,size_slider,opacity_slider,buttons[0],buttons[1],buttons[2]]
 for i in focusables.size():
  focusables[i].focus_next=focusables[i].get_path_to(focusables[(i+1)%focusables.size()])
  focusables[i].focus_previous=focusables[i].get_path_to(focusables[(i-1+focusables.size())%focusables.size()])
 buttons[2].grab_focus()
func _layout() -> void:
 var vp:=get_viewport().get_visible_rect().size
 _frame.ratio=vp.aspect()
 panel.size=Vector2(minf(vp.x-32,1440),vp.y-32)
 panel.position=(vp-panel.size)*0.5
func _select(id: String) -> void:
 selected_id=id
 _refresh()
func _drag(id: String,global_center: Vector2) -> void:
 var point:=preview.get_global_transform().affine_inverse()*global_center
 if TouchLayout.place(draft,id,point,preview.size):
  selected_id=id
  _status.text=""
 else: _status.text=I18n.t("Position blocked: controls must not overlap.")
 _refresh()
func _refresh() -> void:
 if not is_instance_valid(preview) or preview.size.x<=0: return
 var layout:=TouchLayout.resolved(draft,preview.size)
 for id: String in handles:
  var handle: LayoutHandle=handles[id]
  var data: Dictionary=layout[id]
  handle.position=data.center-Vector2.ONE*data.diameter*0.5
  handle.size=Vector2.ONE*data.diameter
  handle.modulate=Color(1.15,1.15,1.15,data.opacity) if id==selected_id else Color(1,1,1,data.opacity)
  ArcadeUI.style_button(_selected_buttons[id],false,id==selected_id)
 _syncing=true
 size_slider.value=float(draft[selected_id].size)*100
 opacity_slider.value=float(draft[selected_id].opacity)*100
 _size_label.text=I18n.t("BUTTON SIZE")+"  /  %d%%" % size_slider.value
 _opacity_label.text=I18n.t("OPACITY")+"  /  %d%%" % opacity_slider.value
 _syncing=false
func _set_size(value: float) -> void:
 if _syncing: return
 draft[selected_id].size=value/100.0
 var layout:=TouchLayout.resolved(draft,preview.size)
 for id: String in TouchLayout.IDS: draft[id].position=layout[id].center/preview.size
 _refresh()
func _set_opacity(value: float) -> void:
 if _syncing: return
 draft[selected_id].opacity=value/100.0
 _refresh()
func reset_defaults() -> void:
 draft=TouchLayout.defaults()
 _status.text=I18n.t("Defaults restored in preview. Save to apply.")
 _refresh()
func save() -> void:
 Game.control_layout=TouchLayout.sanitize(draft)
 Game.save_settings()
 finished.emit(true)
 queue_free()
func cancel() -> void:
 finished.emit(false)
 queue_free()
func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  cancel()
  get_viewport().set_input_as_handled()
