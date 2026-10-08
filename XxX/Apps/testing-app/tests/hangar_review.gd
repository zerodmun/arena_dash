extends Node
## Integration and visual checks for 2D assets, swipe and live selection popups.
func _ready() -> void:
	call_deferred("_review")

func _capture(name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/" + name + ".png")

func _click(control: Control) -> void:
	var point := get_viewport().get_final_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event)

func _review() -> void:
	var original_ship: String = Game.selected_ship_id
	var original_weapon: String = Game.selected_weapon_id
	var original_map: String = Game.selected_map_id
	Game.selected_ship_id = "valkyrie"
	Game.selected_weapon_id = "plasma"
	Game.selected_map_id = "coast"
	var hangar = load("res://scenes/hangar.tscn").instantiate()
	get_tree().root.add_child(hangar)
	get_tree().current_scene = hangar
	await get_tree().process_frame
	for id: String in Game.SHIPS:
		Game.selected_ship_id = id
		hangar._ship_index = Game.SHIPS.keys().find(id)
		hangar._refresh()
		assert(hangar._ship_image.texture.resource_path == Game.SHIPS[id].texture, "Use original 2D assets")
	Game.selected_ship_id = "valkyrie"
	hangar._ship_index = Game.SHIPS.keys().find("valkyrie")
	hangar._refresh()
	# Clicking an aircraft thumbnail and dragging its display both change selection.
	hangar._aircraft_buttons["titan"].pressed.emit()
	assert(Game.selected_ship_id == "titan")
	var origin: Vector2 = hangar._hero.get_global_rect().get_center()
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = get_viewport().get_final_transform() * origin
	get_viewport().push_input(mouse_down)
	var mouse_move := InputEventMouseMotion.new()
	mouse_move.position = get_viewport().get_final_transform() * (origin - Vector2(180, 0))
	mouse_move.relative = Vector2(-180, 0)
	mouse_move.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(mouse_move)
	var mouse_up := InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	mouse_up.position = get_viewport().get_final_transform() * (origin - Vector2(180, 0))
	get_viewport().push_input(mouse_up)
	assert(Game.selected_ship_id == "phantom", "Horizontal swipe should select next aircraft")
	hangar._drag_start = Vector2(50, 50)
	hangar._dragging = true
	hangar._finish_swipe(Vector2(60, 200))
	assert(Game.selected_ship_id == "phantom", "Vertical scrolling should not change aircraft")
	hangar._select_ship("valkyrie")
	await get_tree().create_timer(0.3).timeout
	await _capture("preview_hangar")
	_click(hangar._weapon_card)
	assert(hangar._overlay.visible and hangar._popup_mode == "weapon")
	assert(hangar._preview.ship_id == Game.selected_ship_id)
	await get_tree().process_frame
	var score_before: int = Game.score
	for id: String in Game.WEAPONS:
		hangar._popup_buttons[id].pressed.emit()
		assert(Game.selected_weapon_id == id)
		assert(hangar._overlay.visible, "Changing type should keep popup open")
		assert(hangar._preview.weapon_id == id)
		hangar._preview.shots.clear()
		hangar._preview._emit_shots()
		var expected := 2 if id == "twin_laser" else (3 if id == "quantum_spread" else 1)
		assert(hangar._preview.shots.size() == expected, "Preview must match firing pattern")
		var shot_pos: Vector2 = hangar._preview.shots[0].position
		hangar._preview._process(0.02)
		assert(hangar._preview.shots[0].position != shot_pos, "Shots must animate")
	assert(Game.score == score_before, "Preview must not change gameplay score")
	await get_tree().create_timer(0.4).timeout
	await _capture("hangar_weapon_popup")
	hangar._switch_ship(1)
	assert(Game.selected_ship_id == "valkyrie", "Modal must block background aircraft selection")
	hangar._close_popup()
	assert(not hangar._overlay.visible)
	_click(hangar._map_card)
	assert(hangar._preview.mode == "map")
	for id: String in Game.MAPS:
		hangar._popup_buttons[id].pressed.emit()
		assert(hangar._map_id == id and hangar._preview.map_id == id)
	hangar._popup_buttons["coast"].pressed.emit()
	await get_tree().process_frame
	await _capture("hangar_map_popup")
	hangar._popup_buttons["random"].pressed.emit()
	assert(hangar._map_card_label.text == "LOKASI ACAK")
	hangar._close_popup()
	get_tree().root.size = Vector2i(540, 960)
	await get_tree().create_timer(0.2).timeout
	assert(hangar._compact, "Portrait must use compact layout")
	assert(hangar._weapon_card.position.y > hangar._hero.position.y, "Portrait controls below the aircraft")
	await _capture("preview_mobile")
	hangar._open_popup("weapon")
	await get_tree().create_timer(0.4).timeout
	assert(hangar._modal.size.x <= get_viewport().get_visible_rect().size.x)
	assert(hangar._modal.size.y <= get_viewport().get_visible_rect().size.y)
	await _capture("hangar_mobile_weapon")
	hangar._close_popup()
	hangar._open_popup("map")
	await get_tree().process_frame
	assert(hangar._modal.size.y <= get_viewport().get_visible_rect().size.y)
	await _capture("hangar_mobile_map")
	hangar._close_popup()
	get_tree().root.size = Vector2i(1024, 576)
	await get_tree().create_timer(0.2).timeout
	assert(not hangar._compact, "Landscape uses centered reference layout")
	assert(not hangar._roster_scroll.get_global_rect().intersects(hangar._launch.get_global_rect()), "Roster must not overlap launch")
	assert(not hangar._roster_scroll.get_global_rect().intersects(hangar._map_card.get_global_rect()), "Roster must not overlap map card")
	assert(hangar._launch.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y)
	await _capture("hangar_landscape")
	Game.selected_ship_id = original_ship
	Game.selected_weapon_id = original_weapon
	Game.selected_map_id = original_map
	Game._save_game()
	print("HANGAR REVIEW: PASS — 2D assets, thumbnail selection, swipe, live shot patterns, map popup, modal blocking, portrait")
	hangar.queue_free()
	await get_tree().process_frame
	get_tree().quit()
	queue_free()
