class_name ArcadeUI
extends RefCounted
## Shared cosmic flight-console typography, surfaces and interaction states.
const KIT := "res://assets/future_updates/ui/"
const INK := Color("101630")
const BORDER := Color("596cc4")
const CYAN := Color("82e0ff")
const GOLD := Color("ffd475")
const TEXT := Color("e7edff")
const MUTED := Color("acbddd")
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
 l.add_theme_font_override("font",ThemeDB.fallback_font)
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", color)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l
static func image(path: String, minimum: Vector2) -> TextureRect:
 var t := TextureRect.new()
 t.texture = load(path)
 t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.custom_minimum_size = minimum
 t.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return t
static func icon(button: Button, asset: String) -> void:
 var category:="badges" if asset.begins_with("badge_") else "buttons"
 var organized:="res://assets/ui/"+category+"/"+asset+".svg"
 var path:=organized if ResourceLoader.exists(organized) else KIT+asset+".svg"
 button.icon = load(path)
 button.expand_icon = true
 button.add_theme_constant_override("icon_max_width", 30)
static func style_button(b: Button, primary := false, selected := false) -> void:
 b.add_theme_font_override("font",ThemeDB.fallback_font)
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 b.add_theme_font_size_override("font_size",20)
 b.add_theme_color_override("font_color",INK if primary else TEXT)
 b.add_theme_color_override("font_hover_color",INK if primary else TEXT)
 b.add_theme_color_override("font_pressed_color",INK if primary else TEXT)
 b.add_theme_color_override("font_focus_color",INK if primary else TEXT)
 b.add_theme_color_override("font_disabled_color",Color("7e89ac"))
 for state in ["normal","hover","pressed","disabled","focus"]:
  var s := surface(12)
  if primary: s.bg_color=GOLD; s.border_color=GOLD
  elif selected: s.bg_color=Color("293767"); s.border_color=CYAN
  if state=="hover": s.bg_color=Color("ffe5a5") if primary else Color("293767"); s.border_color=CYAN
  if state=="pressed": s.bg_color=Color("d6ac58") if primary else Color("3c4788")
  if state=="disabled": s.bg_color=Color("171c31"); s.border_color=Color("31394f"); s.shadow_size=0
  if state=="focus": s.bg_color=Color.TRANSPARENT; s.border_color=GOLD; s.shadow_size=0
  b.add_theme_stylebox_override(state,s)
static func button(text: String, asset := "", primary := false) -> Button:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size = Vector2(0,64)
 style_button(b,primary)
 if not asset.is_empty(): icon(b,asset)
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
