extends Node
## Central game state singleton (autoload "Game").
## Manages score/lives, ships, weapons, maps, broadcasts state changes via signals,
## and persists local settings and high score.

signal preferences_changed

var control_layout := TouchLayout.defaults()
var mission_damage := 0
var last_attempt_stars := 0
var _score_dirty := false
var save_writes := 0

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_started
signal boss_status_changed
signal mission_completed
signal mission_progress_changed
signal game_over
signal screen_shake_requested(strength: float)
signal ship_selected(ship_id: String)
signal weapon_selected(weapon_id: String)
signal map_selected(map_id: String)
signal ui_mode_changed(is_mobile: bool)

const SAVE_PATH := "user://arena_dash_save.cfg"
var save_path := SAVE_PATH

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
    },
    "tempest": {
        "id": "tempest",
        "name": "TEMPEST",
        "class": "ASSAULT GUNSHIP",
        "desc": "Heavy forward-swept storm fighter. Relentless firepower with fortified armor.",
        "texture": "res://assets/player_tempest.svg",
        "speed": 380.0,
        "max_lives": 4,
        "fire_rate": 0.14,
        "color": Color(0.66, 0.33, 0.97),
    },
    "mirage": {
        "id": "mirage",
        "name": "MIRAGE",
        "class": "SKYSTALKER",
        "desc": "Twin-boom canard prototype featuring micro-vectoring and solar plasma drives.",
        "texture": "res://assets/player_mirage.svg",
        "speed": 430.0,
        "max_lives": 3,
        "fire_rate": 0.13,
        "color": Color(0.92, 0.70, 0.05),
    },
    "saucer": {"id": "saucer", "name": "SAUCER", "class": "ORBITAL DEFENDER", "desc": "Expansion fleet / orbital defender", "texture": "res://assets/future_updates/aircraft/player_saucer.svg", "speed": 320.0, "max_lives": 5, "fire_rate": 0.19, "color": Color("69dfff")},
    "rocket": {"id": "rocket", "name": "ROCKET", "class": "SOLAR STRIKER", "desc": "Expansion fleet / solar striker", "texture": "res://assets/future_updates/aircraft/player_rocket.svg", "speed": 420.0, "max_lives": 3, "fire_rate": 0.15, "color": Color("ff6969")},
    "wedge": {"id": "wedge", "name": "WEDGE", "class": "STEALTH INTERCEPTOR", "desc": "Expansion fleet / stealth interceptor", "texture": "res://assets/future_updates/aircraft/player_wedge.svg", "speed": 440.0, "max_lives": 2, "fire_rate": 0.12, "color": Color("56baff")},
    "speeder": {"id": "speeder", "name": "SPEEDER", "class": "DELTA RUNNER", "desc": "Expansion fleet / delta runner", "texture": "res://assets/future_updates/aircraft/player_speeder.svg", "speed": 470.0, "max_lives": 2, "fire_rate": 0.11, "color": Color("a7f570")},
    "booster": {"id": "booster", "name": "BOOSTER", "class": "HEAVY ESCORT", "desc": "Expansion fleet / heavy escort", "texture": "res://assets/future_updates/aircraft/player_booster.svg", "speed": 300.0, "max_lives": 5, "fire_rate": 0.16, "color": Color("ffc35c")},
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
    },
    "volcano": {
        "id": "volcano",
        "name": "MAGMA CALDERA",
        "sector": "SECTOR 06",
        "desc": "Volcanic basalt crust with glowing molten lava channels and thermal venting obelisks.",
        "icon": "res://assets/map_volcano.svg",
        "color": Color(0.98, 0.45, 0.15),
        "hazard": "THERMAL OBELISKS",
        "bg_color": Color(0.06, 0.02, 0.01),
        "floor_color": Color(0.12, 0.06, 0.04),
        "grid_color": Color(0.45, 0.15, 0.05, 0.25),
        "node_color": Color(0.98, 0.45, 0.15, 0.50),
        "wall_color": Color(0.98, 0.35, 0.15, 0.95),
    },
    "glacier": {
        "id": "glacier",
        "name": "GLACIAL TUNDRA",
        "sector": "SECTOR 07",
        "desc": "Polar sapphire ice sheets with deep frozen crevasses and crystalline cryo monoliths.",
        "icon": "res://assets/map_glacier.svg",
        "color": Color(0.22, 0.74, 0.98),
        "hazard": "CRYO MONOLITHS",
        "bg_color": Color(0.01, 0.04, 0.08),
        "floor_color": Color(0.03, 0.12, 0.20),
        "grid_color": Color(0.10, 0.35, 0.55, 0.25),
        "node_color": Color(0.22, 0.74, 0.98, 0.50),
        "wall_color": Color(0.25, 0.75, 1.0, 0.95),
    },
    "toxic": {
        "id": "toxic",
        "name": "TOXIC CITADEL",
        "sector": "SECTOR 08",
        "desc": "Corroded industrial refinery with fluorescent acid canals and biohazard containment silos.",
        "icon": "res://assets/map_toxic.svg",
        "color": Color(0.52, 0.80, 0.10),
        "hazard": "ACID CONTAINMENT",
        "bg_color": Color(0.02, 0.05, 0.03),
        "floor_color": Color(0.04, 0.10, 0.06),
        "grid_color": Color(0.15, 0.40, 0.10, 0.25),
        "node_color": Color(0.52, 0.80, 0.10, 0.50),
        "wall_color": Color(0.55, 0.85, 0.15, 0.95),
    }
}

