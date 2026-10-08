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
@onready var fire_button: TextureButton = %FireButton

@onready var game_over_panel: Control = %GameOverPanel
@onready var final_score_label: Label = %FinalScoreLabel
@onready var kills_label: Label = %KillsLabel
@onready var pickups_label: Label = %PickupsLabel
@onready var new_record_badge: Label = %NewRecordBadge
@onready var restart_button: Button = %RestartButton
@onready var hangar_return_button: Button = %HangarReturnButton

var _prev_score := 0
var _pause_panel: PanelContainer
var _pause_button: Button
var _notice: Label
var _damage_flash: ColorRect
var _notice_tween: Tween
var _last_lives := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_mission_controls()
	Game.score_changed.connect(_on_score_changed)
	Game.lives_changed.connect(_on_lives_changed)
	Game.game_over.connect(_on_game_over)
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
	Game.start()
	_last_lives = Game.lives
	_show_notice("MISI DIMULAI • Waspadai penghalang bergerak")


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
	UIStyler.style_label(score_label, 34 if is_mobile else 28, Color.WHITE, 6, Color(0, 0, 0, 0.95))
	UIStyler.style_label(high_score_label, 14, Color(0.98, 0.8, 0.22), 4)
	UIStyler.style_label(ship_badge, 15 if is_mobile else 14, Color(0.38, 0.82, 1.0, 0.95), 4)

	# GameOver hardcoded styling
	UIStyler.style_label(final_score_label, 38 if is_mobile else 32, Color.WHITE, 6, Color(0, 0, 0, 0.95))
	UIStyler.style_label(kills_label, 20 if is_mobile else 18, Color(0.85, 0.9, 1.0, 0.9), 4)
	UIStyler.style_label(pickups_label, 20 if is_mobile else 18, Color(0.85, 0.9, 1.0, 0.9), 4)
	UIStyler.style_badge(new_record_badge, Color(1.0, 0.85, 0.2), is_mobile)
	UIStyler.style_button(hangar_return_button, 20 if is_mobile else 18, Color(0.8, 0.9, 1.0), 56)
	UIStyler.style_button(restart_button, 22 if is_mobile else 20, Color.WHITE, 56)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_P] and not Game.is_game_over:
			_toggle_pause()
		elif event.keycode == KEY_R and game_over_panel.visible:
			_on_start_pressed()


func _refresh_best_scores() -> void:
	high_score_label.text = "BEST: %d" % Game.high_score


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
	game_over_panel.visible = false
	Game.start()
	_last_lives = Game.lives
	_show_notice("MISI DIMULAI")
	_rebuild_shield_cells()


func _on_return_to_hangar() -> void:
	get_tree().paused = false
	Game.is_running = false
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
	high_score_label.text = "BEST: %d" % Game.high_score

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
			_show_notice("PERISAI KRITIS • Hindari drone musuh")
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
	final_score_label.text = "Final Score: %d" % Game.score
	kills_label.text = "Drones Eliminated: %d" % Game.enemies_destroyed
	pickups_label.text = "Energy Crystals: %d" % Game.pickups_collected

	var is_record := Game.score > 0 and Game.score >= Game.high_score
	new_record_badge.visible = is_record
	_refresh_best_scores()
	game_over_panel.visible = true


func _build_mission_controls() -> void:
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color(0.035, 0.075, 0.1, 0.94)
	surface.set_corner_radius_all(14)
	surface.set_border_width_all(1)
	surface.border_color = Color(0.25, 0.4, 0.43)
	surface.content_margin_left = 18
	surface.content_margin_right = 18
	surface.content_margin_top = 12
	surface.content_margin_bottom = 12
	score_panel.add_theme_stylebox_override("panel", surface)
	shield_panel.add_theme_stylebox_override("panel", surface)
	_pause_button = Button.new()
	_pause_button.text = "Ⅱ  JEDA"
	_pause_button.custom_minimum_size = Vector2(105, 50)
	_pause_button.tooltip_text = "Jeda / lanjutkan (Esc atau P)"
	_pause_button.add_theme_stylebox_override("normal", surface)
	_pause_button.pressed.connect(_toggle_pause)
	top_bar_container.get_child(0).add_child(_pause_button)
	_damage_flash = ColorRect.new()
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_flash.color = Color(1.0, 0.15, 0.1, 0.0)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_flash)
	_notice = Label.new()
	_notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_notice.offset_top = 112
	_notice.offset_bottom = 150
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyler.style_label(_notice, 22, Color(0.85, 0.95, 0.88), 3)
	add_child(_notice)
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_panel.offset_left = -240
	_pause_panel.offset_right = 240
	_pause_panel.offset_top = -165
	_pause_panel.offset_bottom = 165
	_pause_panel.add_theme_stylebox_override("panel", surface)
	_pause_panel.visible = false
	add_child(_pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	_pause_panel.add_child(box)
	var title := Label.new()
	title.text = "PENERBANGAN DIJEDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyler.style_label(title, 28)
	box.add_child(title)
	for text in ["LANJUTKAN", "KEMBALI KE HANGAR"]:
		var btn := Button.new()
		btn.text = text
		UIStyler.style_button(btn, 20, Color.WHITE, 60)
		box.add_child(btn)
		if text == "LANJUTKAN":
			btn.pressed.connect(_toggle_pause)
		else:
			btn.pressed.connect(_on_return_to_hangar)

func _toggle_pause() -> void:
	if Game.is_game_over:
		return
	get_tree().paused = not get_tree().paused
	_pause_panel.visible = get_tree().paused
	Input.action_release("fire")
	joystick._reset()
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE if get_tree().paused else Control.MOUSE_FILTER_PASS
	fire_button.disabled = get_tree().paused
	if _pause_panel.visible:
		_pause_panel.get_child(0).get_child(1).grab_focus()
	else:
		_pause_button.release_focus()

func _show_notice(text: String) -> void:
	if _notice_tween and _notice_tween.is_running():
		_notice_tween.kill()
	_notice.text = text
	_notice.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_interval(3.0)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.6)
