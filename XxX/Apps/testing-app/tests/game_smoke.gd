extends Node
## Integration check for catalogs, firing, map generation, obstacle motion and pause.
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var game := get_tree().root.get_node("Game")
	var screenshots := "--screenshots" in OS.get_cmdline_user_args()
	for map_id: String in game.MAPS:
		game.selected_map_id = map_id
		game.selected_ship_id = "falcon"
		game.selected_weapon_id = "ion"
		var scene: Node2D = load("res://scenes/main.tscn").instantiate()
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
		var player = scene.get_node("Player")
		player.set_physics_process(false)
		await get_tree().process_frame
		await get_tree().physics_frame
		check(player.speed == 410.0, "Ship stats must be applied")
		check(player.position.distance_to(Vector2(1700, 1100)) < 10, "Safe center spawn: " + map_id + " at " + str(player.position))
		var cover := get_tree().get_nodes_in_group("moving_cover")
		check(cover.size() >= 12, "Map needs dynamic cover: " + map_id)
		var start: Vector2 = cover[0].position
		for i in range(180):
			await get_tree().physics_frame
		check(start.distance_to(cover[0].position) > 1, "Cover must move: " + map_id)
		for obs in cover:
			check(obs.position.distance_to(Vector2(1700, 1100)) > 200, "Cover must keep launch space free")
		for weapon_id: String in game.WEAPONS:
			game.selected_weapon_id = weapon_id
			player._shoot()
			var bullets := get_tree().get_nodes_in_group("bullets")
			check(not bullets.is_empty(), "Weapon must fire: " + weapon_id)
			if not bullets.is_empty():
				var bullet = bullets.back()
				check(bullet.weapon_id == weapon_id, "Weapon ID must match")
				check(bullet.sprite.texture.resource_path == game.WEAPONS[weapon_id].texture, "Bullet texture must match selected weapon")
		var hud: HUD = scene.get_node("HUD")
		hud._toggle_pause()
		check(get_tree().paused, "Pause must stop simulation")
		var paused_pos: Vector2 = cover[0].position
		await get_tree().process_frame
		await get_tree().process_frame
		check(paused_pos == cover[0].position, "Paused obstacles must not move")
		hud._toggle_pause()
		check(not get_tree().paused, "Resume must unpause")
		if screenshots and map_id in ["coast", "desert"]:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/preview_" + map_id + ".png")
		scene.queue_free()
		await get_tree().process_frame
	game.is_running = false
	game.selected_map_id = "coast"
	var hangar: Hangar = load("res://scenes/hangar.tscn").instantiate()
	get_tree().root.add_child(hangar)
	get_tree().current_scene = hangar
	await get_tree().process_frame
	for id: String in game.SHIPS:
		game.selected_ship_id = id
		hangar._ship_index = game.SHIPS.keys().find(id)
		hangar._refresh()
		check(hangar._ship_image.texture.resource_path == game.SHIPS[id].texture, "Hangar aircraft preview")
	if screenshots:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/preview_hangar.png")
		get_tree().root.size = Vector2i(540, 960)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/preview_mobile.png")
	print("GAME SMOKE: ", "PASS" if failures.is_empty() else "FAIL", " — ", failures.size(), " failures")
	hangar.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
	queue_free()
