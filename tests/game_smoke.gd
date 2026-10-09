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
	game.save_path = "res://build/test-save.cfg"
	game.completed_levels = {}
	game.last_completed_planet = ""
	var screenshots := "--screenshots" in OS.get_cmdline_user_args()
	check(not game.select_level("toxic"), "Locked planet must reject launch")
	for map_id: String in Campaign.ORDER:
		check(game.is_level_unlocked(map_id), "Sequential unlock: " + map_id)
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
		check(player.position.distance_to(Vector2(3400, 2200)) < 10, "Safe center spawn: " + map_id + " at " + str(player.position))
		var cover := get_tree().get_nodes_in_group("moving_cover")
		check(cover.size() >= 12, "Map needs dynamic cover: " + map_id)
		var start: Vector2 = cover[0].position
		for i in range(180):
			await get_tree().physics_frame
		check(start.distance_to(cover[0].position) > 1, "Cover must move: " + map_id)
		for obs in cover:
			check(obs.position.distance_to(Vector2(3400, 2200)) > 200, "Cover must keep launch space free")
		for weapon_id: String in game.WEAPONS:
			game.selected_weapon_id = weapon_id
			var before: Array=get_tree().get_nodes_in_group("bullets")
			player._shoot()
			# Pooled nodes retain tree order; select newly activated shots, not the last tree child.
			var bullets: Array=get_tree().get_nodes_in_group("bullets").filter(func(b: Bullet)->bool:return not before.has(b))
			check(not bullets.is_empty(), "Weapon must fire: " + weapon_id)
			for bullet: Bullet in bullets:
				check(bullet.weapon_id == weapon_id, "Weapon ID must match")
				check(bullet.sprite.texture.resource_path == game.WEAPONS[weapon_id].texture, "Bullet texture must match selected weapon")
		if map_id == "cyber":
			# Real physics projectile collision must damage armor before scoring a kill.
			for old in get_tree().get_nodes_in_group("bullets"): old.queue_free()
			var armored: Enemy = load("res://scenes/enemy.tscn").instantiate()
			armored.position = player.position + Vector2(0, -230)
			armored.health = 2
			scene.add_child(armored)
			armored.set_physics_process(false)
			game.selected_weapon_id = "ion"
			player.last_aim = Vector2.UP
			player._shoot()
			for frame in 25: await get_tree().physics_frame
			check(is_instance_valid(armored) and armored.health == 1, "First projectile absorbs armor")
			player._shoot()
			for frame in 25: await get_tree().physics_frame
			check(not is_instance_valid(armored), "Second projectile destroys armored enemy")
		var start_position: Vector2 = player.position
		player.set_physics_process(true)
		Input.action_press("move_right")
		for frame in 12: await get_tree().physics_frame
		Input.action_release("move_right")
		player.set_physics_process(false)
		check(player.position.x > start_position.x + 30, "Keyboard movement moves aircraft")
		for id: String in game.SHIPS:
			game.selected_ship_id = id
			player.apply_customization()
			check(player.sprite.texture.resource_path == game.SHIPS[id].texture, "All aircraft usable in combat: " + id)
		var hud: HUD = scene.get_node("HUD")
		hud._toggle_pause()
		check(get_tree().paused, "Pause must stop simulation")
		var paused_pos: Vector2 = cover[0].position
		await get_tree().process_frame
		await get_tree().process_frame
		check(paused_pos == cover[0].position, "Paused obstacles must not move")
		hud._toggle_pause()
		check(not get_tree().paused, "Resume must unpause")
		if screenshots and map_id in ["coast", "desert"] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/preview_" + map_id + ".png")
		check(scene.current_arena_rect.size == Vector2(6800, 4400), "Expanded physical arena")
		check(scene._chunks.size() == 16, "Chunked terrain")
		check(scene.enemy_spawner.base_speed == 85 + Campaign.index(map_id) * 13, "Difficulty speed")
		for kill in Campaign.target(map_id):
			game.record_enemy_kill()
		if Campaign.has_boss(map_id):
			check(not game.mission_won, "Guardian gates completion")
			game.record_boss_defeat()
		check(game.mission_won and not game.is_running, "Objective completes mission")
		check(hud.game_over_panel.visible and hud._stars.visible, "Victory screen")
		check(game.completed_levels.has(map_id), "Completion persisted")
		hud._on_start_pressed()
		check(game.is_running and not game.mission_won and game.enemies_destroyed == 0, "Replay resets mission")
		game.take_damage()
		game.lives = 1
		game.take_damage()
		check(game.is_game_over and hud.game_over_panel.visible, "Defeat screen")
		scene.queue_free()
		await get_tree().process_frame
	game._save_game()
	game.completed_levels = {}
	game._load_save()
	check(game.completed_levels.size() == 8, "Campaign save/load round trip")
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
	if screenshots and DisplayServer.get_name() != "headless":
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
	SoundEffects.stop_all()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
	queue_free()
