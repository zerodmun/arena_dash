class_name Hangar
extends Control
## Landscape hangar: left flight systems, central aircraft, right mission controls.
const ACCENT := ArcadeUI.GOLD
const WHITE := ArcadeUI.TEXT
const MUTED := ArcadeUI.MUTED
var _preview_weapon_id := "plasma"
var _feedback := ""
var _ship_index := 0
var _map_id := "coast"
var _deploying := false
var _ship_image: TextureRect
var _ship_name: Label
var _ship_class: Label
var _counter: Label
var _launch: Button
var _purchase: Button
var _hero: Control
var _bars: Array[ProgressBar] = []
var _stat_labels: Array[Label] = []
var _weapon_card: Button
var _map_card: Button
var _weapon_status: Label
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
var _layout_safe := Rect2()

var _environment: Control
var _header: HBoxContainer
var _header_title: Label
var _record: Label
var _stats_panel: PanelContainer
var _coin_base: PanelContainer
var _stat_headings: Array[Label] = []
var _identity: PanelContainer
var _prev: Button
var _next: Button
var _mission_label: Label

func _ready() -> void:
	SoundEffects.enter_screen("hangar")
	Game.is_running = false
	Input.action_release("fire")
	_map_id = Game.selected_map_id
	_ship_index = maxi(0, Game.SHIPS.keys().find(Game.selected_ship_id))
	_build_ui()
	_refresh()
	I18n.changed.connect(_refresh)
	Game.economy_changed.connect(_refresh)
	get_viewport().size_changed.connect(_adapt_layout)
	_adapt_layout()

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
	# Keep the title and navigation bare; only the balance gets a compact panel.
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 12)
	add_child(_header)
	var row := _header
	_coin_base = PanelContainer.new()
	_coin_base.add_theme_stylebox_override("panel", ArcadeUI.panel(10))
	_coin_base.custom_minimum_size = Vector2(200,64)
	row.add_child(_coin_base)
	var balance := HBoxContainer.new()
	balance.alignment = BoxContainer.ALIGNMENT_CENTER
	balance.add_theme_constant_override("separation",10)
	_coin_base.add_child(balance)
	balance.add_child(_image("res://assets/ui/icons/icon_coin.svg",Vector2(30,30)))
	_record = _label(I18n.t("Coins: %d",[Game.coins]), 18, ACCENT)
	_record.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance.add_child(_record)
	var home := _button("")
	ArcadeUI.icon(home, "button_home")
	home.custom_minimum_size = Vector2(64,64)
	home.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	row.add_child(home)
	var settings := _button("")
	ArcadeUI.icon(settings, "button_settings")
	settings.custom_minimum_size = Vector2(64,64)
	settings.pressed.connect(func() -> void: ArcadeUI.settings(self))
	row.add_child(settings)
	var help := _button("")
	ArcadeUI.icon(help,"button_info")
	help.custom_minimum_size = Vector2(64,64)
	help.tooltip_text = "Flight manual"
	help.pressed.connect(func() -> void: ArcadeUI.help(self))
	row.add_child(help)
	_header_title = _label("HANGAR", 38)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_header_title)
func _build_stats_strip() -> void:
	_stats_panel = PanelContainer.new()
	_stats_panel.add_theme_stylebox_override("panel", ArcadeUI.panel(20))
	add_child(_stats_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	_stats_panel.add_child(column)
	var heading := _label("FLIGHT SYSTEMS",18,ArcadeUI.CYAN)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var row := VBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",12)
	column.add_child(row)
	for title in ["SPEED", "SHIELDS", "FIRE RATE"]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 8)
		row.add_child(box)
		var top := HBoxContainer.new()
		box.add_child(top)
		var name_label := _label(title, 18, ArcadeUI.MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stat_headings.append(name_label)
		top.add_child(name_label)
		var value := _label("", 18, ArcadeUI.TEXT)
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
	ArcadeUI.style_button(_prev)
	ArcadeUI.style_button(_next)
	_prev.pressed.connect(func() -> void: _switch_ship(-1))
	_next.pressed.connect(func() -> void: _switch_ship(1))
	_identity = PanelContainer.new()
	_identity.add_theme_stylebox_override("panel", ArcadeUI.panel(12))
	add_child(_identity)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	_identity.add_child(box)
	_ship_name = _label("", 30)
	_ship_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ship_name)
	_ship_class = _label("", 13, Color("d1dce2"))
	_ship_class.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ship_class)
	_counter = _label("", 13, Color("e4edf4"))
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_counter)

