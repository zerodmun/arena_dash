class_name HUD
extends CanvasLayer
## Premium HUD: floating centered command console, dynamic shield matrix,
## ergonomic touch controls, and mission status notifications.

@onready var top_bar_container: MarginContainer = %TopBarContainer
@onready var score_panel: PanelContainer = %ScorePanel
@onready var shield_panel: PanelContainer = %ShieldPanel
@onready var score_label: Label = %ScoreLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var ship_badge: Label = %ShipBadge
@onready var cells_container: HBoxContainer = %CellsHBox
@onready var fullscreen_button: Button = %FullscreenButton

@onready var joystick: GameJoystick = %Joystick
@onready var fire_button: TouchFire = %FireButton

@onready var game_over_panel: Control = %GameOverPanel
@onready var final_score_label: Label = %FinalScoreLabel
@onready var kills_label: Label = %KillsLabel
@onready var pickups_label: Label = %PickupsLabel
@onready var new_record_badge: Label = %NewRecordBadge
@onready var restart_button: Button = %RestartButton
@onready var hangar_return_button: Button = %HangarReturnButton

var _boss_notice: Label
var _objective: Label
var _stars: HBoxContainer
var _result_title: Label
var _next_level: Button
var _prev_score := 0
var _pause_panel: PanelContainer
var _pause_button: Button
var _notice: Label
var _damage_flash: ColorRect
var _notice_tween: Tween
var _notice_key := ""
var _last_lives := 0
var _pause_backdrop: Control
var _resume: Button
var _progress_feedback: Label
var _objective_key:=Vector2i(-1,-1)
var _boss_key:=Vector3i(-1,-1,-1)


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_mission_controls()
    _build_results()
    I18n.changed.connect(_refresh_language)
    Game.preferences_changed.connect(_apply_touch_layout)
    get_viewport().size_changed.connect(_apply_touch_layout)
    move_child(_pause_backdrop,get_child_count()-1)
    Game.score_changed.connect(_on_score_changed)
    Game.lives_changed.connect(_on_lives_changed)
    Game.game_over.connect(_on_game_over)
    Game.mission_completed.connect(_on_mission_completed)
    Game.ui_mode_changed.connect(_on_ui_mode_changed)

    if restart_button:
        restart_button.pressed.connect(_on_start_pressed)
    if hangar_return_button:
        hangar_return_button.pressed.connect(_on_return_to_hangar)

    fire_button.button_down.connect(_on_fire_down)
    fire_button.button_up.connect(_on_fire_up)

    if fullscreen_button:
        fullscreen_button.pressed.connect(_on_fullscreen_pressed)

    game_over_panel.visible = false

    _apply_ui_mode(Game.is_mobile_ui)
    _refresh_best_scores()
    _update_badges()
    _rebuild_shield_cells()
    _on_score_changed(Game.score)

    # Launch Game
    _result_title.text = "MISSION TERMINATED"
    _progress_feedback.visible=false
    _stars.visible = false
    _next_level.visible = false
    Game.start()
    _update_badges()
    _objective_key=Vector2i(-1,-1)
    _boss_key=Vector3i(-1,-1,-1)
    _last_lives = Game.lives
    _show_notice("MISSION STARTED • WATCH FOR MOVING COVER")


func _on_ui_mode_changed(is_mobile: bool) -> void:
    _apply_ui_mode(is_mobile)
    _update_badges()
    _rebuild_shield_cells()


