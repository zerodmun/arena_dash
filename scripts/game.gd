extends Node
## Central game state singleton (autoload "Game").
## Manages score/lives, ships, weapons, maps, broadcasts state changes via signals,
## and persists local settings and high score.

signal economy_changed

signal preferences_changed

var startup_resources: Dictionary = {} # Warm startup assets retained for scene reuse.

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

const SHIPS := EquipmentCatalog.SHIPS
const WEAPONS := EquipmentCatalog.WEAPONS

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
    },
    "lava": {
        "id":"lava", "name":"LAVA FRONTIER", "sector":"SECTOR 09",
        "desc":"Lava interceptors / thermal guardian", "hazard":"LAVA FRONTIER", "color":Color("ef6a1a"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("ef6a1a"),
        "icon":"res://assets/future_update/maps/lava/bg_lava_landscape.png", "tile":"res://assets/future_update/maps/lava/map_lava_tile.png",
        "overlay":"res://assets/future_update/maps/lava/overlay_atmosphere_lava.png",
    },
    "ice": {
        "id":"ice", "name":"ICE CROWN", "sector":"SECTOR 10",
        "desc":"Ice orbiters / cryo crossfire", "hazard":"ICE CROWN", "color":Color("8adfe8"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("8adfe8"),
        "icon":"res://assets/future_update/maps/ice/bg_ice_landscape.png", "tile":"res://assets/future_update/maps/ice/map_ice_tile.png",
        "overlay":"res://assets/future_update/maps/ice/overlay_atmosphere_ice.png",
    },
    "advanced_desert": {
        "id":"advanced_desert", "name":"DESERT SIEGE", "sector":"SECTOR 11",
        "desc":"Desert siege / bomber escorts", "hazard":"DESERT SIEGE", "color":Color("e0be87"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("e0be87"),
        "icon":"res://assets/future_update/maps/desert/bg_desert_landscape.png", "tile":"res://assets/future_update/maps/desert/map_desert_tile.png",
        "overlay":"res://assets/future_update/maps/desert/overlay_atmosphere_desert.png",
    },
    "advanced_toxic": {
        "id":"advanced_toxic", "name":"TOXIC REFINERY", "sector":"SECTOR 12",
        "desc":"Toxic drones / refinery guardian", "hazard":"TOXIC REFINERY", "color":Color("83ca21"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("83ca21"),
        "icon":"res://assets/future_update/maps/toxic/bg_toxic_landscape.png", "tile":"res://assets/future_update/maps/toxic/map_toxic_tile.png",
        "overlay":"res://assets/future_update/maps/toxic/overlay_atmosphere_toxic.png",
    },
    "storm": {
        "id":"storm", "name":"STORM REACH", "sector":"SECTOR 13",
        "desc":"Storm fighters / charged crossfire", "hazard":"STORM REACH", "color":Color("759bff"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("759bff"),
        "icon":"res://assets/future_update/maps/storm/bg_storm_landscape.png", "tile":"res://assets/future_update/maps/storm/map_storm_tile.png",
        "overlay":"res://assets/future_update/maps/storm/overlay_atmosphere_storm.png",
    },
    "crystal": {
        "id":"crystal", "name":"CRYSTAL NEXUS", "sector":"SECTOR 14",
        "desc":"Crystal destroyers / converging volleys", "hazard":"CRYSTAL NEXUS", "color":Color("cd8dff"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("cd8dff"),
        "icon":"res://assets/future_update/maps/crystal/bg_crystal_landscape.png", "tile":"res://assets/future_update/maps/crystal/map_crystal_tile.png",
        "overlay":"res://assets/future_update/maps/crystal/overlay_atmosphere_crystal.png",
    },
    "dark_void": {
        "id":"dark_void", "name":"DARK VOID", "sector":"SECTOR 15",
        "desc":"Void fleet / battleship command", "hazard":"DARK VOID", "color":Color("9165e5"),
        "bg_color":Color("090f20"), "floor_color":Color("101c30"), "wall_color":Color("9165e5"),
        "icon":"res://assets/future_update/maps/dark_void/bg_dark_void_landscape.png", "tile":"res://assets/future_update/maps/dark_void/map_dark_void_tile.png",
        "overlay":"res://assets/future_update/maps/dark_void/overlay_atmosphere_dark_void.png",
    },
}

var last_completed_planet := ""
var boss_defeated := true
var boss_health := 0
var boss_max_health := 0
var completed_levels: Dictionary = {}
var mission_elapsed := 0.0
var mission_won := false
var audio_enabled := true
var audio_volumes: Dictionary = {"Master": 0.85, "Music": 0.7, "UI": 0.8, "SFX": 0.85}
var reduced_motion := false

var score := 0
var high_score := 0
var coins := 0
var owned_ships: Dictionary = {"falcon":true,"aurora":true,"valkyrie":true}
var owned_weapons: Dictionary = {"ion":true,"plasma":true}
var rewarded_planets: Dictionary = {}
var last_coin_reward := 0
var economy_loaded := false
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
    if OS.get_name() in ["Android","iOS"]:
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    if OS.is_debug_build() and OS.has_feature("arena_review"):
        save_path="user://arena_review_save.cfg"
    _load_save()
    if OS.is_debug_build() and OS.has_feature("arena_review") and not FileAccess.file_exists(save_path):
        coins=5000
        _save_game()
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


func select_ship(ship_id: String) -> bool:
    if SHIPS.has(ship_id) and owns_equipment("ship",ship_id):
        var previous := selected_ship_id
        selected_ship_id = ship_id
        if not _save_game():
            selected_ship_id=previous
            return false
        ship_selected.emit(ship_id)
        return true
    return false


func select_weapon(weapon_id: String) -> bool:
    if WEAPONS.has(weapon_id) and owns_equipment("weapon",weapon_id):
        var previous := selected_weapon_id
        selected_weapon_id = weapon_id
        if not _save_game():
            selected_weapon_id=previous
            return false
        weapon_selected.emit(weapon_id)
        return true
    return false


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
    if not owns_equipment("ship",selected_ship_id): selected_ship_id="valkyrie"
    if not owns_equipment("weapon",selected_weapon_id): selected_weapon_id="plasma"
    last_coin_reward=0
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
    var existing := cfg.load(save_path) == OK
    if existing:
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
        for bus: String in audio_volumes:
            var value: Variant = cfg.get_value("audio", bus, audio_volumes[bus])
            if (value is float or value is int) and is_finite(float(value)):
                audio_volumes[bus] = clampf(float(value), 0.0, 1.0)
        reduced_motion = cfg.get_value("settings", "reduced_motion", false)
        control_layout=TouchLayout.sanitize(cfg.get_value("controls","layout",{}))
        I18n.set_language(cfg.get_value("settings","language","en"),false)
    if not SHIPS.has(selected_ship_id): selected_ship_id = "valkyrie"
    if not WEAPONS.has(selected_weapon_id): selected_weapon_id = "plasma"
    if not MAPS.has(selected_map_id) or not is_level_unlocked(selected_map_id): selected_map_id = "cyber"
    _load_economy(cfg,existing)
    if not owns_equipment("ship",selected_ship_id): selected_ship_id="valkyrie"
    if not owns_equipment("weapon",selected_weapon_id): selected_weapon_id="plasma"
    apply_audio()


func _save_game() -> bool:
    var cfg := ConfigFile.new()
    cfg.set_value("economy", "version", 1)
    cfg.set_value("economy", "coins", coins)
    cfg.set_value("economy", "ships", owned_ships)
    cfg.set_value("economy", "weapons", owned_weapons)
    cfg.set_value("economy", "rewarded_planets", rewarded_planets)
    cfg.set_value("stats", "high_score", high_score)
    cfg.set_value("settings", "ship", selected_ship_id)
    cfg.set_value("settings", "weapon", selected_weapon_id)
    cfg.set_value("settings", "map", selected_map_id)
    cfg.set_value("campaign", "completed", completed_levels)
    cfg.set_value("campaign", "last_completed", last_completed_planet)
    cfg.set_value("settings","language",I18n.language)
    cfg.set_value("controls","layout",control_layout)
    cfg.set_value("settings", "audio", audio_enabled)
    for bus: String in audio_volumes: cfg.set_value("audio", bus, audio_volumes[bus])
    cfg.set_value("settings", "reduced_motion", reduced_motion)
    # Atomically replace one snapshot: balance and ownership cannot save separately.
    var temporary := save_path+".tmp"
    if cfg.save(temporary)!=OK: return false
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(save_path))!=OK: return false
    _score_dirty=false
    save_writes+=1
    return true

func _physics_process(delta: float) -> void:
 if is_running: mission_elapsed+=delta

func flush_save() -> void:
 if _score_dirty:_save_game()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_RESUMED and OS.get_name() in ["Android","iOS"]:
  DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
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
 last_coin_reward=120+30*last_attempt_stars+10*Campaign.index(selected_map_id)
 if not rewarded_planets.has(selected_map_id):
  last_coin_reward+=250
  rewarded_planets[selected_map_id]=true
 coins+=last_coin_reward
 _score_dirty=true
 _save_game()
 economy_changed.emit()
 mission_completed.emit()

func apply_audio() -> void:
    AudioServer.set_bus_mute(0, not audio_enabled)
    var director := get_node_or_null("/root/SoundEffects")
    if director and director.is_node_ready(): director.apply_settings()

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

# Economy is independent of combat score and mission stars. Repeat mission rewards
# are intentional; the 250-coin first-clear bonus is awarded once per planet.
func owns_equipment(kind: String,id: String) -> bool:
 return kind in ["ship","weapon"] and (owned_ships if kind=="ship" else owned_weapons).get(id,false)==true

func equipment_price(kind: String,id: String) -> int:
 if not kind in ["ship","weapon"]:return -1
 return int((SHIPS if kind=="ship" else WEAPONS).get(id,{}).get("price",-1))

func purchase_equipment(kind: String,id: String) -> String:
 if not kind in ["ship","weapon"]: return "invalid"
 var price:=equipment_price(kind,id)
 if price<0:return "invalid"
 if owns_equipment(kind,id):return "owned"
 if coins<price:return "insufficient"
 var ownership: Dictionary=owned_ships if kind=="ship" else owned_weapons
 var before:=coins
 coins-=price
 ownership[id]=true
 if not _save_game():
  coins=before
  ownership.erase(id)
  return "save_failed"
 economy_changed.emit()
 return "purchased"

func _valid_ownership(raw: Variant,catalog: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for id: String in catalog:
  if catalog[id].price==0 or (raw is Dictionary and raw.get(id,false)==true):result[id]=true
 return result

func _load_economy(cfg: ConfigFile,existing: bool) -> void:
 coins=0
 owned_ships=_valid_ownership({},SHIPS)
 owned_weapons=_valid_ownership({},WEAPONS)
 rewarded_planets={}
 if existing and not cfg.has_section_key("economy","version"):
  # Previously all equipment was free. Preserve that entitlement for old saves.
  for id: String in EquipmentCatalog.LEGACY_FREE_SHIPS:owned_ships[id]=true
  for id: String in EquipmentCatalog.LEGACY_FREE_WEAPONS:owned_weapons[id]=true
  # An explicitly saved loadout is evidence of prior access; preserve it too.
  var carried_ship: String=cfg.get_value("settings","ship","valkyrie")
  var carried_weapon: String=cfg.get_value("settings","weapon","plasma")
  if SHIPS.has(carried_ship):owned_ships[carried_ship]=true
  if WEAPONS.has(carried_weapon):owned_weapons[carried_weapon]=true
  # Credit historical mission completion once, without converting combat scores.
  for id: String in completed_levels:
   rewarded_planets[id]=true
   coins+=370+30*best_stars(id)+10*Campaign.index(id)
 elif existing:
  var balance: Variant=cfg.get_value("economy","coins",0)
  if balance is int and balance>=0:coins=mini(balance,1000000000)
  owned_ships=_valid_ownership(cfg.get_value("economy","ships",{}),SHIPS)
  owned_weapons=_valid_ownership(cfg.get_value("economy","weapons",{}),WEAPONS)
  var claimed: Variant=cfg.get_value("economy","rewarded_planets",{})
  if claimed is Dictionary:
   for id: String in Campaign.ORDER:
    if claimed.get(id,false)==true:rewarded_planets[id]=true
 economy_loaded=true
 # Persist migration immediately; reopening cannot grant it again.
 if existing and not cfg.has_section_key("economy","version"):_save_game()
