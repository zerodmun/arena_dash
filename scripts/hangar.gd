class_name Hangar
extends Control
## Reference-inspired hangar: top stats, central 2D aircraft and bottom loadout controls.
const ACCENT := ArcadeUI.GOLD
const WHITE := ArcadeUI.TEXT
const MUTED := ArcadeUI.MUTED
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
var _confirm_button: Button
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
var _mission_label: Label

func _ready() -> void:
	Game.is_running = false
	Input.action_release("fire")
	_map_id = Game.selected_map_id
	_ship_index = maxi(0, Game.SHIPS.keys().find(Game.selected_ship_id))
	_build_ui()
	_refresh()
	I18n.changed.connect(_refresh)
	get_viewport().size_changed.connect(_adapt_layout)
	_adapt_layout()
	_roster_scroll.call_deferred("ensure_control_visible", _aircraft_buttons[Game.selected_ship_id])

func _surface(bg: Color = ArcadeUI.INK, border: Color = ArcadeUI.BORDER, margin: float = 20) -> StyleBoxFlat:
	var style := ArcadeUI.surface(margin)
	style.bg_color = bg
	style.border_color = border
	return style

func _label(text: String, font_size := 18, color: Color = WHITE) -> Label:
	return ArcadeUI.label(text,maxi(font_size,16),color)

func _button(text: String, primary := false) -> Button:
	return ArcadeUI.button(text,"",primary)

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
	_header.add_theme_stylebox_override("panel", ArcadeUI.surface(12))
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
	_record = _label(I18n.t("BEST  %05d",[Game.high_score]), 17, ACCENT)
	row.add_child(_record)
	var home := _button("")
	ArcadeUI.icon(home, "button_home")
	home.custom_minimum_size.x = 60
	home.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	row.add_child(home)
	var settings := _button("")
	ArcadeUI.icon(settings, "button_settings")
	settings.custom_minimum_size.x = 60
	settings.pressed.connect(func() -> void: ArcadeUI.settings(self))
	row.add_child(settings)
	var help := _button("")
	ArcadeUI.icon(help,"button_info")
	help.custom_minimum_size = Vector2(50, 48)
	help.tooltip_text = "Flight manual"
	help.pressed.connect(func() -> void: ArcadeUI.help(self))
	row.add_child(help)
	_header_title = _label("HANGAR", 38)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_header_title)
func _build_stats_strip() -> void:
	_stats_badge = PanelContainer.new()
	_stats_badge.add_theme_stylebox_override("panel", ArcadeUI.surface(8))
	add_child(_stats_badge)
	var badge := _label("FLIGHT SYSTEMS", 18, ArcadeUI.CYAN)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_badge.add_child(badge)
	_stats_panel = PanelContainer.new()
	_stats_panel.add_theme_stylebox_override("panel", ArcadeUI.surface(18))
	add_child(_stats_panel)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_stats_panel.add_child(row)
	for title in ["SPEED", "SHIELDS", "FIRE RATE"]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 6)
		row.add_child(box)
		var top := HBoxContainer.new()
		box.add_child(top)
		var name_label := _label(title, 16, ArcadeUI.MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stat_headings.append(name_label)
		top.add_child(name_label)
		var value := _label("", 16, ArcadeUI.TEXT)
		_stat_labels.append(value)
		top.add_child(value)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 12
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _surface(Color("202845"),ArcadeUI.BORDER,0))
		bar.add_theme_stylebox_override("fill", _surface(ArcadeUI.CYAN,ArcadeUI.CYAN,0))
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
		add_child(arrow)
	ArcadeUI.icon(_prev, "button_back")
	ArcadeUI.icon(_next, "button_forward")
	_prev.text = ""
	_next.text = ""
	_prev.pressed.connect(func() -> void: _switch_ship(-1))
	_next.pressed.connect(func() -> void: _switch_ship(1))
	_identity = PanelContainer.new()
	_identity.add_theme_stylebox_override("panel", ArcadeUI.surface(12))
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

var _pedestal: Texture2D = preload("res://assets/future_updates/hangar/hangar_docking_pedestal.svg")
var _env_texture: Texture2D
var _background_art: TextureRect

func _draw_environment() -> void:
	var w := _environment.size.x
	var h := _environment.size.y
	if w <= 0 or h <= 0:
		return
	if _env_texture == null:
		_env_texture = load("res://assets/future_updates/hangar/hangar_starry_void.svg")
	_environment.draw_rect(Rect2(0, 0, w, h), Color("050716"))
	var scale_factor := h / float(_env_texture.get_height())
	var image_size := _env_texture.get_size() * scale_factor
	if _background_art == null:
		_background_art = _image("res://assets/future_updates/hangar/hangar_starry_void.svg", Vector2.ZERO)
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float fade=smoothstep(0.0,0.2,UV.x)*smoothstep(0.0,0.2,1.0-UV.x); COLOR=vec4(c.rgb,c.a*fade); }"
		var material := ShaderMaterial.new()
		material.shader = shader
		_background_art.material = material
		_environment.add_child(_background_art)
	_background_art.position = Vector2((w - image_size.x) / 2, 0)
	_background_art.size = image_size
	for i in 90:
		var pos := Vector2(fmod(i * 317.73, w), fmod(i * 151.21, h))
		_environment.draw_circle(pos, 1.2, Color(0.5, 0.7, 1.0, 0.35))