func _apply_ui_mode(is_mobile: bool) -> void:
    # Touch controls: only active in mobile mode
    joystick.visible = is_mobile
    fire_button.visible = is_mobile

    # Fullscreen toggle: only for desktop/browser
    if fullscreen_button:
        var on_native_mobile: bool = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
        fullscreen_button.visible = not is_mobile and not on_native_mobile

    # Top bar container responsive margins
    if top_bar_container:
        if is_mobile:
            top_bar_container.add_theme_constant_override("margin_left", 16)
            top_bar_container.add_theme_constant_override("margin_right", 16)
            top_bar_container.add_theme_constant_override("margin_top", 12)
        else:
            top_bar_container.add_theme_constant_override("margin_left", 32)
            top_bar_container.add_theme_constant_override("margin_right", 32)
            top_bar_container.add_theme_constant_override("margin_top", 16)

    # Typography styling
    UIStyler.style_label(score_label, 28, Color.WHITE, 2, ArcadeUI.INK)
    UIStyler.style_label(high_score_label, 14, Color(0.98, 0.8, 0.22), 2)
    UIStyler.style_label(ship_badge, 15 if is_mobile else 14, Color(0.38, 0.82, 1.0, 0.95), 2)

    # GameOver hardcoded styling
    UIStyler.style_label(final_score_label, 28, Color.WHITE, 2, ArcadeUI.INK)
    UIStyler.style_label(kills_label, 20 if is_mobile else 18, Color(0.85, 0.9, 1.0, 0.9), 2)
    UIStyler.style_label(pickups_label, 20 if is_mobile else 18, Color(0.85, 0.9, 1.0, 0.9), 2)
    UIStyler.style_badge(new_record_badge, Color(1.0, 0.85, 0.2), is_mobile)
    UIStyler.style_button(hangar_return_button, 20 if is_mobile else 18, Color(0.8, 0.9, 1.0), 56)
    UIStyler.style_button(restart_button, 22 if is_mobile else 20, Color.WHITE, 56)

    _apply_touch_layout()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if has_node("FlightDialog"): return
        if event.keycode in [KEY_ESCAPE, KEY_P] and Game.is_running:
            _toggle_pause()
        elif event.keycode == KEY_R and game_over_panel.visible:
            _on_start_pressed()


func _refresh_best_scores() -> void:
    high_score_label.text = I18n.t("BEST: %d",[Game.high_score])


func _update_badges() -> void:
    var ship := Game.get_current_ship()
    var map_info := Game.get_current_map()
    ship_badge.text = String(ship.get("name", "VALKYRIE")).to_upper() if Game.is_mobile_ui else "%s // %s" % [String(ship.get("name", "VALKYRIE")).to_upper(), String(map_info.get("name", "CYBER MATRIX")).to_upper()]
    ship_badge.add_theme_color_override("font_color", ship.get("color", Color(0.22, 0.74, 1.0)))


func _rebuild_shield_cells() -> void:
    for child in cells_container.get_children():
        child.queue_free()

    var ship := Game.get_current_ship()
    var max_lives: int = int(ship.get("max_lives", 3))
    var ship_color: Color = ship.get("color", Color(0.22, 0.84, 1.0))
    var is_mob: bool = Game.is_mobile_ui
    var cell_size: Vector2 = Vector2(40, 18) if is_mob else Vector2(34, 16)

    for i in range(max_lives):
        var cell := ColorRect.new()
        cell.custom_minimum_size = cell_size
        cell.color = ship_color
        cells_container.add_child(cell)

    _on_lives_changed(Game.lives)


func _on_fullscreen_pressed() -> void:
    var input_setup := get_node_or_null("/root/InputSetup")
    if input_setup and input_setup.has_method("toggle_fullscreen"):
        input_setup.toggle_fullscreen()
    else:
        var mode := DisplayServer.window_get_mode()
        if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_start_pressed() -> void:
    get_tree().paused = false
    _pause_button.visible = true
    _notice.visible = true
    _objective.visible = true
    _pause_panel.visible=false
    _pause_backdrop.visible=false
    _apply_ui_mode(Game.is_mobile_ui)
    game_over_panel.visible = false
    _result_title.text = "MISSION TERMINATED"
    _progress_feedback.visible=false
    _stars.visible = false
    _next_level.visible = false
    Game.start()
    _update_badges()
    _objective_key=Vector2i(-1,-1)
    _boss_key=Vector3i(-1,-1,-1)
    _last_lives = Game.lives
    _show_notice("MISSION STARTED")
    _rebuild_shield_cells()


func _on_return_to_hangar() -> void:
    get_tree().paused = false
    Game.is_running = false
    Game.flush_save()
    Input.action_release("fire")
    get_tree().change_scene_to_file("res://scenes/hangar.tscn")


func _on_fire_down() -> void:
    Input.action_press("fire")
    var tw := create_tween()
    tw.tween_property(fire_button, "scale", Vector2(0.9, 0.9), 0.05)


func _on_fire_up() -> void:
    Input.action_release("fire")
    var tw := create_tween()
    tw.tween_property(fire_button, "scale", Vector2(1.0, 1.0), 0.08)