var _pedestal: Texture2D = preload("res://assets/future_updates/hangar/hangar_docking_pedestal.svg")
var _background_art: TextureRect

func _draw_environment() -> void:
	if _background_art == null:
		_background_art=ArcadeUI.image("res://assets/ui/theme/space_landscape.svg",Vector2.ZERO)
		_background_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_background_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_environment.add_child(_background_art)


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
	# Keep the existing footer footprint; use its height for the artwork.
	weapon_row.offset_top = 6
	weapon_row.offset_bottom = -6
	weapon_row.add_theme_constant_override("separation", 8)
	_weapon_icon = _image(Game.get_current_weapon().texture, Vector2(144, 96))
	weapon_row.add_child(_weapon_icon)
	var weapon_box := VBoxContainer.new()
	weapon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_box.add_theme_constant_override("separation", 6)
	weapon_row.add_child(weapon_box)
	weapon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_weapon_card_label = _label("", 16)
	_weapon_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_weapon_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_box.add_child(_weapon_card_label)
	_weapon_status = _label("", 16, ACCENT)
	_weapon_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_box.add_child(_weapon_status)
	_map_card = PlanetButton.new()
	(_map_card as PlanetButton).planet_id = Game.hangar_planet()
	_map_card.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	add_child(_map_card)
	_map_card_label = _label("", 15, Color("b8ccf8"))
	_map_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_map_card_label)
	_purchase = _button("SELECT AIRCRAFT")
	_purchase.add_theme_font_size_override("font_size",17)
	_purchase.custom_minimum_size = Vector2(208,64)
	_purchase.pressed.connect(_purchase_or_select_aircraft)
	add_child(_purchase)
	_launch = _button("DEPLOY MISSION", true)
	_launch.add_theme_font_size_override("font_size",28)
	_launch.custom_minimum_size = Vector2(352,108)
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var face := _launch.get_theme_stylebox(state).duplicate() as StyleBoxTexture
		face.content_margin_left = 24
		face.content_margin_right = 24
		face.content_margin_top = 20
		face.content_margin_bottom = 20
		_launch.add_theme_stylebox_override(state,face)
	_mission_label=_label("",20,ArcadeUI.GOLD)
	_mission_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(_mission_label)
	_launch.pressed.connect(_deploy)
	add_child(_launch)

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
	_modal.add_theme_stylebox_override("panel",ArcadeUI.panel(24))
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
	_preview.size_flags_horizontal=Control.SIZE_FILL
	columns.add_child(_preview)
	var info:=VBoxContainer.new()
	info.custom_minimum_size.x=460
	info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
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
	done.pressed.connect(_confirm_loadout)
	info.add_child(done)

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	# Measure wrapping text at its final width before resolving minimum height.
	if control is Label and control.autowrap_mode != TextServer.AUTOWRAP_OFF:
		control.size.x = rect.size.x
	control.size = rect.size

