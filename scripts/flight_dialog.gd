class_name FlightDialog
extends CanvasLayer
## Categorized landscape settings; editor saves a draft without activating flight inputs.
var mode := "settings"
var panel: PanelContainer
var audio: Button
var motion: Button
var close_button: Button
var _was_paused := false
var _focus: Control
var _content: VBoxContainer
var _category := "GENERAL"
var _tabs: Dictionary={}
var _display_section := ""
var _fixed_button: Button
func _ready() -> void:
 SoundEffects.play("open")
 name="FlightDialog"
 layer=100
 process_mode=Node.PROCESS_MODE_ALWAYS
 _was_paused=get_tree().paused
 _focus=get_viewport().gui_get_focus_owner()
 if Game.is_running:
  Game.flush_save()
  get_tree().paused=true
  Input.action_release("fire")
  for stick in get_tree().get_nodes_in_group("joystick"): stick._reset()
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(root)
 var dim:=ColorRect.new()
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 dim.color=Color(0.025,0.015,0.09,0.82)
 root.add_child(dim)
 panel=PanelContainer.new()
 panel.add_theme_stylebox_override("panel",ArcadeUI.panel(24))
 root.add_child(panel)
 var box:=VBoxContainer.new()
 box.add_theme_constant_override("separation",20)
 panel.add_child(box)
 var heading:=HBoxContainer.new()
 box.add_child(heading)
 var title:=ArcadeUI.label("FLIGHT SETTINGS" if mode=="settings" else "FLIGHT MANUAL",30,ArcadeUI.GOLD)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 heading.add_child(title)
 close_button=ArcadeUI.button("","button_close")
 close_button.custom_minimum_size=Vector2(64,64)
 close_button.tooltip_text="Close (Escape)"
 close_button.pressed.connect(close)
 heading.add_child(close_button)
 var columns:=HBoxContainer.new()
 columns.add_theme_constant_override("separation",24)
 columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(columns)
 if mode=="settings":
  var tabs:=VBoxContainer.new()
  tabs.custom_minimum_size.x=210
  tabs.add_theme_constant_override("separation",8)
  columns.add_child(tabs)
  for category in ["GENERAL","LANGUAGE","AUDIO","DISPLAY","GRAPHICS","CONTROLS"]:
   var button:=ArcadeUI.button(category)
   button.custom_minimum_size.y=64
   button.pressed.connect(func() -> void: _show_category(category))
   tabs.add_child(button)
   _tabs[category]=button
 else:
  columns.add_child(ArcadeUI.image(Game.get_current_ship().texture,Vector2(300,220)))
 _content=VBoxContainer.new()
 _content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _content.add_theme_constant_override("separation",12)
 columns.add_child(_content)
 I18n.changed.connect(_language_changed)
 get_viewport().size_changed.connect(_layout)
 _show_category(_category)
 _layout()
 for frame in 3: await get_tree().process_frame
 _layout()
 close_button.grab_focus()
func _show_category(category: String) -> void:
 _category=category
 for node in _content.get_children(): _content.remove_child(node);node.queue_free()
 for key: String in _tabs: ArcadeUI.style_button(_tabs[key],false,key==category)
 if mode=="help" or category=="CONTROLS":
  var manual:=ArcadeUI.label("HANGAR\nArrows / A–D or swipe: select aircraft\nLoadout: choose weapon • Enter: deploy\nPlanet button: inspect campaign\n\nFLIGHT\nWASD / arrows: fly • Space / J: fire\nEsc / P: pause • F11: fullscreen\nTouch: left joystick + right fire button",18,ArcadeUI.MUTED)
  manual.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  _content.add_child(manual)
  if mode=="settings": _editor_button()
 else:
  if category in ["GENERAL","LANGUAGE"]:
   _content.add_child(ArcadeUI.label("LANGUAGE",24,ArcadeUI.GOLD))
   _description("Choose the language for all menus and flight information.")
   var row:=HBoxContainer.new()
   row.add_theme_constant_override("separation",16)
   _content.add_child(row)
   for pair in [["en","ENGLISH"],["id","BAHASA INDONESIA"]]:
    var btn:=ArcadeUI.button(pair[1])
    btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    ArcadeUI.style_button(btn,false,I18n.language==pair[0])
    btn.pressed.connect(func() -> void: I18n.set_language(pair[0]))
    row.add_child(btn)
  if category in ["GENERAL","AUDIO"]:
   audio=ArcadeUI.button("")
   _content.add_child(audio)
   audio.pressed.connect(func() -> void: Game.audio_enabled=not Game.audio_enabled;Game.save_settings();_refresh())
   if category=="AUDIO": _audio_controls()
  if category in ["GENERAL","GRAPHICS"]:
   motion=ArcadeUI.button("")
   _content.add_child(motion)
   motion.pressed.connect(func() -> void: Game.reduced_motion=not Game.reduced_motion;Game.save_settings();_refresh())
   if category=="GRAPHICS": _description("Reduce camera shake and interface animations.")
  if category=="DISPLAY":
   _content.add_child(ArcadeUI.label("Display",24,ArcadeUI.GOLD))
   if _display_section=="GAMEPLAY":
    var back:=ArcadeUI.button("Display","button_back")
    back.pressed.connect(func() -> void: _display_section="";_show_category("DISPLAY"))
    _content.add_child(back)
    _content.add_child(ArcadeUI.label("Gameplay",24,ArcadeUI.CYAN))
    _editor_button()
    _fixed_button=ArcadeUI.button("")
    _fixed_button.pressed.connect(func() -> void:
     Game.control_layout.joystick.fixed=not Game.control_layout.joystick.fixed
     Game.save_settings()
     _refresh())
    _content.add_child(_fixed_button)
    _description("Fixed: the base stays anchored. Dynamic: the base follows your movement finger within the left half.")
   else:
    var gameplay:=ArcadeUI.button("Gameplay")
    gameplay.pressed.connect(func() -> void: _display_section="GAMEPLAY";_show_category("DISPLAY"))
    _content.add_child(gameplay)
  if category=="GENERAL": _editor_button()
  _description("Changes are saved automatically.")
 _refresh()
 _focus_loop()