func _on_score_changed(value: int) -> void:
    score_label.text = "%05d" % value
    high_score_label.text = I18n.t("BEST: %d",[Game.high_score])

    if value > _prev_score:
        var tw := create_tween()
        tw.tween_property(score_label, "scale", Vector2(1.15, 1.15), 0.06)
        tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.08)
    _prev_score = value


func _on_lives_changed(value: int) -> void:
    if value < _last_lives:
        _damage_flash.color.a = 0.22
        create_tween().tween_property(_damage_flash, "color:a", 0.0, 0.35)
        if value == 1:
            _show_notice("SHIELDS CRITICAL • EVADE HOSTILE DRONES")
    _last_lives = value
    var ship := Game.get_current_ship()
    var ship_color: Color = ship.get("color", Color(0.22, 0.84, 1.0))
    var cells := cells_container.get_children()

    for i in cells.size():
        var cell := cells[i] as ColorRect
        if cell == null or cell.is_queued_for_deletion():
            continue
        if i < value:
            cell.color = ship_color
        else:
            cell.color = Color(0.2, 0.25, 0.35, 0.35)


func _on_game_over() -> void:
    Input.action_release("fire")
    _pause_button.visible = false
    _notice.visible = false
    _objective.visible = false
    joystick.visible = false
    fire_button.visible = false
    _result_title.text = "MISSION TERMINATED"
    _progress_feedback.visible=false
    _stars.visible = false
    _next_level.visible = false
    restart_button.text = "RETRY MISSION"
    joystick._reset()
    final_score_label.text = I18n.t("Final Score: %d",[Game.score])
    kills_label.text = I18n.t("Drones Eliminated: %d",[Game.enemies_destroyed])
    pickups_label.text = I18n.t("Energy Crystals: %d",[Game.pickups_collected])

    var is_record := Game.score > 0 and Game.score >= Game.high_score
    new_record_badge.visible = is_record
    _refresh_best_scores()
    game_over_panel.visible = true


func _build_mission_controls() -> void:
    score_panel.add_theme_stylebox_override("panel",ArcadeUI.surface(12))
    shield_panel.add_theme_stylebox_override("panel",ArcadeUI.surface(12))
    ArcadeUI.style_button(fullscreen_button)
    _pause_button=ArcadeUI.button("","button_pause")
    _pause_button.custom_minimum_size=Vector2(64,64)
    _pause_button.tooltip_text="Pause / resume (Esc or P)"
    _pause_button.pressed.connect(_toggle_pause)
    top_bar_container.get_child(0).add_child(_pause_button)
    _damage_flash=ColorRect.new()
    _damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _damage_flash.color=Color(1.0,0.15,0.1,0)
    _damage_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(_damage_flash)
    _notice=ArcadeUI.label("",18,ArcadeUI.MUTED)
    _notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    _notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_child(_notice)
    _pause_backdrop=Control.new()
    _pause_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _pause_backdrop.visible=false
    add_child(_pause_backdrop)
    var dim:=ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color=Color(0.025,0.015,0.09,0.82)
    _pause_backdrop.add_child(dim)
    _pause_panel=PanelContainer.new()
    _pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    _pause_panel.offset_left=-440
    _pause_panel.offset_right=440
    _pause_panel.offset_top=-180
    _pause_panel.offset_bottom=180
    _pause_panel.add_theme_stylebox_override("panel",ArcadeUI.surface(28))
    _pause_panel.visible=false
    _pause_backdrop.add_child(_pause_panel)
    var columns:=HBoxContainer.new()
    columns.add_theme_constant_override("separation",32)
    _pause_panel.add_child(columns)
    var info:=VBoxContainer.new()
    info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation",16)
    columns.add_child(info)
    info.add_child(ArcadeUI.label("FLIGHT PAUSED",32,ArcadeUI.GOLD))
    info.add_child(ArcadeUI.image(Game.get_current_ship().texture,Vector2(300,170)))
    info.add_child(ArcadeUI.label("Take a breath. Your mission is waiting.",18,ArcadeUI.MUTED))
    var actions:=VBoxContainer.new()
    actions.custom_minimum_size.x=330
    actions.alignment=BoxContainer.ALIGNMENT_CENTER
    actions.add_theme_constant_override("separation",16)
    columns.add_child(actions)
    _resume=ArcadeUI.button("RESUME FLIGHT","button_play",true)
    _resume.pressed.connect(_toggle_pause)
    actions.add_child(_resume)
    var settings:=ArcadeUI.button("SETTINGS","button_settings")
    settings.pressed.connect(func() -> void: ArcadeUI.settings(self))
    actions.add_child(settings)
    var hangar:=ArcadeUI.button("RETURN TO HANGAR","button_home")
    hangar.pressed.connect(_on_return_to_hangar)
    actions.add_child(hangar)
    ArcadeUI.focus_loop([_resume,settings,hangar])