func _adapt_layout(available := Rect2()) -> void:
	var safe:=available if available.has_area() else ArcadeUI.safe_rect(get_viewport_rect().size)
	_layout_safe=safe
	var vp:=safe.size
	_compact=false
	_counter.visible=true
	_record.visible=true
	# Equal side rails keep the aircraft on the usable screen's center line.
	var margin := 24.0
	var gap := 24.0
	var rail := 352.0
	var footer_y := vp.y - margin - 108.0
	var body_y := 108.0
	var center_left := margin + rail + 8.0
	var center_width := vp.x - center_left * 2.0
	var center_x := vp.x * 0.5
	var right_x := vp.x - margin - rail
	var navigation_width := maxf(428.0,_header.get_combined_minimum_size().x)
	_place(_header,Rect2(vp.x-navigation_width-margin,20,navigation_width,64))
	_place(_header_title,Rect2(margin,26,240,52))
	_header_title.add_theme_font_size_override("font_size",30)
	_place(_identity,Rect2(margin,body_y,rail,108))
	_place(_stats_panel,Rect2(margin,body_y+132,rail,footer_y-body_y-156))
	_place(_weapon_card,Rect2(margin,footer_y,rail,108))
	_place(_hero,Rect2(center_left,92,center_width,footer_y-92))
	_ship_image.offset_left=8
	_ship_image.offset_right=-8
	_ship_image.offset_top=0
	_ship_image.offset_bottom=-12
	# Selection belongs to the aircraft, in a single footer row below its stage.
	_place(_prev,Rect2(center_x-176,footer_y+34,64,64))
	_place(_next,Rect2(center_x+112,footer_y+34,64,64))
	_place(_counter,Rect2(center_x-176,footer_y,352,26))
	_place(_purchase,Rect2(center_x-104,footer_y+34,208,64))
	_counter.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var planet_side := minf(164.0,(footer_y-body_y)*0.34)
	_place(_map_card,Rect2(right_x+(rail-planet_side)*0.5,body_y+12,planet_side,planet_side))
	_place(_map_card_label,Rect2(right_x,body_y+planet_side+28,rail,84))
	_map_card_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_map_card_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_place(_mission_label,Rect2(right_x,footer_y-136,rail,112))
	_mission_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_mission_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_place(_launch,Rect2(right_x,footer_y,rail,108))
	for control in [_header,_header_title,_identity,_stats_panel,_weapon_card,_hero,_prev,_next,_counter,_purchase,_map_card,_map_card_label,_mission_label,_launch]:
		control.position+=safe.position
	_environment.queue_redraw()
	_layout_popup(safe)
	_finish_wrapped_layout.call_deferred()

func _finish_wrapped_layout() -> void:
	# Label shaping updates after width changes; shrink the old wrapped height then.
	# Refit large balances without discarding the current safe-area layout.
	var width := maxf(428.0,_header.get_combined_minimum_size().x)
	_header.size.x=width
	_header.position.x=_layout_safe.end.x-24-width
	_map_card_label.size.y = 84
	_mission_label.size.y = 112
	_mission_label.position.y = _launch.position.y - 24 - _mission_label.size.y

func _layout_popup(available := Rect2()) -> void:
	var safe:=available if available.has_area() else ArcadeUI.safe_rect(get_viewport_rect().size)
	var vp:=safe.size
	_modal.size=Vector2(minf(vp.x-64,1100),minf(vp.y-64,600))
	_modal.position=safe.position+(vp-_modal.size)*0.5

func get_hangar_texture(id: String) -> Texture2D:
	return load(Game.SHIPS[id].texture)

