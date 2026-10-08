class_name Hangar
extends Control
## Reference-inspired hangar: top stats, central 2D aircraft and bottom loadout controls.
const ACCENT := Color("f0b567")
const WHITE := Color("edf3f7")
const MUTED := Color("92a8b9")
var _ship_index := 0
var _map_id := "coast"
var _deploying := false
var _ship_image: TextureRect
var _ship_name: Label
var _ship_class: Label
var _counter: Label
var _launch: Button
var _hero: Control
var _roster_scroll: ScrollContainer
var _aircraft_buttons: Dictionary = {}
var _bars: Array[ProgressBar] = []
var _stat_labels: Array[Label] = []
var _weapon_card: Button
var _map_card: Button
var _weapon_card_label: Label
var _map_card_label: Label
var _weapon_icon: TextureRect
var _map_icon: TextureRect
var _overlay: Control
var _modal: PanelContainer
var _preview: HangarPreview
var _popup_title: Label
var _popup_ship: Label
var _popup_description: Label
var _options: HFlowContainer
var _popup_buttons: Dictionary = {}
var _popup_mode := ""
var _close_button: Button
var _return_focus: Control
var _ship_tween: Tween
var _drag_start := Vector2.ZERO
var _drag_index := -1
var _dragging := false
var _compact := false
var _stage: Control

var _environment: Control
var _header: PanelContainer
var _header_title: Label
var _profile: Label
var _record: Label
var _stats_panel: PanelContainer
var _stats_badge: PanelContainer
var _stat_headings: Array[Label] = []
var _identity: PanelContainer
var _prev: Button
var _next: Button
var _hint: Label
var _help: AcceptDialog

func _ready() -> void:
	Game.is_running = false
	Input.action_release("fire")
	_map_id = Game.selected_map_id
	_ship_index = maxi(0, Game.SHIPS.keys().find(Game.selected_ship_id))
	_build_ui()
	_refresh()
	get_viewport().size_changed.connect(_adapt_layout)
	_adapt_layout()