var last_completed_planet := ""
var boss_defeated := true
var boss_health := 0
var boss_max_health := 0
var completed_levels: Dictionary = {}
var mission_elapsed := 0.0
var mission_won := false
var audio_enabled := true
var reduced_motion := false

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
    # One landscape design canvas; portrait windows letterbox instead of changing layout.
    get_tree().root.content_scale_size = Vector2i(1280,720)
    get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP if vp_size.x < vp_size.y else Window.CONTENT_SCALE_ASPECT_EXPAND
    var viewport_mobile: bool = vp_size.x > 0 and vp_size.x <= 1120
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


func select_map(map_id: String) -> bool:
 if map_id=="random":
  var unlocked: Array[String]=[]
  for id: String in Campaign.ORDER:
   if is_level_unlocked(id):unlocked.append(id)
  map_id=unlocked.pick_random()
 if not MAPS.has(map_id) or not is_level_unlocked(map_id):return false
 selected_map_id=map_id
 _save_game()
 map_selected.emit(map_id)
 return true


func start() -> void:
    if not is_level_unlocked(selected_map_id): selected_map_id="cyber"
    mission_damage=0
    last_attempt_stars=0
    var ship := get_current_ship()
    boss_defeated = not Campaign.has_boss(selected_map_id)
    boss_health = 0
    boss_max_health = 0
    mission_elapsed = 0.0
    mission_won = false
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
        _score_dirty=true
    score_changed.emit(score)


func record_enemy_kill() -> void:
    if not is_running: return
    enemies_destroyed += 1
    mission_progress_changed.emit()
    _check_mission_completion()


func record_pickup_collected() -> void:
    pickups_collected += 1


func request_screen_shake(strength: float = 6.0) -> void:
    if not reduced_motion:
        screen_shake_requested.emit(strength)


func take_damage(amount: int = 1) -> void:
    if not is_running or is_game_over:
        return
    mission_damage+=mini(lives,maxi(0,amount))
    lives = maxi(0, lives - amount)
    lives_changed.emit(lives)
    request_screen_shake(12.0)
    if SoundEffects:
        SoundEffects.play_hit()
    if lives <= 0:
        lives = 0
        is_running = false
        is_game_over = true
        flush_save()
        game_over.emit()