func _refresh() -> void:
	var ship: Dictionary = Game.SHIPS[Game.SHIPS.keys()[_ship_index]]
	_record.text=I18n.t("Coins: %d",[Game.coins])
	_ship_image.texture = get_hangar_texture(ship.id)
	_ship_name.text = ship.name
	_ship_name.add_theme_color_override("font_color", ship.color.lerp(ArcadeUI.TEXT,.35))
	_ship_class.text = I18n.t(ship["class"])
	_identity.tooltip_text = I18n.t(ship.desc)
	var owned := Game.owns_equipment("ship",ship.id)
	var status := I18n.t("EQUIPPED" if ship.id==Game.selected_ship_id else "UNLOCKED") if owned else I18n.t("LOCKED")
	_counter.text = "%02d / %02d • %s" % [_ship_index + 1, Game.SHIPS.size(),status]
	_counter.add_theme_font_size_override("font_size",16)
	_launch.text=I18n.t("DEPLOY MISSION")
	_launch.disabled=not owned or _deploying
	_purchase.disabled=owned and ship.id==Game.selected_ship_id
	_purchase.text=I18n.t("EQUIPPED" if _purchase.disabled else "SELECT AIRCRAFT") if owned else I18n.t("PURCHASE\n%d Coins",[Game.equipment_price("ship",ship.id)])
	_purchase.icon=null
	if not owned:ArcadeUI.icon(_purchase,"badge_lock")
	ArcadeUI.style_button(_purchase,false,owned and ship.id==Game.selected_ship_id)
	_bars[0].value = ship.speed / 500.0 * 100
	_bars[1].value = ship.max_lives / 5.0 * 100
	var effective_rate: float=EquipmentCatalog.firing_interval(ship, Game.get_current_weapon())
	_bars[2].value = (0.30 - effective_rate) / 0.20 * 100
	_stat_labels[0].text = "%d" % ship.speed
	_stat_labels[1].text = I18n.t("%d CELLS",[ship.max_lives])
	_stat_labels[2].text = I18n.t("%.1f / SEC",[1.0 / effective_rate])
	_weapon_card_label.text = I18n.t(Game.get_current_weapon().name)
	_weapon_status.text = I18n.t("EQUIPPED")
	_weapon_card.tooltip_text = I18n.t("WEAPON LOADOUT")
	_weapon_icon.texture = load(Game.get_current_weapon().texture)
	var progress_planet := Game.hangar_planet()
	(_map_card as PlanetButton).configure(progress_planet)
	_map_card_label.text = I18n.t("PLANET CAMPAIGN\n%s\n%s",[Game.MAPS[progress_planet].name,I18n.t("LAST SECURED" if not Game.last_completed_planet.is_empty() else "BEGIN YOUR JOURNEY")])
	_launch.tooltip_text = I18n.t("Deploy to %s",[Game.MAPS[_map_id].name])
	_mission_label.text=I18n.t("MISSION DESTINATION\n%s\n%s",[Game.MAPS[_map_id].name,I18n.t(Campaign.DIFFICULTY[Campaign.index(_map_id)])])
	if not _feedback.is_empty(): _mission_label.text=_feedback
	_finish_wrapped_layout.call_deferred()
	_stage.queue_redraw()
	if _overlay.visible:
		_refresh_popup()

func _set_selected(btn: Button, selected: bool) -> void:
	ArcadeUI.style_button(btn,false,selected)

func _open_popup(mode: String) -> void:
	SoundEffects.play("open")
	_popup_mode = mode
	_preview_weapon_id=Game.selected_weapon_id
	_feedback=""
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
		btn.custom_minimum_size = Vector2(294,64)
		btn.add_theme_font_size_override("font_size",16)
		btn.add_theme_font_size_override("font_size",16)
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
		_preview_weapon_id=id
		_feedback=""
	else:
		_map_id = id
	_refresh()