func _surface(bg: Color = Color("101e2c"), border: Color = Color("304454"), margin: float = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func _label(text: String, font_size := 18, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, primary := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size.y = 54
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color("102032") if primary else WHITE)
	btn.add_theme_color_override("font_hover_color", Color("102032") if primary else WHITE)
	btn.add_theme_stylebox_override("normal", _surface(ACCENT if primary else Color("152737"), ACCENT if primary else Color("304454"), 12))
	btn.add_theme_stylebox_override("hover", _surface(Color("ffcd8c") if primary else Color("253d50"), ACCENT, 12))
	btn.add_theme_stylebox_override("pressed", _surface(Color("ca934e") if primary else Color("314d61"), ACCENT, 12))
	btn.add_theme_stylebox_override("focus", _surface(Color.TRANSPARENT, ACCENT, 12))
	return btn

func _image(path: String, minimum: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(path)
	image.custom_minimum_size = minimum
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _build_ui() -> void:
	_environment = Control.new()
	_environment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_environment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_environment.draw.connect(_draw_environment)
	_environment.resized.connect(func() -> void: _environment.queue_redraw())
	add_child(_environment)
	_build_header()
	_build_stats_strip()
	_build_display()
	_build_bottom_controls()
	_build_popup()

func _build_header() -> void:
	_header = PanelContainer.new()
	_header.add_theme_stylebox_override("panel", _surface(Color(0.035, 0.055, 0.08, 0.97), Color("6b7d8b"), 16))
	add_child(_header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_header.add_child(row)
	var emblem := _label("AD", 30, ACCENT)
	emblem.custom_minimum_size.x = 74
	row.add_child(emblem)
	_profile = _label("ARENA DASH\nFLIGHT COMMAND", 15, WHITE)
	row.add_child(_profile)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	_record = _label("REKOR   %05d" % Game.high_score, 17, ACCENT)
	row.add_child(_record)
	var help := _button("?")
	help.custom_minimum_size = Vector2(50, 48)
	help.tooltip_text = "Panduan kontrol"
	help.pressed.connect(func() -> void: _help.popup_centered())
	row.add_child(help)
	_header_title = _label("HANGAR", 38)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_header_title)
	_help = AcceptDialog.new()
	_help.title = "KONTROL PENERBANGAN"
	_help.dialog_text = "Hangar: klik pesawat di bawah, panah, A/D, atau geser display.\nCard peluru dan map membuka preview pilihan.\nEnter memulai misi.\n\nBermain: WASD / panah untuk terbang, Space / J untuk menembak.\nEsc / P untuk jeda. F11 untuk layar penuh."
	_help.min_size = Vector2i(540, 300)
	add_child(_help)

func _build_stats_strip() -> void:
	_stats_badge = PanelContainer.new()
	_stats_badge.add_theme_stylebox_override("panel", _surface(Color("f5f8fc"), Color("c88b2d"), 8))
	add_child(_stats_badge)
	var badge := _label("STATISTIK", 18, Color("193a52"))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_badge.add_child(badge)
	_stats_panel = PanelContainer.new()
	_stats_panel.add_theme_stylebox_override("panel", _surface(Color("eaf2fb"), Color("afc9e3"), 16))
	add_child(_stats_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	_stats_panel.add_child(row)
	for title in ["KECEPATAN", "PERISAI", "LAJU TEMBAKAN"]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 6)
		row.add_child(box)
		var top := HBoxContainer.new()
		box.add_child(top)
		var name_label := _label(title, 16, Color("1f3c57"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stat_headings.append(name_label)
		top.add_child(name_label)
		var value := _label("", 16, Color("32516c"))
		_stat_labels.append(value)
		top.add_child(value)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 12
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _surface(Color("cedfed"), Color("7d9ebd"), 0))
		bar.add_theme_stylebox_override("fill", _surface(Color("ffaf12"), Color("f3c854"), 0))
		_bars.append(bar)
		box.add_child(bar)

func _build_display() -> void:
	_hero = Control.new()
	_hero.mouse_filter = Control.MOUSE_FILTER_STOP
	_hero.gui_input.connect(_on_preview_input)
	add_child(_hero)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.draw.connect(_draw_stage)
	_stage.resized.connect(func() -> void: _stage.queue_redraw())
	_hero.add_child(_stage)
	_ship_image = _image(Game.get_current_ship().texture, Vector2.ZERO)
	_ship_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hero.add_child(_ship_image)
	_prev = _button("❮")
	_next = _button("❯")
	for arrow in [_prev, _next]:
		arrow.add_theme_font_size_override("font_size", 58)
		arrow.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		arrow.add_theme_stylebox_override("hover", _surface(Color(1, 1, 1, 0.1), Color.TRANSPARENT, 0))
		arrow.add_theme_color_override("font_color", Color.WHITE)
		add_child(arrow)
	_prev.pressed.connect(func() -> void: _switch_ship(-1))
	_next.pressed.connect(func() -> void: _switch_ship(1))
	_identity = PanelContainer.new()
	_identity.add_theme_stylebox_override("panel", _surface(Color(0.035, 0.065, 0.09, 0.92), Color("8095a0"), 10))
	add_child(_identity)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_identity.add_child(box)
	_ship_name = _label("", 30)
	_ship_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ship_name)
	_ship_class = _label("", 13, Color("d1dce2"))
	_ship_class.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ship_class)
	_counter = _label("", 13, Color("e4edf4"))
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_counter)
	_roster_scroll = ScrollContainer.new()
	_roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_roster_scroll)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	_roster_scroll.add_child(row)
	for id: String in Game.SHIPS:
		var btn := _button("")
		btn.custom_minimum_size = Vector2(136, 88)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: _select_ship(id))
		row.add_child(btn)
		_aircraft_buttons[id] = btn
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_top = 6
		content.offset_bottom = -6
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(content)
		content.add_child(_image(Game.SHIPS[id].texture, Vector2(0, 50)))
		var name_label := _label(Game.SHIPS[id].name, 13)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)

