class_name EquipmentCatalog
extends RefCounted
## Stable IDs and all price/visual/combat properties share one source.
const LEGACY_FREE_SHIPS := ["falcon", "aurora", "valkyrie", "titan", "phantom", "tempest", "mirage", "saucer", "rocket", "wedge", "speeder", "booster"]
const LEGACY_FREE_WEAPONS := ["ion", "plasma", "twin_laser", "quantum_spread"]

const SHIPS := {

    "falcon": {
        "id": "falcon", "price": 0, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "FALCON", "class": "STRIKE FIGHTER",
        "desc": "Swept-wing strike aircraft. Fast acceleration with reliable armor.",
        "texture": "res://assets/player_falcon.svg", "speed": 410.0,
        "max_lives": 3, "fire_rate": 0.15, "color": Color(1.0, 0.65, 0.25),
    },
    "aurora": {
        "id": "aurora", "price": 0, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "AURORA", "class": "RECON WING",
        "desc": "A silver delta-wing aircraft with reinforced shields and precise handling.",
        "texture": "res://assets/player_aurora.svg", "speed": 330.0,
        "max_lives": 4, "fire_rate": 0.16, "color": Color(0.4, 0.9, 0.85),
    },
    "valkyrie": {
        "id": "valkyrie", "price": 0, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48),
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
        "id": "titan", "price": 150, "visual_scale": 0.3, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48),
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
        "id": "phantom", "price": 200, "visual_scale": 0.26, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48),
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
        "id": "tempest", "price": 250, "visual_scale": 0.31, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48),
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
        "id": "mirage", "price": 300, "visual_scale": 0.27, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48),
        "name": "MIRAGE",
        "class": "SKYSTALKER",
        "desc": "Twin-boom canard prototype featuring micro-vectoring and solar plasma drives.",
        "texture": "res://assets/player_mirage.svg",
        "speed": 430.0,
        "max_lives": 3,
        "fire_rate": 0.13,
        "color": Color(0.92, 0.70, 0.05),
    },
    "saucer": {"id": "saucer", "price": 350, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "SAUCER", "class": "ORBITAL DEFENDER", "desc": "Expansion fleet / orbital defender", "texture": "res://assets/future_updates/aircraft/player_saucer.svg", "speed": 320.0, "max_lives": 5, "fire_rate": 0.19, "color": Color("69dfff")},
    "rocket": {"id": "rocket", "price": 400, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "ROCKET", "class": "SOLAR STRIKER", "desc": "Expansion fleet / solar striker", "texture": "res://assets/future_updates/aircraft/player_rocket.svg", "speed": 420.0, "max_lives": 3, "fire_rate": 0.15, "color": Color("ff6969")},
    "wedge": {"id": "wedge", "price": 450, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "WEDGE", "class": "STEALTH INTERCEPTOR", "desc": "Expansion fleet / stealth interceptor", "texture": "res://assets/future_updates/aircraft/player_wedge.svg", "speed": 440.0, "max_lives": 2, "fire_rate": 0.12, "color": Color("56baff")},
    "speeder": {"id": "speeder", "price": 500, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "SPEEDER", "class": "DELTA RUNNER", "desc": "Expansion fleet / delta runner", "texture": "res://assets/future_updates/aircraft/player_speeder.svg", "speed": 470.0, "max_lives": 2, "fire_rate": 0.11, "color": Color("a7f570")},
    "booster": {"id": "booster", "price": 600, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "BOOSTER", "class": "HEAVY ESCORT", "desc": "Expansion fleet / heavy escort", "texture": "res://assets/future_updates/aircraft/player_booster.svg", "speed": 300.0, "max_lives": 5, "fire_rate": 0.16, "color": Color("ffc35c")},
    "solaris": {
        "id": "solaris", "price": 750, "visual_scale": 0.28, "collision_radius": 34.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "SOLARIS", "class": "SOLAR APEX",
        "desc": "Imperial gold flagship with high-velocity solar thrusters and radiant armor.",
        "texture": "res://assets/player_solaris.svg", "speed": 460.0,
        "max_lives": 4, "fire_rate": 0.12, "color": Color(1.0, 0.82, 0.15),
    },
    "vortex": {
        "id": "vortex", "price": 900, "visual_scale": 0.26, "collision_radius": 32.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "VORTEX", "class": "VOID HARBINGER",
        "desc": "Obsidian stealth interceptor harnessing quantum singularities and warp vectoring.",
        "texture": "res://assets/player_vortex.svg", "speed": 480.0,
        "max_lives": 3, "fire_rate": 0.10, "color": Color(0.2, 0.85, 1.0),
    },
    "nemesis": {
        "id": "nemesis", "price": 1100, "visual_scale": 0.3, "collision_radius": 36.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "NEMESIS", "class": "HYPER PREDATOR",
        "desc": "Aggressive crimson assault fighter with heavy armor plating and quad kinetic mounts.",
        "texture": "res://assets/player_nemesis.svg", "speed": 420.0,
        "max_lives": 5, "fire_rate": 0.13, "color": Color(1.0, 0.18, 0.35),
    },
    "chronos": {
        "id": "chronos", "price": 1400, "visual_scale": 0.3, "collision_radius": 36.0, "muzzle": Vector2(0,-68), "thruster": Vector2(0,48), "name": "CHRONOS", "class": "TEMPORAL AEGIS",
        "desc": "Apex dreadnought with crystalline emerald armor and temporal distortion drives.",
        "texture": "res://assets/player_chronos.svg", "speed": 440.0,
        "max_lives": 5, "fire_rate": 0.11, "color": Color(0.25, 0.98, 0.70),
    },
}

