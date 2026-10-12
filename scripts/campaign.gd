class_name Campaign
extends RefCounted
## Stable level IDs follow the planet asset naming convention.
const ORDER := ["cyber", "forest", "space", "coast", "desert", "volcano", "glacier", "toxic", "lava", "ice", "advanced_desert", "advanced_toxic", "storm", "crystal", "dark_void"]
const PLANETS := ["cyber_matrix", "primal_jungle", "void_horizon", "coastal_front", "dune_outpost", "magma_caldera", "glacial_tundra", "toxic_citadel"]
const DIFFICULTY := ["CADET", "PATROL", "HOSTILE", "VETERAN", "ELITE", "INFERNO", "EXTREME", "COMMANDER", "VANGUARD", "FROSTBITE", "SIEGE", "BIOWAR", "TEMPEST", "PRISM", "VOID COMMAND"]
static func index(map_id: String) -> int:
 return maxi(0, ORDER.find(map_id))
static func planet(map_id: String) -> String:
 if index(map_id)>=8: return "res://assets/future_update/planets/planet_%s.svg" % environment(map_id)
 return "res://assets/future_updates/maps/planet_%s.svg" % PLANETS[index(map_id)]
static func target(map_id: String) -> int:
 return 16 + index(map_id) * 6
const CHALLENGES := ["Recon patrols / aimed plasma", "Canopy ambush / flanking wings", "Orbital crossfire / drifting hazards", "Naval V-wings / guardian cruiser", "Sandstorm charge runs / escort formation", "Thermal ring attacks / caldera guardian", "Cryo orbiters / converging volleys", "Citadel mixed squadrons / command guardian", "Lava interceptors / thermal guardian", "Ice orbiters / cryo crossfire", "Desert siege / bomber escorts", "Toxic drones / refinery guardian", "Storm fighters / charged crossfire", "Crystal destroyers / converging volleys", "Void fleet / battleship command"]
const ROSTERS := [["pursuer","gunner"], ["flanker","pursuer","gunner"], ["orbiter","gunner","pursuer"], ["gunner","flanker","pursuer"], ["charger","flanker","gunner"], ["orbiter","gunner","charger"], ["orbiter","flanker","charger"], ["charger","gunner","orbiter","flanker"], ["charger","flanker","gunner"], ["orbiter","gunner","charger"], ["gunner","charger","flanker"], ["orbiter","charger","gunner"], ["flanker","orbiter","gunner"], ["gunner","orbiter","charger"], ["charger","gunner","orbiter","flanker"]]
static func challenge(id: String) -> String:
 return CHALLENGES[index(id)]
static func has_boss(id: String) -> bool:
 return index(id)>=3
static func attack_interval(id: String) -> float:
 var level:=index(id)
 return 4.4-mini(level,7)*0.27-maxi(0,level-7)*0.09

static func par_time(id: String) -> float:
 return 120.0+index(id)*20.0+(30.0 if has_boss(id) else 0.0)
static func damage_budget(ship_id: String) -> int:
 return maxi(1,int(Game.SHIPS.get(ship_id,Game.SHIPS.valkyrie).max_lives)/2)
static func rating(id: String,ship_id: String,damage: int,seconds: float) -> int:
 return 1+int(damage<=damage_budget(ship_id))+int(seconds<=par_time(id))

# Separate stable IDs avoid overwriting the original desert/toxic save entries.
static func environment(id: String) -> String:
 return id.trim_prefix("advanced_")
static func advanced(id: String) -> bool:
 return index(id)>=8
static func spawn_interval(id: String) -> float:
 var level:=index(id)
 return 1.9-mini(level,7)*0.13-maxi(0,level-7)*0.045
static func movement_speed(id: String) -> float:
 var level:=index(id)
 return 85.0+mini(level,7)*13+maxi(0,level-7)*6
static func projectile_speed(id: String) -> float:
 var level:=index(id)
 return 220.0+mini(level,7)*10+maxi(0,level-7)*6
static func enemy_health(id: String,role: String) -> int:
 return (2 if role in ["gunner","orbiter"] else 1)+int(ceil(maxi(0,index(id)-7)/2.0))
static func enemy_art(id: String,role: String) -> String:
 var kinds:={"pursuer":"scout","flanker":"interceptor","charger":"fighter","orbiter":"plasma_drone","gunner":"bomber","boss":"boss_battleship"}
 if index(id)>=12 and role=="gunner":return "res://assets/future_update/enemies/enemy_destroyer.svg"
 return "res://assets/future_update/enemies/enemy_%s.svg" % kinds.get(role,"scout")