func _draw_stage() -> void:
	var center := _stage.size * Vector2(0.5, 0.73)
	if _stage.size.x <= 0 or _stage.size.y <= 0:
		return
	var pedestal := _pedestal
	var width := _stage.size.x * 0.5
	var extent := Vector2(width, width * float(pedestal.get_height()) / float(pedestal.get_width()))
	_stage.draw_texture_rect(pedestal, Rect2(center - extent * Vector2(0.5, 0.32), extent), false)

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
	weapon_box.add_child(_label("WEAPON LOADOUT", 12, ACCENT))
	_weapon_card_label = _label("", 15)
	weapon_box.add_child(_weapon_card_label)
	weapon_row.add_child(_label("›", 24))
	_map_card = PlanetButton.new()
	(_map_card as PlanetButton).planet_id = Game.hangar_planet()
	_map_card.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	add_child(_map_card)
	_map_card_label = _label("", 15, Color("b8ccf8"))
	_map_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_map_card_label)
	_launch = _button("DEPLOY MISSION", true)
	_launch.add_theme_font_size_override("font_size",22)
	_mission_label=_label("",20,ArcadeUI.GOLD)
	_mission_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(_mission_label)
	_launch.pressed.connect(_deploy)
	add_child(_launch)
	_hint = _label("SWIPE / A–D TO SELECT AIRCRAFT", 13, Color("d8e3e9"))
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
	_overlay=Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible=false
	add_child(_overlay)
	var dim:=ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color=Color(0.025,0.015,0.09,0.85)
	_overlay.add_child(dim)
	_modal=PanelContainer.new()
	_modal.add_theme_stylebox_override("panel",ArcadeUI.surface(24))
	_overlay.add_child(_modal)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",20)
	_modal.add_child(box)
	var top:=HBoxContainer.new()
	box.add_child(top)
	_popup_title=_label("",28,ACCENT)
	_popup_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(_popup_title)
	_close_button=ArcadeUI.button("","button_close")
	_close_button.custom_minimum_size=Vector2(64,64)
	_close_button.pressed.connect(_close_popup)
	top.add_child(_close_button)
	var columns:=HBoxContainer.new()
	columns.add_theme_constant_override("separation",24)
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	_preview=HangarPreview.new()
	_preview.custom_minimum_size=Vector2(430,280)
	_preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_child(_preview)
	var info:=VBoxContainer.new()
	info.custom_minimum_size.x=460
	info.add_theme_constant_override("separation",14)
	columns.add_child(info)
	_popup_ship=_label("",16,MUTED)
	info.add_child(_popup_ship)
	info.add_child(_label("SELECT WEAPON / LIVE PREVIEW",16,ArcadeUI.CYAN))
	_options=HFlowContainer.new()
	_options.add_theme_constant_override("h_separation",10)
	_options.add_theme_constant_override("v_separation",10)
	info.add_child(_options)
	_popup_description=_label("",18,MUTED)
	_popup_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_popup_description.size_flags_vertical=Control.SIZE_EXPAND_FILL
	info.add_child(_popup_description)
	var done:=_button("CONFIRM LOADOUT",true)
	_confirm_button=done
	done.pressed.connect(_close_popup)
	info.add_child(done)

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _adapt_layout() -> void:
	var vp:=get_viewport_rect().size
	_compact=false
	_counter.visible=true
	_profile.visible=true
	_record.visible=vp.x>1400
	_place(_header,Rect2(16,12,vp.x-32,78))
	_place(_header_title,Rect2(vp.x*0.5-120,22,240,52))
	_header_title.add_theme_font_size_override("font_size",30)
	_place(_identity,Rect2(24,112,276,100))
	_place(_stats_badge,Rect2(24,228,276,46))
	_place(_stats_panel,Rect2(24,282,276,218))
	_place(_weapon_card,Rect2(24,518,276,76))
	_place(_hero,Rect2(318,110,vp.x-630,vp.y-246))
	_ship_image.offset_left=36
	_ship_image.offset_right=-36
	_ship_image.offset_top=0
	_ship_image.offset_bottom=-45
	_place(_prev,Rect2(320,vp.y*0.48,64,64))
	_place(_next,Rect2(vp.x-384,vp.y*0.48,64,64))
	_place(_map_card,Rect2(vp.x-235,118,140,140))
	_place(_map_card_label,Rect2(vp.x-296,274,272,100))
	_map_card_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_place(_mission_label,Rect2(vp.x-296,398,272,88))
	_mission_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_place(_launch,Rect2(vp.x-296,518,272,76))
	_place(_roster_scroll,Rect2(24,vp.y-106,vp.x-48,92))
	_hint.visible=false
	_environment.queue_redraw()
	_layout_popup()