func _toggle_pause() -> void:
    if not Game.is_running:
        return
    get_tree().paused = not get_tree().paused
    if get_tree().paused:Game.flush_save()
    _pause_panel.visible = get_tree().paused
    _pause_backdrop.visible = get_tree().paused
    Input.action_release("fire")
    joystick._reset()
    joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE if get_tree().paused else Control.MOUSE_FILTER_PASS
    fire_button.disabled = get_tree().paused
    if _pause_panel.visible:
        _resume.grab_focus()
    else:
        _pause_button.release_focus()

func _show_notice(text: String) -> void:
    if _notice_tween and _notice_tween.is_running():
        _notice_tween.kill()
    _notice_key=text
    _notice.text = I18n.t(text)
    _notice.modulate.a = 1.0
    _notice_tween = create_tween()
    _notice_tween.tween_interval(3.0)
    _notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.6)

func _process(_delta: float) -> void:
    var boss_key:=Vector3i(Game.boss_health,Game.boss_max_health,int(Game.boss_defeated))
    _boss_notice.visible=Game.is_running and Campaign.has_boss(Game.selected_map_id)
    if boss_key!=_boss_key:
        _boss_key=boss_key
        _boss_notice.text=I18n.t("GUARDIAN  %d / %d",[Game.boss_health,Game.boss_max_health]) if Game.boss_max_health>0 else I18n.t("GUARDIAN APPROACHES AT %d DRONES",[Campaign.target(Game.selected_map_id)/2])
        if Game.boss_defeated:_boss_notice.text=I18n.t("GUARDIAN DEFEATED / CLEAR REMAINING DRONES")
    var key:=Vector2i(int(Game.mission_elapsed),Game.enemies_destroyed)
    if key!=_objective_key:
        _objective_key=key
        _objective.text=I18n.t("PLANET %02d  /  %s     •     DRONES %02d / %02d     •     %02d:%02d",[Campaign.index(Game.selected_map_id)+1,I18n.t(Campaign.DIFFICULTY[Campaign.index(Game.selected_map_id)]),Game.enemies_destroyed,Campaign.target(Game.selected_map_id),key.x/60,key.x%60])

func _build_results() -> void:
    _boss_notice=ArcadeUI.label("",18,Color("ffa5d7"))
    _boss_notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    _boss_notice.offset_top=156
    _boss_notice.offset_bottom=184
    _boss_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_child(_boss_notice)
    _objective=ArcadeUI.label("",18,ArcadeUI.GOLD)
    _objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    _objective.offset_top=94
    _objective.offset_bottom=120
    _objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    add_child(_objective)
    _notice.offset_top=124
    _notice.offset_bottom=152
    var modal: PanelContainer=game_over_panel.get_node("CenterContainer/Modal")
    modal.add_theme_stylebox_override("panel",ArcadeUI.surface(28))
    modal.custom_minimum_size=Vector2(1060,480)
    var old: VBoxContainer=modal.get_node("VBox")
    _result_title=old.get_node("GameOverLabel")
    _result_title.add_theme_constant_override("shadow_outline_size",0)
    _result_title.add_theme_constant_override("shadow_offset_y",0)
    UIStyler.style_label(_result_title,30,ArcadeUI.GOLD,0)
    var columns:=HBoxContainer.new()
    columns.add_theme_constant_override("separation",32)
    modal.add_child(columns)
    var info:=VBoxContainer.new()
    info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation",18)
    info.alignment=BoxContainer.ALIGNMENT_CENTER
    columns.add_child(info)
    for label in [_result_title,final_score_label,kills_label,pickups_label,new_record_badge]:
        label.reparent(info)
        label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
        label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    _progress_feedback=ArcadeUI.label("",18,ArcadeUI.GOLD)
    _progress_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    _progress_feedback.visible=false
    info.add_child(_progress_feedback)
    var actions:=VBoxContainer.new()
    actions.custom_minimum_size.x=310
    actions.add_theme_constant_override("separation",14)
    actions.alignment=BoxContainer.ALIGNMENT_CENTER
    columns.add_child(actions)
    _stars=HBoxContainer.new()
    _stars.alignment=BoxContainer.ALIGNMENT_CENTER
    _stars.visible=false
    actions.add_child(_stars)
    _next_level=ArcadeUI.button("NEXT PLANET","button_forward",true)
    _next_level.visible=false
    _next_level.pressed.connect(_advance)
    actions.add_child(_next_level)
    restart_button.reparent(actions)
    hangar_return_button.reparent(actions)
    for btn in [restart_button,hangar_return_button]:
        btn.custom_minimum_size=Vector2(310,64)
        ArcadeUI.style_button(btn)
    ArcadeUI.icon(restart_button,"button_restart")
    ArcadeUI.icon(hangar_return_button,"button_home")
    hangar_return_button.text="RETURN TO HANGAR"
    restart_button.text="RETRY MISSION"
    ArcadeUI.focus_loop([_next_level,restart_button,hangar_return_button])
    modal.remove_child(old)
    old.queue_free()
    game_over_panel.get_node("Dim").color=Color(0.025,0.015,0.09,0.85)

