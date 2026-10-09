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
func _ready() -> void:
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
 panel.add_theme_stylebox_override("panel",ArcadeUI.surface(24))
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
  for category in ["GENERAL","LANGUAGE","AUDIO","GRAPHICS","CONTROLS"]:
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
   if category=="AUDIO": _description("Sound effects include weapons, impacts and mission alerts.")
  if category in ["GENERAL","GRAPHICS"]:
   motion=ArcadeUI.button("")
   _content.add_child(motion)
   motion.pressed.connect(func() -> void: Game.reduced_motion=not Game.reduced_motion;Game.save_settings();_refresh())
   if category=="GRAPHICS": _description("Reduce camera shake and interface animations.")
  if category=="GENERAL": _editor_button()
  _description("Changes are saved automatically.")
 _refresh()
 _focus_loop()
func _description(key: String) -> void:
 var label:=ArcadeUI.label(key,18,ArcadeUI.MUTED)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _content.add_child(label)
func _editor_button() -> void:
 var button:=ArcadeUI.button("CUSTOMIZE CONTROLS","",true)
 button.pressed.connect(open_editor)
 _content.add_child(button)
func open_editor() -> ControlLayoutEditor:
 var existing:=get_node_or_null("ControlLayoutEditor") as ControlLayoutEditor
 if existing: return existing
 panel.visible=false
 var editor:=ControlLayoutEditor.new()
 editor.finished.connect(func(_saved: bool) -> void: panel.visible=true;close_button.grab_focus())
 add_child(editor)
 return editor
func _refresh() -> void:
 if is_instance_valid(audio) and not audio.is_queued_for_deletion():
  ArcadeUI.icon(audio,"button_audio" if Game.audio_enabled else "button_audio_off")
  audio.text=I18n.t("SOUND EFFECTS")+"  /  "+I18n.t("ON" if Game.audio_enabled else "OFF")
  ArcadeUI.style_button(audio,false,Game.audio_enabled)
 if is_instance_valid(motion) and not motion.is_queued_for_deletion():
  motion.text=I18n.t("REDUCED MOTION")+"  /  "+I18n.t("ON" if Game.reduced_motion else "OFF")
  ArcadeUI.style_button(motion,false,Game.reduced_motion)
func _language_changed() -> void:
 if mode=="settings": _show_category(_category)
 _layout.call_deferred()
func _focus_loop() -> void:
 var buttons: Array[Button]=[close_button]
 for button in panel.find_children("*","Button",true,false):
  if button!=close_button: buttons.append(button)
 ArcadeUI.focus_loop(buttons)
func _layout() -> void:
 var vp:=get_viewport().get_visible_rect().size
 panel.size=Vector2(minf(vp.x-48,1100),minf(vp.y-48,640) if mode=="settings" else 470)
 panel.position=(vp-panel.size)*0.5
func close() -> void:
 if has_node("ControlLayoutEditor"): return
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
  elif event.keycode in [KEY_P,KEY_R,KEY_LEFT,KEY_RIGHT]: get_viewport().set_input_as_handled()
