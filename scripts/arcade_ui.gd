class_name ArcadeUI
extends RefCounted
## Shared cosmic flight-console typography, surfaces and interaction states.
const KIT := "res://assets/future_updates/ui/"
const INK := Color("111b2b")
const BORDER := Color("536b83")
const CYAN := Color("90bbcf")
const GOLD := Color("d8b779")
const TEXT := Color("e2e9f0")
const MUTED := Color("a8b9cc")
const BUTTON_ART := "res://assets/ui/theme/buttons/"
static var _button_styles: Dictionary={}
static func surface(margin := 20.0) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = Color(INK,0.96)
 s.border_color = BORDER
 s.set_border_width_all(2)
 s.set_corner_radius_all(16)
 s.set_content_margin_all(margin)
 s.shadow_color = Color(0.02,0.01,0.08,0.4)
 s.shadow_size = 6
 return s
static func label(text: String, font_size := 22, color := TEXT) -> Label:
 var l := Label.new()
 l.text = text
 l.add_theme_font_override("font",bold_font() if font_size>=24 else ThemeDB.fallback_font)
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", color)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l
static func image(path: String, minimum: Vector2) -> TextureRect:
 var t := TextureRect.new()
 t.texture = load(path)
 if path.ends_with("space_landscape.svg"): t.modulate=Color(.65,.7,.8)
 t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.custom_minimum_size = minimum
 t.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return t
static func icon(button: Button, asset: String) -> void:
 var category:="badges" if asset.begins_with("badge_") else "buttons"
 var organized:="res://assets/ui/"+category+"/"+asset+".svg"
 var glyph:="res://assets/ui/theme/icons/"+asset+".svg"
 var path:=glyph if ResourceLoader.exists(glyph) else organized if ResourceLoader.exists(organized) else KIT+asset+".svg"
 button.icon = load(path)
 button.expand_icon = true
 button.add_theme_constant_override("icon_max_width", 30)
 style_button(button,bool(button.get_meta("ui_primary",false)),bool(button.get_meta("ui_selected",false)))
static func style_button(b: Button, primary := false, selected := false) -> void:
 b.set_meta("ui_primary",primary)
 b.set_meta("ui_selected",selected)
 b.add_theme_font_override("font",bold_font())
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.alignment=HORIZONTAL_ALIGNMENT_CENTER
 b.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT if not b.text.is_empty() else HORIZONTAL_ALIGNMENT_CENTER
 b.vertical_icon_alignment=VERTICAL_ALIGNMENT_CENTER
 b.add_theme_constant_override("h_separation",10)
 b.add_theme_constant_override("line_spacing",0)
 b.add_theme_constant_override("outline_size",0)
 b.add_theme_constant_override("align_to_largest_stylebox",1)
 if not b.has_theme_font_size_override("font_size"): b.add_theme_font_size_override("font_size",20)
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
  b.add_theme_color_override(state,INK if primary else Color("f0ebe2"))
 b.add_theme_color_override("font_disabled_color",Color("8795a7"))
 for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_hover_pressed_color","icon_focus_color"]:
  b.add_theme_color_override(state,INK if primary else Color("d3e1e6"))
 b.add_theme_color_override("icon_disabled_color",Color("738398"))
 b.clip_text=false
 b.flat=false
 var kind:="primary" if primary else "selected" if selected else "secondary"
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var asset: String=state if state in ["disabled","focus"] else kind+"_"+("pressed" if state=="hover_pressed" else state)
  b.add_theme_stylebox_override(state,button_style(asset,b.icon!=null and not b.text.is_empty()))
 if not b.has_node("ButtonFeedback"):
  var feedback:=preload("res://scripts/button_feedback.gd").new()
  feedback.name="ButtonFeedback"
  b.add_child(feedback)
static func button_style(asset: String, balance_icon := false) -> StyleBoxTexture:
 # Immutable shared nine-slices: curved face, border and bevel are one silhouette.
 var key:=asset+("_balanced_icon" if balance_icon else "")
 if not _button_styles.has(key):
  var box:=StyleBoxTexture.new()
  box.texture=load(BUTTON_ART+asset+".svg")
  box.texture_margin_left=32
  box.texture_margin_right=32
  box.texture_margin_top=30
  box.texture_margin_bottom=30
  box.content_margin_left=16
  # Native left icons reserve 30px + 10px gap. Mirror that reservation on the
  # right so the label itself remains at the button's true horizontal center.
  box.content_margin_right=56 if balance_icon else 16
  box.content_margin_top=12
  box.content_margin_bottom=12
  _button_styles[key]=box
 return _button_styles[key]