const WEAPONS := {
    "ion": {
        "id": "ion", "price": 0, "projectile_speed": 900.0, "visual_scale": Vector2(0.22,0.22), "collision_radius": 14.0, "damage": 1, "lifetime": 2.4, "fire_interval_multiplier": 1.0, "name": "ION CANNON", "desc": "Fast golden ion rounds with a long luminous wake.",
        "texture": "res://assets/bullet_ion.svg", "color": Color(1.0, 0.72, 0.25), "pattern": "single",
    },
    "plasma": {
        "id": "plasma", "price": 0, "projectile_speed": 680.0, "visual_scale": Vector2(0.22,0.22), "collision_radius": 14.0, "damage": 1, "lifetime": 2.4, "fire_interval_multiplier": 1.0,
        "name": "PLASMA BOLT",
        "desc": "Concentrated high-velocity plasma core with electric aura.",
        "texture": "res://assets/bullet.svg",
        "color": Color(0.22, 0.74, 1.0),
        "pattern": "single",
    },
    "twin_laser": {
        "id": "twin_laser", "price": 200, "projectile_speed": 780.0, "visual_scale": Vector2(0.24,0.28), "collision_radius": 14.0, "damage": 1, "lifetime": 2.4, "fire_interval_multiplier": 1.0,
        "name": "TWIN LASERS",
        "desc": "Dual high-energy crimson beams fired simultaneously from wingtips.",
        "texture": "res://assets/bullet_laser.svg",
        "color": Color(1.0, 0.25, 0.35),
        "pattern": "twin",
    },
    "quantum_spread": {
        "id": "quantum_spread", "price": 300, "projectile_speed": 600.0, "visual_scale": Vector2(0.2,0.2), "collision_radius": 14.0, "damage": 1, "lifetime": 2.4, "fire_interval_multiplier": 1.0,
        "name": "QUANTUM SPREAD",
        "desc": "3-way spread energy bursts sweeping a forward cone.",
        "texture": "res://assets/bullet_quantum.svg",
        "color": Color(0.75, 0.45, 1.0),
        "pattern": "spread",
    },
    "plasma_lance": {
        "id": "plasma_lance", "price": 1050, "projectile_speed": 960.0, "visual_scale": Vector2(0.22,0.28), "collision_radius": 14.0, "damage": 2, "lifetime": 2.4, "fire_interval_multiplier": 1.4,
        "name": "PLASMA LANCE",
        "desc": "Four emerald lances in a symmetrical forward spread.",
        "texture": "res://assets/bullet_lance.svg",
        "color": Color(0.15, 1.0, 0.78),
        "pattern": "spread", "projectile_count": 4, "spread_degrees": 30.0, "muzzle_spacing": 16.0, "minimum_interval": 0.24,
    },
    "nova_burst": {
        "id": "nova_burst", "price": 1680, "projectile_speed": 720.0, "visual_scale": Vector2(0.26,0.26), "collision_radius": 14.0, "damage": 2, "lifetime": 2.4, "fire_interval_multiplier": 1.5,
        "name": "NOVA BURST",
        "desc": "Five solar-plasma orbs sweeping a wide forward cone.",
        "texture": "res://assets/bullet_nova.svg",
        "color": Color(1.0, 0.38, 0.18),
        "pattern": "spread", "projectile_count": 5, "spread_degrees": 48.0, "muzzle_spacing": 14.0, "minimum_interval": 0.26,
    }
}


## Shared by live combat and the decorative Hangar preview.
static func firing_pattern(weapon: Dictionary) -> Array[Dictionary]:
    var pattern: String = weapon.pattern
    var count := int(weapon.get("projectile_count", 3 if pattern == "spread" else 2 if pattern in ["twin", "burst"] else 1))
    var spread := float(weapon.get("spread_degrees", 36.0 if pattern == "spread" else 10.0 if pattern == "burst" else 0.0))
    var spacing := float(weapon.get("muzzle_spacing", 52.0 if pattern == "twin" else 32.0 if pattern == "burst" else 0.0))
    var shots: Array[Dictionary] = []
    for i in count:
        var offset := float(i) - float(count - 1) * 0.5
        shots.append({"angle": deg_to_rad(spread * offset / maxf(count - 1, 1)), "offset": offset * spacing})
    return shots

static func firing_interval(ship: Dictionary, weapon: Dictionary) -> float:
    return maxf(float(ship.fire_rate) * float(weapon.fire_interval_multiplier), float(weapon.get("minimum_interval", 0.0)))