func _layout_popup() -> void:
	var vp:=get_viewport_rect().size
	_modal.size=Vector2(minf(vp.x-64,1100),minf(vp.y-64,500))
	_modal.position=(vp-_modal.size)*0.5

func get_hangar_texture(id: String) -> Texture2D:
	return load(Game.SHIPS[id].texture)

func _refresh() -> void:
	var ship := Game.get_current_ship()
	_record.text=I18n.t("BEST  %05d",[Game.high_score])
	_ship_image.texture = get_hangar_texture(ship.id)
	_ship_name.text = ship.name
	_ship_name.add_theme_color_override("font_color", ship.color)
	_ship_class.text = I18n.t(ship["class"])
	_identity.tooltip_text = I18n.t(ship.desc)
	_counter.text = "%02d / %02d" % [_ship_index + 1, Game.SHIPS.size()]
	_bars[0].value = ship.speed / 500.0 * 100
	_bars[1].value = ship.max_lives / 5.0 * 100
	_bars[2].value = (0.30 - ship.fire_rate) / 0.20 * 100
	_stat_labels[0].text = "%d" % ship.speed
	_stat_labels[1].text = I18n.t("%d CELLS",[ship.max_lives])
	_stat_labels[2].text = I18n.t("%.1f / SEC",[1.0 / ship.fire_rate])
	for id: String in _aircraft_buttons:
		_set_selected(_aircraft_buttons[id], id == ship.id)
	_weapon_card_label.text = Game.get_current_weapon().name
	_weapon_icon.texture = load(Game.get_current_weapon().texture)
	var progress_planet := Game.hangar_planet()
	(_map_card as PlanetButton).configure(progress_planet)
	_map_card_label.text = I18n.t("PLANET CAMPAIGN\n%s\n%s",[Game.MAPS[progress_planet].name,I18n.t("LAST SECURED" if not Game.last_completed_planet.is_empty() else "BEGIN YOUR JOURNEY")])
	_launch.tooltip_text = I18n.t("Deploy to %s",[Game.MAPS[_map_id].name])
	_mission_label.text=I18n.t("MISSION DESTINATION\n%s\n%s",[Game.MAPS[_map_id].name,I18n.t(Campaign.DIFFICULTY[Campaign.index(_map_id)])])
	_stage.queue_redraw()
	if _overlay.visible:
		_refresh_popup()

func _set_selected(btn: Button, selected: bool) -> void:
	ArcadeUI.style_button(btn,false,selected)

func _open_popup(mode: String) -> void:
	_popup_mode = mode
	_return_focus = _weapon_card if mode == "weapon" else _map_card
	_dragging = false
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	_popup_buttons.clear()
	if mode == "map":
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
		return
	var catalog: Dictionary = Game.WEAPONS
	for id: String in catalog:
		var btn := _button(catalog[id].name)
		btn.custom_minimum_size = Vector2(215,64)
		btn.add_theme_font_size_override("font_size",18)
		btn.pressed.connect(func() -> void: _choose_popup_option(id))
		_options.add_child(btn)
		_popup_buttons[id] = btn
	if mode == "map":
		var random_btn := _button("RANDOM LOCATION")
		random_btn.add_theme_font_size_override("font_size", 15)
		random_btn.pressed.connect(func() -> void: _choose_popup_option("random"))
		_options.add_child(random_btn)
		_popup_buttons["random"] = random_btn
	_overlay.visible = true
	_refresh_popup()
	_layout_popup()
	var focus_buttons: Array[Button]=[_close_button]
	for btn: Button in _popup_buttons.values(): focus_buttons.append(btn)
	focus_buttons.append(_confirm_button)
	ArcadeUI.focus_loop(focus_buttons)
	for frame in 2: await get_tree().process_frame
	_layout_popup()
	_close_button.grab_focus()
	if not Game.reduced_motion:
		_modal.modulate.a=0
		create_tween().tween_property(_modal,"modulate:a",1.0,0.16)

func _choose_popup_option(id: String) -> void:
	if _popup_mode == "weapon":
		Game.select_weapon(id)
	else:
		_map_id = id
	_refresh()

func _refresh_popup() -> void:
	var is_weapon := _popup_mode == "weapon"
	_popup_title.text = "WEAPON LOADOUT" if is_weapon else "PLANET CAMPAIGN"
	_popup_ship.text = "%s  /  %s" % [Game.get_current_ship().name,I18n.t(Game.get_current_ship()["class"])]
	var selected: String = Game.selected_weapon_id if is_weapon else _map_id
	for id: String in _popup_buttons:
		_set_selected(_popup_buttons[id], id == selected)
	_preview.configure(Game.selected_ship_id, Game.selected_weapon_id, "cyber" if _map_id == "random" else _map_id, _popup_mode)
	_popup_description.text = I18n.t(Game.get_current_weapon().desc if is_weapon else Game.MAPS[_map_id].desc)

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
	if not Game.reduced_motion:
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
	if not Game.select_level(_map_id):
		_deploying = false
		_launch.disabled = false
		return
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if has_node("FlightDialog"):
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
