class_name UIStyler
extends RefCounted
## UIStyler: Enforces hardcoded, high-contrast typography and element metrics.
## Completely bypasses phone OS system settings (accessibility font scale, DPI overrides)
## to guarantee identical, crisp, professional visuals across mobile devices and browsers.

# Base Theme Colors
const COLOR_CYAN := Color(0.22, 0.74, 1.0)
const COLOR_CYAN_GLOW := Color(0.4, 0.9, 1.0)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_WHITE := Color(1.0, 1.0, 1.0)
const COLOR_SUBTEXT := Color(0.75, 0.88, 1.0, 0.85)
const COLOR_OUTLINE := Color(0.02, 0.04, 0.08, 0.95)
const COLOR_RED := Color(1.0, 0.35, 0.4)
const COLOR_GREEN := Color(0.25, 0.9, 0.55)


static func style_label(label: Label, size: int, color: Color = COLOR_WHITE, outline: int = 5, outline_col: Color = COLOR_OUTLINE) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", outline_col)


static func style_title(label: Label, is_mobile: bool) -> void:
	if label == null:
		return
	var sz := 52 if is_mobile else 46
	style_label(label, sz, COLOR_WHITE, 12, Color(0.04, 0.45, 0.85, 0.9))
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_constant_override("shadow_outline_size", 14)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.3, 0.6, 0.9))


static func style_header(label: Label, is_mobile: bool) -> void:
	if label == null:
		return
	var sz := 22 if is_mobile else 18
	style_label(label, sz, COLOR_CYAN_GLOW, 6, COLOR_OUTLINE)


static func style_body(label: Label, is_mobile: bool, color: Color = COLOR_SUBTEXT) -> void:
	if label == null:
		return
	var sz := 19 if is_mobile else 16
	style_label(label, sz, color, 4, COLOR_OUTLINE)


static func style_button(button: Button, font_size: int, text_color: Color = COLOR_WHITE, min_height: int = 64) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	if min_height > 0:
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, float(min_height))


static func style_badge(label: Label, text_color: Color, is_mobile: bool) -> void:
	if label == null:
		return
	var sz := 20 if is_mobile else 16
	style_label(label, sz, text_color, 5, COLOR_OUTLINE)


static func style_weapon_chip(btn: Button, is_selected: bool, color: Color) -> void:
	if btn == null:
		return
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.set_border_width_all(2)

	if is_selected:
		style.bg_color = Color(color.r * 0.16, color.g * 0.16, color.b * 0.16, 0.94)
		style.border_color = color
		style.shadow_color = Color(color.r, color.g, color.b, 0.45)
		style.shadow_size = 10
	else:
		style.bg_color = Color(0.03, 0.06, 0.11, 0.82)
		style.border_color = Color(0.16, 0.28, 0.42, 0.5)
		style.shadow_size = 0

	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)


static func style_sector_card(btn: Button, is_selected: bool, color: Color) -> void:
	if btn == null:
		return
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.set_border_width_all(2)

	if is_selected:
		style.bg_color = Color(color.r * 0.18, color.g * 0.18, color.b * 0.18, 0.95)
		style.border_color = color
		style.shadow_color = Color(color.r, color.g, color.b, 0.55)
		style.shadow_size = 14
	else:
		style.bg_color = Color(0.03, 0.05, 0.10, 0.88)
		style.border_color = Color(0.18, 0.28, 0.44, 0.55)
		style.shadow_size = 0

	style.content_margin_left = 10.0
	style.content_margin_top = 10.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 10.0

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)


static func style_mobile_sector_strip(btn: Button, is_selected: bool, color: Color) -> void:
	if btn == null:
		return
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.set_border_width_all(2)

	if is_selected:
		style.bg_color = Color(color.r * 0.16, color.g * 0.16, color.b * 0.16, 0.94)
		style.border_color = color
		style.shadow_color = Color(color.r, color.g, color.b, 0.5)
		style.shadow_size = 10
	else:
		style.bg_color = Color(0.04, 0.07, 0.13, 0.85)
		style.border_color = Color(0.18, 0.28, 0.42, 0.55)
		style.shadow_size = 0

	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	var check_label := btn.find_child("Check", true, false) as Label
	if check_label:
		check_label.text = "✔" if is_selected else "›"
		check_label.add_theme_color_override("font_color", color if is_selected else Color(0.4, 0.55, 0.7, 0.6))
