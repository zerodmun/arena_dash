extends Node
## Central game state singleton (autoload "Game").
## Manages score/lives, ships, weapons, maps, broadcasts state changes via signals,
## and persists local settings and high score.

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_started
signal game_over
signal screen_shake_requested(strength: float)
signal ship_selected(ship_id: String)
signal weapon_selected(weapon_id: String)
signal map_selected(map_id: String)
signal ui_mode_changed(is_mobile: bool)

const SAVE_PATH := "user://arena_dash_save.cfg"

const SHIPS := {
	"falcon": {
		"id": "falcon", "name": "FALCON", "class": "STRIKE FIGHTER",
		"desc": "Swept-wing strike aircraft. Fast acceleration with reliable armor.",
		"texture": "res://assets/player_falcon.svg", "speed": 410.0,
		"max_lives": 3, "fire_rate": 0.15, "color": Color(1.0, 0.65, 0.25),
	},
	"aurora": {
		"id": "aurora", "name": "AURORA", "class": "RECON WING",
		"desc": "A silver delta-wing aircraft with reinforced shields and precise handling.",
		"texture": "res://assets/player_aurora.svg", "speed": 330.0,
		"max_lives": 4, "fire_rate": 0.16, "color": Color(0.4, 0.9, 0.85),
	},
	"valkyrie": {
		"id": "valkyrie",
		"name": "VALKYRIE",
		"class": "INTERCEPTOR",
		"desc": "Balanced multi-role starfighter with nimble handling and twin plasma thrusters.",
		"texture": "res://assets/player.svg",
		"speed": 360.0,
		"max_lives": 3,
		"fire_rate": 0.18,
		"color": Color(0.22, 0.74, 1.0),
	},
	"titan": {
		"id": "titan",
		"name": "TITAN",
		"class": "DREADNOUGHT",
		"desc": "Heavy armored warship with fortified shield matrices and heavy kinetic mounts.",
		"texture": "res://assets/player_titan.svg",
		"speed": 290.0,
		"max_lives": 5,
		"fire_rate": 0.22,
		"color": Color(0.98, 0.28, 0.28),
	},
	"phantom": {
		"id": "phantom",
		"name": "PHANTOM",
		"class": "SPEEDER",
		"desc": "Hyper-velocity stealth interceptor with extreme agility and rapid-fire systems.",
		"texture": "res://assets/player_phantom.svg",
		"speed": 450.0,
		"max_lives": 2,
		"fire_rate": 0.12,
		"color": Color(0.2, 0.9, 0.55),
	}
}

const WEAPONS := {
	"ion": {
		"id": "ion", "name": "ION CANNON", "desc": "Fast golden ion rounds with a long luminous wake.",
		"texture": "res://assets/bullet_ion.svg", "color": Color(1.0, 0.72, 0.25), "pattern": "single",
	},
	"plasma": {
		"id": "plasma",
		"name": "PLASMA BOLT",
		"desc": "Concentrated high-velocity plasma core with electric aura.",
		"texture": "res://assets/bullet.svg",
		"color": Color(0.22, 0.74, 1.0),
		"pattern": "single",
	},
	"twin_laser": {
		"id": "twin_laser",
		"name": "TWIN LASERS",
		"desc": "Dual high-energy crimson beams fired simultaneously from wingtips.",
		"texture": "res://assets/bullet_laser.svg",
		"color": Color(1.0, 0.25, 0.35),
		"pattern": "twin",
	},
	"quantum_spread": {
		"id": "quantum_spread",
		"name": "QUANTUM SPREAD",
		"desc": "3-way spread energy bursts sweeping a forward cone.",
		"texture": "res://assets/bullet_quantum.svg",
		"color": Color(0.75, 0.45, 1.0),
		"pattern": "spread",
	}
}

const MAPS := {
	"coast": {
		"id": "coast", "name": "COASTAL FRONT", "sector": "SECTOR 04",
		"desc": "Turquoise shallows, sandbanks and drifting offshore cargo. Moving cover changes every route.",
		"icon": "res://assets/map_coast.svg", "color": Color(0.25, 0.85, 0.8),
		"hazard": "DRIFTING CARGO", "bg_color": Color(0.025, 0.08, 0.11),
		"floor_color": Color(0.05, 0.3, 0.35), "wall_color": Color(0.5, 0.8, 0.78),
	},
	"desert": {
		"id": "desert", "name": "DUNE OUTPOST", "sector": "SECTOR 05",
		"desc": "Wind-carved dunes, sandstone ridges and roaming armored cargo. Keep your escape route open.",
		"icon": "res://assets/map_desert.svg", "color": Color(0.95, 0.7, 0.4),
		"hazard": "ROAMING COVER", "bg_color": Color(0.16, 0.1, 0.07),
		"floor_color": Color(0.52, 0.36, 0.21), "wall_color": Color(0.9, 0.69, 0.41),
	},
	"cyber": {
		"id": "cyber",
		"name": "CYBER MATRIX",
		"sector": "SECTOR 01",
		"desc": "High-tech grid with quantum defense pillars and tactical barricades.",
		"icon": "res://assets/map_cyber.svg",
		"color": Color(0.2, 0.75, 1.0),
		"hazard": "DEFENSE BARRICADES",
		"bg_color": Color(0.015, 0.02, 0.04),
		"floor_color": Color(0.035, 0.06, 0.10),
		"grid_color": Color(0.04, 0.30, 0.50, 0.25),
		"node_color": Color(0.22, 0.74, 1.0, 0.45),
		"wall_color": Color(0.22, 0.74, 1.0, 0.95),
	},
	"forest": {
		"id": "forest",
		"name": "PRIMAL JUNGLE",
		"sector": "SECTOR 02",
		"desc": "Prehistoric alien jungle with giant dinosaur skull relics and ancient bio-trees.",
		"icon": "res://assets/map_forest.svg",
		"color": Color(0.2, 0.9, 0.55),
		"hazard": "DINO RELICS & TREES",
		"bg_color": Color(0.01, 0.03, 0.02),
		"floor_color": Color(0.025, 0.065, 0.035),
		"grid_color": Color(0.05, 0.35, 0.18, 0.25),
		"node_color": Color(0.2, 0.9, 0.5, 0.45),
		"wall_color": Color(0.2, 0.9, 0.5, 0.95),
	},
	"space": {
		"id": "space",
		"name": "VOID HORIZON",
		"sector": "SECTOR 03",
		"desc": "Deep cosmic abyss with drifting asteroid clusters and incoming meteor showers.",
		"icon": "res://assets/map_space.svg",
		"color": Color(0.8, 0.4, 1.0),
		"hazard": "METEOR SHOWERS",
		"bg_color": Color(0.01, 0.005, 0.02),
		"floor_color": Color(0.03, 0.015, 0.06),
		"grid_color": Color(0.3, 0.1, 0.45, 0.25),
		"node_color": Color(0.8, 0.4, 1.0, 0.45),
		"wall_color": Color(0.8, 0.4, 1.0, 0.95),
	}
}