func _audio_controls() -> void:
 for bus: String in ["Master","Music","SFX","UI"]:
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",16)
  _content.add_child(row)
  var labels := {"Master":"MASTER VOLUME","Music":"MUSIC VOLUME","SFX":"SOUND EFFECTS VOLUME","UI":"UI SOUNDS VOLUME"}
  var label := ArcadeUI.label(labels[bus],18,ArcadeUI.TEXT)
  label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  row.add_child(label)
  var slider := ArcadeUI.slider(0,100,1)
  slider.name=bus+"Volume"
  slider.value=float(Game.audio_volumes[bus])*100
  slider.tooltip_text=I18n.t(labels[bus])
  row.add_child(slider)
  var value := ArcadeUI.label("%d%%" % slider.value,18,ArcadeUI.CYAN)
  value.custom_minimum_size.x=56
  row.add_child(value)
  slider.value_changed.connect(func(amount: float) -> void:
   SoundEffects.set_volume(bus,amount/100)
   value.text="%d%%" % amount
   SoundEffects.play("slider",-18))
  slider.drag_ended.connect(func(_changed: bool) -> void: Game.save_settings())
  slider.focus_exited.connect(Game.save_settings)
 # Commit keyboard changes and sliders that have not yet lost focus before closing.
func _description(key: String) -> void:
 var label:=ArcadeUI.label(key,18,ArcadeUI.MUTED)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _content.add_child(label)
func _editor_button() -> void:
 var button:=ArcadeUI.button("Customize Control Position","",true)
 button.pressed.connect(open_editor)
 _content.add_child(button)
func open_editor() -> ControlLayoutEditor:
 var existing:=get_node_or_null("ControlLayoutEditor") as ControlLayoutEditor
 if existing: return existing
 panel.visible=false
 var editor:=ControlLayoutEditor.new()
 editor.finished.connect(func(_saved: bool) -> void: panel.visible=true;_refresh();close_button.grab_focus())
 add_child(editor)
 return editor
func _refresh() -> void:
 if is_instance_valid(_fixed_button) and not _fixed_button.is_queued_for_deletion():
  _fixed_button.text=I18n.t("Fixed Control")+"  /  "+I18n.t("ON" if Game.control_layout.joystick.fixed else "OFF")
  ArcadeUI.style_button(_fixed_button,false,Game.control_layout.joystick.fixed)
 if is_instance_valid(audio) and not audio.is_queued_for_deletion():
  ArcadeUI.icon(audio,"button_audio" if Game.audio_enabled else "button_audio_off")
  audio.text=I18n.t("MUTE ALL AUDIO")+"  /  "+I18n.t("OFF" if Game.audio_enabled else "ON")
  ArcadeUI.style_button(audio,false,Game.audio_enabled)
 if is_instance_valid(motion) and not motion.is_queued_for_deletion():
  motion.text=I18n.t("REDUCED MOTION")+"  /  "+I18n.t("ON" if Game.reduced_motion else "OFF")
  ArcadeUI.style_button(motion,false,Game.reduced_motion)
func _language_changed() -> void:
 if mode=="settings": _show_category(_category)
 _layout.call_deferred()
func _focus_loop() -> void:
 var controls: Array[Control]=[close_button]
 for node in panel.find_children("*","Control",true,false):
  if node != close_button and node.focus_mode == Control.FOCUS_ALL: controls.append(node)
 for i in controls.size():
  controls[i].focus_next=controls[i].get_path_to(controls[(i+1)%controls.size()])
  controls[i].focus_previous=controls[i].get_path_to(controls[(i-1+controls.size())%controls.size()])
func _layout(available := Rect2()) -> void:
 var safe:=available if available.has_area() else ArcadeUI.safe_rect(get_viewport().get_visible_rect().size)
 var vp:=safe.size
 panel.size=Vector2(minf(vp.x-48,1100),minf(vp.y-48,640) if mode=="settings" else 470)
 panel.position=safe.position+(vp-panel.size)*0.5
func close() -> void:
 if has_node("ControlLayoutEditor"): return
 SoundEffects.play("close")
 Game.save_settings()
 get_tree().paused=_was_paused
 Game.preferences_changed.emit()
 if is_instance_valid(_focus): _focus.grab_focus()
 queue_free()
func _input(event: InputEvent) -> void:
 if has_node("ControlLayoutEditor"): return
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_ESCAPE:
   close()
   get_viewport().set_input_as_handled()
  elif event.keycode in [KEY_P,KEY_R] or (event.keycode in [KEY_LEFT,KEY_RIGHT] and not get_viewport().gui_get_focus_owner() is HSlider): get_viewport().set_input_as_handled()
