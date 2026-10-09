class_name Campaign
extends RefCounted
## Stable level IDs follow the planet asset naming convention.
const ORDER := ["cyber", "forest", "space", "coast", "desert", "volcano", "glacier", "toxic"]
const PLANETS := ["cyber_matrix", "primal_jungle", "void_horizon", "coastal_front", "dune_outpost", "magma_caldera", "glacial_tundra", "toxic_citadel"]
const DIFFICULTY := ["CADET", "PATROL", "HOSTILE", "VETERAN", "ELITE", "INFERNO", "EXTREME", "COMMANDER"]
static func index(map_id: String) -> int:
 return maxi(0, ORDER.find(map_id))
static func planet(map_id: String) -> String:
 return "res://assets/future_updates/maps/planet_%s.svg" % PLANETS[index(map_id)]
static func target(map_id: String) -> int:
 return 16 + index(map_id) * 6
const CHALLENGES := ["Recon patrols / aimed plasma", "Canopy ambush / flanking wings", "Orbital crossfire / drifting hazards", "Naval V-wings / guardian cruiser", "Sandstorm charge runs / escort formation", "Thermal ring attacks / caldera guardian", "Cryo orbiters / converging volleys", "Citadel mixed squadrons / command guardian"]
const ROSTERS := [["pursuer","gunner"], ["flanker","pursuer","gunner"], ["orbiter","gunner","pursuer"], ["gunner","flanker","pursuer"], ["charger","flanker","gunner"], ["orbiter","gunner","charger"], ["orbiter","flanker","charger"], ["charger","gunner","orbiter","flanker"]]
static func challenge(id: String) -> String:
 return CHALLENGES[index(id)]
static func has_boss(id: String) -> bool:
 return index(id)>=3
static func attack_interval(id: String) -> float:
 return 4.4-index(id)*0.27

static func par_time(id: String) -> float:
 return 120.0+index(id)*20.0+(30.0 if has_boss(id) else 0.0)
static func damage_budget(ship_id: String) -> int:
 return maxi(1,int(Game.SHIPS.get(ship_id,Game.SHIPS.valkyrie).max_lives)/2)
static func rating(id: String,ship_id: String,damage: int,seconds: float) -> int:
 return 1+int(damage<=damage_budget(ship_id))+int(seconds<=par_time(id))
