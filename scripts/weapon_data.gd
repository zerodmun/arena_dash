@static_unload
class_name WeaponData
extends RefCounted
## Runtime snapshot of the existing catalog. Prices and entitlements stay in Game.
var id: String
var texture: Texture2D
var speed: float
var damage: int
var lifetime: float
var radius: float
var visual_scale: Vector2
var color: Color
var pattern: Array[Dictionary]
static var _catalog_cache: Dictionary = {}
static func from_catalog(weapon_id: String) -> WeaponData:
 if not Game.WEAPONS.has(weapon_id):return null
 if _catalog_cache.has(weapon_id):return _catalog_cache[weapon_id]
 var config: Dictionary=Game.WEAPONS[weapon_id]
 var data:=WeaponData.new()
 data.id=weapon_id;data.texture=load(config.texture)
 data.speed=config.projectile_speed;data.damage=config.damage
 data.lifetime=config.lifetime;data.radius=config.collision_radius
 data.visual_scale=config.visual_scale;data.color=config.color
 data.pattern=EquipmentCatalog.firing_pattern(config)
 if data.texture==null or data.speed<=0 or data.lifetime<=0 or data.radius<=0 or data.pattern.is_empty():return null
 for sample in data.pattern: sample.make_read_only()
 data.pattern.make_read_only()
 _catalog_cache[weapon_id]=data
 return data