func _refresh_popup() -> void:
	var is_weapon := _popup_mode == "weapon"
	_popup_title.text = "WEAPON LOADOUT" if is_weapon else "PLANET CAMPAIGN"
	var preview_ship: Dictionary=Game.SHIPS[Game.SHIPS.keys()[_ship_index]]
	_popup_ship.text = "%s  /  %s" % [preview_ship.name,I18n.t(preview_ship["class"])]
	var selected: String = _preview_weapon_id if is_weapon else _map_id
	for id: String in _popup_buttons:
		_set_selected(_popup_buttons[id], id == selected)
		var owned := Game.owns_equipment("weapon",id)
		var state := "EQUIPPED" if id==Game.selected_weapon_id else "SELECTED" if id==selected else "UNLOCKED"
		_popup_buttons[id].text=I18n.t(Game.WEAPONS[id].name)+"\n"+(I18n.t(state) if owned else I18n.t("LOCKED • %d Coins",[Game.equipment_price("weapon",id)]))
		_popup_buttons[id].icon=null
		if not owned:ArcadeUI.icon(_popup_buttons[id],"badge_lock")
		ArcadeUI.style_button(_popup_buttons[id],false,id==selected)
	_preview.configure(Game.SHIPS.keys()[_ship_index], _preview_weapon_id, "cyber" if _map_id == "random" else _map_id, _popup_mode)
	_popup_description.text = I18n.t(Game.WEAPONS[_preview_weapon_id].desc)+"\n"+I18n.t("Coins: %d",[Game.coins])+ ("\n"+_feedback if not _feedback.is_empty() else "")
	_confirm_button.disabled=_preview_weapon_id==Game.selected_weapon_id
	_confirm_button.text=I18n.t("EQUIPPED" if _confirm_button.disabled else "EQUIP WEAPON") if Game.owns_equipment("weapon",_preview_weapon_id) else I18n.t("PURCHASE • %d Coins",[Game.equipment_price("weapon",_preview_weapon_id)])
	_confirm_button.icon=null
	if not Game.owns_equipment("weapon",_preview_weapon_id):ArcadeUI.icon(_confirm_button,"badge_lock")
	ArcadeUI.style_button(_confirm_button,true)
	_confirm_button.add_theme_font_size_override("font_size",18)

func _close_popup() -> void:
	SoundEffects.play("close")
	_overlay.visible = false
	_preview.shots.clear()
	if _return_focus:
		_return_focus.grab_focus()

func _select_ship(id: String) -> void:
	if _deploying or _overlay.visible or id == Game.SHIPS.keys()[_ship_index]:
		return
	_ship_index = Game.SHIPS.keys().find(id)
	_feedback=""
	_refresh()
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
	var candidate: String=Game.SHIPS.keys()[_ship_index]
	if not Game.owns_equipment("ship",candidate):return
	if not Game.select_ship(candidate):
		_feedback=I18n.t("Purchase could not be saved. Try again.")
		_refresh()
		return
	_deploying = true
	_launch.disabled = true
	SoundEffects.play("confirm")
	if not Game.select_level(_map_id):
		_deploying = false
		_launch.disabled = false
		SoundEffects.play("locked")
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

func _purchase_or_select_aircraft() -> void:
	if _deploying or _overlay.visible:return
	var id: String=Game.SHIPS.keys()[_ship_index]
	if Game.owns_equipment("ship",id):
		_feedback="" if Game.select_ship(id) else I18n.t("Purchase could not be saved. Try again.")
	else:
		var result:=Game.purchase_equipment("ship",id)
		_feedback=I18n.t("Aircraft unlocked. Select it to equip.") if result=="purchased" else I18n.t("Not enough coins" if result=="insufficient" else "Purchase could not be saved. Try again.")
		SoundEffects.play("confirm" if result=="purchased" else "locked")
	_refresh()

func _confirm_loadout() -> void:
	if not Game.owns_equipment("weapon",_preview_weapon_id):
		var result:=Game.purchase_equipment("weapon",_preview_weapon_id)
		_feedback=I18n.t("Weapon unlocked. Equip it to use.") if result=="purchased" else I18n.t("Not enough coins" if result=="insufficient" else "Purchase could not be saved. Try again.")
		SoundEffects.play("confirm" if result=="purchased" else "locked")
		_refresh()
		return
	if Game.select_weapon(_preview_weapon_id):
		_feedback=""
		_refresh()
		_close_popup()
	else:
		_feedback=I18n.t("Purchase could not be saved. Try again.")
		_refresh_popup()