var score := 0
var high_score := 0
var lives := 3
var is_running := false
var is_game_over := false

var selected_ship_id := "valkyrie"
var selected_weapon_id := "plasma"
var selected_map_id := "cyber"

var enemies_destroyed := 0
var pickups_collected := 0
var is_mobile_ui := false


func _ready() -> void:
	_load_save()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_update_device_detection()


func _update_device_detection() -> void:
	var platform_mobile: bool = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	var vp_size := Vector2(get_tree().root.size)
	# Use a readable logical canvas on phones instead of shrinking 1920px UI.
	if vp_size.x < vp_size.y:
		get_tree().root.content_scale_size = Vector2i(720, 1280)
	elif vp_size.x <= 1120:
		get_tree().root.content_scale_size = Vector2i(1280, 720)
	else:
		get_tree().root.content_scale_size = Vector2i(1920, 1080)
	# Auto-detect mobile if running on mobile platform, touchscreen device, or if viewport is narrow (<= 1120px) or in portrait orientation
	var viewport_mobile: bool = (vp_size.x > 0.0 and vp_size.x <= 1120.0) or (vp_size.x > 0.0 and vp_size.x < vp_size.y)
	var should_be_mobile: bool = platform_mobile or viewport_mobile
	set_mobile_ui(should_be_mobile)


func _on_viewport_size_changed() -> void:
	_update_device_detection()


func set_mobile_ui(enable: bool) -> void:
	if is_mobile_ui != enable:
		is_mobile_ui = enable
		ui_mode_changed.emit(is_mobile_ui)


func toggle_ui_mode() -> void:
	set_mobile_ui(not is_mobile_ui)


func get_current_ship() -> Dictionary:
	return SHIPS.get(selected_ship_id, SHIPS["valkyrie"])


func get_current_weapon() -> Dictionary:
	return WEAPONS.get(selected_weapon_id, WEAPONS["plasma"])


func get_current_map() -> Dictionary:
	return MAPS.get(selected_map_id, MAPS["cyber"])


func select_ship(ship_id: String) -> void:
	if SHIPS.has(ship_id):
		selected_ship_id = ship_id
		_save_game()
		ship_selected.emit(ship_id)


func select_weapon(weapon_id: String) -> void:
	if WEAPONS.has(weapon_id):
		selected_weapon_id = weapon_id
		_save_game()
		weapon_selected.emit(weapon_id)


func select_map(map_id: String) -> void:
	if map_id == "random":
		var keys := MAPS.keys()
		selected_map_id = keys.pick_random()
		_save_game()
		map_selected.emit(selected_map_id)
	elif MAPS.has(map_id):
		selected_map_id = map_id
		_save_game()
		map_selected.emit(map_id)


func start() -> void:
	var ship := get_current_ship()
	score = 0
	lives = int(ship["max_lives"])
	enemies_destroyed = 0
	pickups_collected = 0
	is_running = true
	is_game_over = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	game_started.emit()


func add_score(amount: int) -> void:
	if not is_running:
		return
	score += amount
	if score > high_score:
		high_score = score
		_save_game()
	score_changed.emit(score)


func record_enemy_kill() -> void:
	enemies_destroyed += 1


func record_pickup_collected() -> void:
	pickups_collected += 1


func request_screen_shake(strength: float = 6.0) -> void:
	screen_shake_requested.emit(strength)


func take_damage() -> void:
	if not is_running or is_game_over:
		return
	lives -= 1
	lives_changed.emit(lives)
	request_screen_shake(12.0)
	if SoundEffects:
		SoundEffects.play_hit()
	if lives <= 0:
		lives = 0
		is_running = false
		is_game_over = true
		game_over.emit()


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = cfg.get_value("stats", "high_score", 0)
		selected_ship_id = cfg.get_value("settings", "ship", "valkyrie")
		selected_weapon_id = cfg.get_value("settings", "weapon", "plasma")
		selected_map_id = cfg.get_value("settings", "map", "cyber")


func _save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "high_score", high_score)
	cfg.set_value("settings", "ship", selected_ship_id)
	cfg.set_value("settings", "weapon", selected_weapon_id)
	cfg.set_value("settings", "map", selected_map_id)
	cfg.save(SAVE_PATH)