func _load_save() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(save_path) == OK:
        high_score = cfg.get_value("stats", "high_score", 0)
        selected_ship_id = cfg.get_value("settings", "ship", "valkyrie")
        selected_weapon_id = cfg.get_value("settings", "weapon", "plasma")
        selected_map_id = cfg.get_value("settings", "map", "cyber")
        completed_levels = sanitize_progress(cfg.get_value("campaign", "completed", {}))
        last_completed_planet = cfg.get_value("campaign", "last_completed", "")
        if not is_level_cleared(last_completed_planet):
            last_completed_planet = ""
            for id: String in Campaign.ORDER:
                if is_level_cleared(id): last_completed_planet = id
        audio_enabled = cfg.get_value("settings", "audio", true)
        reduced_motion = cfg.get_value("settings", "reduced_motion", false)
        control_layout=TouchLayout.sanitize(cfg.get_value("controls","layout",{}))
        I18n.set_language(cfg.get_value("settings","language","en"),false)
    if not SHIPS.has(selected_ship_id): selected_ship_id = "valkyrie"
    if not WEAPONS.has(selected_weapon_id): selected_weapon_id = "plasma"
    if not MAPS.has(selected_map_id) or not is_level_unlocked(selected_map_id): selected_map_id = "cyber"
    apply_audio()


func _save_game() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("stats", "high_score", high_score)
    cfg.set_value("settings", "ship", selected_ship_id)
    cfg.set_value("settings", "weapon", selected_weapon_id)
    cfg.set_value("settings", "map", selected_map_id)
    cfg.set_value("campaign", "completed", completed_levels)
    cfg.set_value("campaign", "last_completed", last_completed_planet)
    cfg.set_value("settings","language",I18n.language)
    cfg.set_value("controls","layout",control_layout)
    cfg.set_value("settings", "audio", audio_enabled)
    cfg.set_value("settings", "reduced_motion", reduced_motion)
    if cfg.save(save_path)==OK:
        _score_dirty=false
        save_writes+=1

func _physics_process(delta: float) -> void:
 if is_running: mission_elapsed+=delta

func flush_save() -> void:
 if _score_dirty:_save_game()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_CLOSE_REQUEST]:flush_save()

func sanitize_progress(raw: Variant) -> Dictionary:
 var progress: Dictionary={}
 if raw is Dictionary:
  for id: String in Campaign.ORDER:
   var rating: Variant=raw.get(id,0)
   if (rating is int or rating is float) and is_finite(float(rating)):
    var stars:=int(rating)
    if stars>=1 and stars<=3 and float(rating)==float(stars):progress[id]=stars
 return progress

func best_stars(id: String) -> int:
 var value: Variant=completed_levels.get(id,0)
 if (value is int or value is float) and is_finite(float(value)) and float(value)==float(int(value)) and int(value) in [1,2,3]:return int(value)
 return 0

func is_level_cleared(id: String) -> bool:
 return best_stars(id)==3 and is_level_unlocked(id)

func is_level_unlocked(id: String) -> bool:
 var i:=Campaign.ORDER.find(id)
 if i<0:return false
 for previous in i:
  if best_stars(Campaign.ORDER[previous])!=3:return false
 return true

func select_level(id: String) -> bool:
    if not is_level_unlocked(id): return false
    select_map(id)
    return true

func complete_mission() -> void:
 if not is_running or mission_won or not is_level_unlocked(selected_map_id):return
 if enemies_destroyed<Campaign.target(selected_map_id) or not boss_defeated:return
 mission_won=true
 is_running=false
 last_attempt_stars=Campaign.rating(selected_map_id,selected_ship_id,mission_damage,mission_elapsed)
 completed_levels[selected_map_id]=maxi(best_stars(selected_map_id),last_attempt_stars)
 if last_attempt_stars==3:last_completed_planet=selected_map_id
 _save_game()
 mission_completed.emit()

func apply_audio() -> void:
    AudioServer.set_bus_mute(0, not audio_enabled)

func save_settings() -> void:
    apply_audio()
    _save_game()
    preferences_changed.emit()

func hangar_planet() -> String:
    return last_completed_planet if is_level_cleared(last_completed_planet) else "cyber"

func _check_mission_completion() -> void:
    if is_running and enemies_destroyed >= Campaign.target(selected_map_id) and boss_defeated:
        complete_mission()

func record_boss_defeat() -> void:
    boss_defeated = true
    boss_health = 0
    boss_status_changed.emit()
    _check_mission_completion()

func _exit_tree() -> void:
 flush_save()