func _on_mission_completed() -> void:
    _on_game_over()
    var rating:=Game.last_attempt_stars
    var best:=Game.best_stars(Game.selected_map_id)
    _result_title.text="MISSION COMPLETE" if rating<3 else ("CAMPAIGN COMPLETE" if Campaign.index(Game.selected_map_id)==7 else "PLANET SECURED")
    for child in _stars.get_children():
        _stars.remove_child(child)
        child.queue_free()
    for i in 3:
        _stars.add_child(ArcadeUI.image(ArcadeUI.KIT+("badge_star_active.svg" if i<rating else "badge_star_inactive.svg"),Vector2(60,60)))
    _stars.visible=true
    _next_level.visible=Campaign.index(Game.selected_map_id)<7
    var next:=Campaign.index(Game.selected_map_id)+1
    _next_level.disabled=rating<3 or next>=Campaign.ORDER.size() or not Game.is_level_unlocked(Campaign.ORDER[next])
    ArcadeUI.style_button(restart_button,rating<3)
    kills_label.text=I18n.t("Attempt: %d / 3 stars  •  Best: %d / 3",[rating,best])
    pickups_label.text=I18n.t("Time: %d s  •  Damage taken: %d",[int(Game.mission_elapsed),Game.mission_damage])
    _progress_feedback.text=I18n.t("Earn 3 stars to unlock the next planet. Retry this mission." if rating<3 else "Three-star clear! Progress saved.")+"\n"+I18n.t("3 stars: complete objectives, take at most %d damage, finish within %d s.",[Campaign.damage_budget(Game.selected_ship_id),int(Campaign.par_time(Game.selected_map_id))])
    _progress_feedback.visible=true
    restart_button.text="RETRY MISSION" if rating<3 else "REPLAY PLANET"
    if _next_level.visible and not _next_level.disabled:_next_level.grab_focus()
    else:restart_button.grab_focus()

func _advance() -> void:
    var next := Campaign.index(Game.selected_map_id) + 1
    if next < Campaign.ORDER.size() and Game.select_level(Campaign.ORDER[next]):
        get_tree().paused = false
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _refresh_language() -> void:
    _refresh_best_scores()
    _objective_key=Vector2i(-1,-1)
    _boss_key=Vector3i(-1,-1,-1)
    _process(0)
    _notice.text=I18n.t(_notice_key)
    if game_over_panel.visible:
        if Game.mission_won: _on_mission_completed()
        else: _on_game_over()
func _apply_touch_layout() -> void:
    if not is_instance_valid(fire_button) or not is_instance_valid(joystick): return
    var resolved:=TouchLayout.resolved(Game.control_layout,get_viewport().get_visible_rect().size)
    var fire: Dictionary=resolved.fire
    fire_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    fire_button.position=fire.center-Vector2.ONE*fire.diameter*0.5
    fire_button.size=Vector2.ONE*fire.diameter
    fire_button.pivot_offset=fire_button.size*0.5
    fire_button.modulate.a=fire.opacity
    fire_button.disabled=get_tree().paused
    joystick.apply_layout(resolved.joystick)