func _draw_environment() -> void:
	var w := _environment.size.x
	var h := _environment.size.y
	if w <= 0 or h <= 0:
		return
	var horizon := h * (0.57 if _compact else 0.62)
	_environment.draw_rect(Rect2(0, 0, w, h), Color("333f49"))
	# The amber service wall and perspective floor follow the reference composition.
	_environment.draw_rect(Rect2(0, 80, w, horizon - 80), Color("c18e1e"))
	for i in range(30):
		var t := float(i) / 30
		var tint := Color("ffc534").lerp(Color("b78318"), absf(t - 0.5) * 1.5)
		_environment.draw_rect(Rect2(t * w, 80, w / 30 + 1, horizon - 80), tint)
	for x in [w * 0.09, w * 0.25, w * 0.75, w * 0.91]:
		_environment.draw_rect(Rect2(x, 80, 13, horizon - 80), Color(0.4, 0.29, 0.11, 0.23))
		_environment.draw_line(Vector2(x + 14, 80), Vector2(x + 14, horizon), Color(1, 0.9, 0.55, 0.18), 2)
	_environment.draw_rect(Rect2(0, horizon - 18, w, 24), Color("26394a"))
	_environment.draw_rect(Rect2(0, horizon + 6, w, h - horizon), Color("625c4d"))
	for i in range(20):
		var t := float(i) / 20
		_environment.draw_rect(Rect2(0, horizon + (h - horizon) * t, w, (h - horizon) / 20 + 1), Color("776c53").lerp(Color("353b3e"), t))
	for x in [-0.3, 0.12, 0.5, 0.88, 1.3]:
		_environment.draw_line(Vector2(w * 0.5 + (x - 0.5) * w * 0.3, horizon + 12), Vector2(x * w, h), Color("b4bec1"), 4, true)
	for y in [0.25, 0.55, 0.85]:
		var fy: float = horizon + (h - horizon) * y
		_environment.draw_line(Vector2(0, fy), Vector2(w, fy), Color(0.1, 0.15, 0.18, 0.5), 2)
	for i in range(14):
		var x := w * 0.09 + i * w * 0.059
		_environment.draw_rect(Rect2(x, horizon + 22, w * 0.06, 12), Color("eebd31") if i % 2 == 0 else Color("23303b"))
	# Ceiling piping and beams establish a hangar rather than a flat menu background.
	_environment.draw_rect(Rect2(0, 80, w, 47), Color("788a97"))
	_environment.draw_line(Vector2(0, 108), Vector2(w, 108), Color("30424c"), 9)
	for x in [w * 0.15, w * 0.48, w * 0.82]:
		_environment.draw_line(Vector2(x, 80), Vector2(x + 18, 125), Color("34434b"), 8)
		_environment.draw_circle(Vector2(x + 18, 120), 5, Color("e7d8ac"))
	# Restrained edge shading keeps the center bay bright.
	for i in range(12):
		_environment.draw_rect(Rect2(i * w * 0.01, 80, w * 0.01, h - 80), Color(0.015, 0.03, 0.05, 0.15 * (1 - float(i) / 12)))
		_environment.draw_rect(Rect2(w - (i + 1) * w * 0.01, 80, w * 0.01, h - 80), Color(0.015, 0.03, 0.05, 0.15 * (1 - float(i) / 12)))

func _draw_stage() -> void:
	var center := _stage.size * Vector2(0.5, 0.73)
	for i in range(10):
		var points := PackedVector2Array()
		var radius := Vector2(_stage.size.x * (0.18 - i * 0.006), _stage.size.y * (0.055 - i * 0.002))
		for point in range(64):
			var a := float(point) / 64 * TAU
			points.append(center + Vector2(cos(a), sin(a)) * radius)
		_stage.draw_colored_polygon(points, Color(0.015, 0.02, 0.025, 0.035))