static func button(text: String, asset := "", primary := false) -> Button:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size = Vector2(0,64)
 style_button(b,primary)
 if not asset.is_empty():
  icon(b,asset)
  style_button(b,primary)
 return b
static func settings(parent: Node) -> FlightDialog:
 return _dialog(parent,"settings")
static func help(parent: Node) -> FlightDialog:
 return _dialog(parent,"help")
static func _dialog(parent: Node, mode: String) -> FlightDialog:
 var existing := parent.get_node_or_null("FlightDialog") as FlightDialog
 if existing: return existing
 var dialog := FlightDialog.new()
 dialog.mode=mode
 parent.add_child(dialog)
 return dialog

static func focus_loop(buttons: Array[Button]) -> void:
 for i in buttons.size():
  buttons[i].focus_next=buttons[i].get_path_to(buttons[(i+1)%buttons.size()])
  buttons[i].focus_previous=buttons[i].get_path_to(buttons[(i-1+buttons.size())%buttons.size()])

static func slider(minimum: float,maximum: float,increment: float) -> HSlider:
 var control:=HSlider.new()
 control.min_value=minimum
 control.max_value=maximum
 control.step=increment
 control.custom_minimum_size=Vector2(240,48)
 var track:=StyleBoxTexture.new()
 track.texture=load("res://assets/ui/sliders/slider_track.svg")
 track.texture_margin_left=12
 track.texture_margin_right=12
 track.content_margin_top=12
 track.content_margin_bottom=12
 track.modulate_color=Color(0.35,0.45,0.6,1)
 control.add_theme_stylebox_override("slider",track)
 var thumb: Texture2D=load("res://assets/ui/sliders/slider_thumb.svg")
 control.add_theme_icon_override("grabber",thumb)
 control.add_theme_icon_override("grabber_highlight",thumb)
 control.add_theme_icon_override("grabber_disabled",thumb)
 var fill:=StyleBoxFlat.new()
 fill.bg_color=CYAN
 fill.set_corner_radius_all(6)
 fill.content_margin_top=6
 fill.content_margin_bottom=6
 control.add_theme_stylebox_override("grabber_area",fill)
 control.add_theme_stylebox_override("grabber_area_highlight",fill)
 var focus:=surface(0)
 focus.bg_color=Color.TRANSPARENT
 focus.border_color=GOLD
 control.add_theme_stylebox_override("focus",focus)
 return control

static func panel(margin := 20.0) -> StyleBoxTexture:
 var box:=StyleBoxTexture.new()
 box.texture=load("res://assets/ui/theme/panel_strip.svg" if margin<12 else "res://assets/ui/theme/panel.svg")
 box.texture_margin_left=32
 box.texture_margin_right=32
 box.texture_margin_top=20 if margin<12 else 32
 box.texture_margin_bottom=20 if margin<12 else 32
 box.set_content_margin_all(margin)
 return box

static func safe_rect(vp: Vector2) -> Rect2:
 var full:=Rect2(Vector2.ZERO,vp)
 if OS.get_name() not in ["Android","iOS"]: return full
 var physical:=Vector2(DisplayServer.window_get_size())
 var device:=Rect2(DisplayServer.get_display_safe_area())
 if not device.has_area() or physical.x<=0 or physical.y<=0: return full
 device.position-=Vector2(DisplayServer.window_get_position())
 return full.intersection(map_safe_rect(device,physical,vp))

static func map_safe_rect(device: Rect2,physical: Vector2,vp: Vector2) -> Rect2:
 return Rect2(device.position*vp/physical,device.size*vp/physical)

static var _bold: FontVariation
static func bold_font() -> FontVariation:
 if _bold==null:
  _bold=FontVariation.new()
  _bold.base_font=ThemeDB.fallback_font
  _bold.variation_embolden=.65
 return _bold