func _build_bottom_controls() -> void:
	_weapon_card = _button("")
	_weapon_card.pressed.connect(func() -> void: _open_popup("weapon"))
	add_child(_weapon_card)
	var weapon_row := _card_content(_weapon_card)
	_weapon_icon = _image(Game.get_current_weapon().texture, Vector2(32, 50))
	weapon_row.add_child(_weapon_icon)
	var weapon_box := VBoxContainer.new()
	weapon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_row.add_child(weapon_box)
	weapon_box.add_child(_label("PILIH PELURU", 12, ACCENT))
	_weapon_card_label = _label("", 15)
	weapon_box.add_child(_weapon_card_label)
	weapon_row.add_child(_label("›", 24))
	_map_card = _button("")
	_map_card.pressed.connect(func() -> void: _open_popup("map"))
	add_child(_map_card)
	var map_row := _card_content(_map_card)
	_map_icon = _image(Game.get_current_map().icon, Vector2(44, 50))
	map_row.add_child(_map_icon)
	var map_box := VBoxContainer.new()
	map_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_row.add_child(map_box)
	map_box.add_child(_label("PILIH MAP", 12, ACCENT))
	_map_card_label = _label("", 15)
	map_box.add_child(_map_card_label)
	map_row.add_child(_label("›", 24))
	_launch = _button("MULAI MISI   →", true)
	_launch.add_theme_font_size_override("font_size", 28)
	for state in ["normal", "hover", "pressed"]:
		var fill := Color("ffb82e") if state == "normal" else (Color("ffd166") if state == "hover" else Color("df9420"))
		var style := _surface(fill, Color("fff0c8"), 16)
		style.set_corner_radius_all(36)
		style.set_border_width_all(2)
		_launch.add_theme_stylebox_override(state, style)
	_launch.pressed.connect(_deploy)
	add_child(_launch)
	_hint = _label("GESER / A–D UNTUK MEMILIH PESAWAT", 13, Color("d8e3e9"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

func _card_content(btn: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = 12
	row.offset_bottom = -12
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	return row

func _build_popup() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var dim := Button.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(state, _surface(Color(0.015, 0.035, 0.055, 0.9), Color.TRANSPARENT, 0))
	dim.focus_mode = Control.FOCUS_NONE
	dim.pressed.connect(_close_popup)
	_overlay.add_child(dim)
	_modal = PanelContainer.new()
	_modal.add_theme_stylebox_override("panel", _surface(Color("102130"), Color("4a6478"), 24))
	_overlay.add_child(_modal)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	scroll.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	_popup_title = _label("", 28)
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_popup_title)
	_close_button = _button("✕")
	_close_button.custom_minimum_size = Vector2(48, 48)
	_close_button.pressed.connect(_close_popup)
	top.add_child(_close_button)
	_popup_ship = _label("", 16, MUTED)
	box.add_child(_popup_ship)
	_preview = HangarPreview.new()
	_preview.custom_minimum_size.y = 300
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_preview)
	box.add_child(_label("PILIH TIPE DI BAWAH — PREVIEW LANGSUNG BERUBAH", 13, ACCENT))
	_options = HFlowContainer.new()
	_options.add_theme_constant_override("h_separation", 10)
	_options.add_theme_constant_override("v_separation", 10)
	box.add_child(_options)
	_popup_description = _label("", 16, MUTED)
	_popup_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_description.custom_minimum_size.y = 44
	box.add_child(_popup_description)
	var done := _button("SELESAI", true)
	done.pressed.connect(_close_popup)
	box.add_child(done)

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _adapt_layout() -> void:
	var vp := get_viewport_rect().size
	_compact = vp.x < 1100
	_counter.visible = true
	_identity.add_theme_stylebox_override("panel", _surface(Color(0.035, 0.065, 0.09, 0.92), Color("8095a0"), 10))
	_place(_header, Rect2(0, 0, vp.x, 80))
	_place(_header_title, Rect2(vp.x * 0.5 - 125, 10, 250, 58))
	_profile.visible = not _compact
	_header_title.add_theme_font_size_override("font_size", 30 if _compact else 38)
	for label in _stat_headings:
		label.add_theme_font_size_override("font_size", 12 if _compact else 16)
	for label in _stat_labels:
		label.add_theme_font_size_override("font_size", 12 if _compact else 16)
	_place(_stats_badge, Rect2(vp.x * 0.5 - 100, 94, 200, 40))
	_place(_stats_panel, Rect2(24 if _compact else vp.x * 0.15, 146, vp.x - 48 if _compact else vp.x * 0.7, 78))
	var reserved := 420.0 if _compact else 260.0
	_place(_hero, Rect2(0, 240, vp.x, maxf(vp.y - 240 - reserved, 220)))
	_ship_image.offset_left = vp.x * 0.28 if not _compact else vp.x * 0.15
	_ship_image.offset_right = -_ship_image.offset_left
	_ship_image.offset_top = 0
	_ship_image.offset_bottom = -10
	var arrow_y := _hero.position.y + _hero.size.y * 0.48 - 45
	_place(_prev, Rect2(vp.x * 0.10, arrow_y, 80, 100))
	_place(_next, Rect2(vp.x * 0.90 - 80, arrow_y, 80, 100))
	var identity_y := vp.y - (416 if _compact else 255)
	_place(_identity, Rect2(vp.x * 0.5 - 180, identity_y, 360, 82))
	if _compact:
		_place(_roster_scroll, Rect2(24, vp.y - 314, vp.x - 48, 100))
		var card_width := (vp.x - 64) / 2
		_place(_weapon_card, Rect2(24, vp.y - 188, card_width, 86))
		_place(_map_card, Rect2(40 + card_width, vp.y - 188, card_width, 86))
		_place(_launch, Rect2(24, vp.y - 84, vp.x - 48, 60))
		_hint.visible = false
	else:
		var card_width := clampf(vp.x * 0.15, 240, 290)
		var left_limit := card_width + 60
		var right_limit := vp.x - 390
		var roster_width := minf(840, right_limit - left_limit)
		_place(_roster_scroll, Rect2(left_limit + (right_limit - left_limit - roster_width) / 2, vp.y - 156, roster_width, 96))
		_place(_weapon_card, Rect2(30, vp.y - 230, card_width, 90))
		_place(_map_card, Rect2(30, vp.y - 126, card_width, 90))
		_place(_launch, Rect2(vp.x - 360, vp.y - 130, 330, 88))
		_place(_hint, Rect2(vp.x * 0.5 - 420, vp.y - 38, 840, 24))
		_hint.visible = true
		if vp.y < 900:
			# Reserve less vertical space on landscape phones so the aircraft stays prominent.
			_place(_hero, Rect2(0, 225, vp.x, vp.y - 405))
			_ship_image.offset_top = 0
			_ship_image.offset_bottom = 0
			var short_arrow_y := _hero.position.y + _hero.size.y * 0.48 - 45
			_place(_prev, Rect2(vp.x * 0.10, short_arrow_y, 80, 100))
			_place(_next, Rect2(vp.x * 0.90 - 80, short_arrow_y, 80, 100))
			_counter.visible = false
			_identity.add_theme_stylebox_override("panel", _surface(Color(0.035, 0.065, 0.09, 0.92), Color("8095a0"), 8))
			_place(_identity, Rect2(vp.x * 0.5 - 180, vp.y - 184, 360, 70))
			_ship_name.add_theme_font_size_override("font_size", 24)
			_place(_roster_scroll, Rect2(_roster_scroll.position.x, vp.y - 108, roster_width, 76))
			_place(_launch, Rect2(vp.x - 360, vp.y - 106, 330, 76))
		else:
			_ship_name.add_theme_font_size_override("font_size", 30)
	_environment.queue_redraw()
	_layout_popup()

func _layout_popup() -> void:
	var vp := get_viewport_rect().size
	_modal.size = Vector2(minf(vp.x - 48, 900), minf(vp.y - 64, 820))
	_modal.position = (vp - _modal.size) / 2

func get_hangar_texture(id: String) -> Texture2D:
	return load(Game.SHIPS[id].texture)

func _refresh() -> void:
	var ship := Game.get_current_ship()
	_ship_image.texture = get_hangar_texture(ship.id)
	_ship_name.text = ship.name
	_ship_name.add_theme_color_override("font_color", ship.color)
	_ship_class.text = ship["class"]
	_counter.text = "%02d / %02d" % [_ship_index + 1, Game.SHIPS.size()]
	_bars[0].value = ship.speed / 500.0 * 100
	_bars[1].value = ship.max_lives / 5.0 * 100
	_bars[2].value = (0.30 - ship.fire_rate) / 0.20 * 100
	_stat_labels[0].text = "%d" % ship.speed
	_stat_labels[1].text = "%d SEL" % ship.max_lives
	_stat_labels[2].text = "%.1f / DETIK" % (1.0 / ship.fire_rate)
	for id: String in _aircraft_buttons:
		_set_selected(_aircraft_buttons[id], id == ship.id)
	_weapon_card_label.text = Game.get_current_weapon().name
	_weapon_icon.texture = load(Game.get_current_weapon().texture)
	_map_card_label.text = "LOKASI ACAK" if _map_id == "random" else Game.MAPS[_map_id].name
	_map_icon.texture = load("res://assets/map_random.svg" if _map_id == "random" else Game.MAPS[_map_id].icon)
	_stage.queue_redraw()
	if _overlay.visible:
		_refresh_popup()

func _set_selected(btn: Button, selected: bool) -> void:
	btn.add_theme_stylebox_override("normal", _surface(Color("294050") if selected else Color("122435"), ACCENT if selected else Color("304454"), 12))

func _open_popup(mode: String) -> void:
	_popup_mode = mode
	_return_focus = _weapon_card if mode == "weapon" else _map_card
	_dragging = false
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	_popup_buttons.clear()
	var catalog: Dictionary = Game.WEAPONS if mode == "weapon" else Game.MAPS
	for id: String in catalog:
		var btn := _button(catalog[id].name)
		btn.custom_minimum_size.y = 50
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(func() -> void: _choose_popup_option(id))
		_options.add_child(btn)
		_popup_buttons[id] = btn
	if mode == "map":
		var random_btn := _button("LOKASI ACAK")
		random_btn.add_theme_font_size_override("font_size", 15)
		random_btn.pressed.connect(func() -> void: _choose_popup_option("random"))
		_options.add_child(random_btn)
		_popup_buttons["random"] = random_btn
	_overlay.visible = true
	_refresh_popup()
	_layout_popup()
	_close_button.grab_focus()

func _choose_popup_option(id: String) -> void:
	if _popup_mode == "weapon":
		Game.select_weapon(id)
	else:
		_map_id = id
	_refresh()

func _refresh_popup() -> void:
	var is_weapon := _popup_mode == "weapon"
	_popup_title.text = "PILIH PELURU" if is_weapon else "PILIH MAP"
	_popup_ship.text = "%s  /  %s" % [Game.get_current_ship().name, Game.get_current_ship()["class"]]
	var selected: String = Game.selected_weapon_id if is_weapon else _map_id
	for id: String in _popup_buttons:
		_set_selected(_popup_buttons[id], id == selected)
	_preview.configure(Game.selected_ship_id, Game.selected_weapon_id, "cyber" if _map_id == "random" else _map_id, _popup_mode)
	_popup_description.text = Game.get_current_weapon().desc if is_weapon else ("Lokasi dipilih secara acak saat misi dimulai." if _map_id == "random" else Game.MAPS[_map_id].desc)

func _close_popup() -> void:
	_overlay.visible = false
	_preview.shots.clear()
	if _return_focus:
		_return_focus.grab_focus()

func _select_ship(id: String) -> void:
	if _deploying or _overlay.visible or id == Game.selected_ship_id:
		return
	_ship_index = Game.SHIPS.keys().find(id)
	Game.select_ship(id)
	_refresh()
	_roster_scroll.ensure_control_visible(_aircraft_buttons[id])
	if _ship_tween and _ship_tween.is_running():
		_ship_tween.kill()
	_ship_image.modulate.a = 0.3
	_ship_tween = create_tween()
	_ship_tween.tween_property(_ship_image, "modulate:a", 1.0, 0.2)

func _switch_ship(step: int) -> void:
	_select_ship(Game.SHIPS.keys()[wrapi(_ship_index + step, 0, Game.SHIPS.size())])

func _on_preview_input(event: InputEvent) -> void:
	if _overlay.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not _dragging:
			_drag_start = event.position
			_drag_index = event.index
			_dragging = true
		elif not event.pressed and event.index == _drag_index:
			_finish_swipe(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			_drag_start = event.position
			_drag_index = -2
			_dragging = true
		elif not event.pressed and _drag_index == -2:
			_finish_swipe(event.position)

func _finish_swipe(position: Vector2) -> void:
	if _dragging:
		var delta := position - _drag_start
		if absf(delta.x) > 60 and absf(delta.x) > absf(delta.y) * 1.25:
			_switch_ship(1 if delta.x < 0 else -1)
	_dragging = false
	_drag_index = -1

func _deploy() -> void:
	if _deploying or _overlay.visible:
		return
	_deploying = true
	_launch.disabled = true
	Game.select_map(_map_id)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _help.visible:
			return
		if _overlay.visible:
			if event.keycode == KEY_ESCAPE:
				_close_popup()
			return
		if event.keycode in [KEY_LEFT, KEY_A]:
			_switch_ship(-1)
		elif event.keycode in [KEY_RIGHT, KEY_D]:
			_switch_ship(1)
		elif event.keycode == KEY_ENTER:
			_deploy()
