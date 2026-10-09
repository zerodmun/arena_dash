class_name HangarPreview
extends Control
## Decorative preview only: shots never spawn gameplay bodies or change score.
var mode := "weapon"
var ship_id := "valkyrie"
var weapon_id := "plasma"
var map_id := "cyber"
var shots: Array[Dictionary] = []
var _shot_timer := 0.0
var _time := 0.0
var _textures: Dictionary = {}

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(ship: String, weapon: String, map: String, preview_mode: String) -> void:
	ship_id = ship
	weapon_id = weapon
	map_id = map
	mode = preview_mode
	shots.clear()
	_shot_timer = 0.0
	queue_redraw()

func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	if mode == "weapon":
		_shot_timer -= delta
		if _shot_timer <= 0.0:
			_shot_timer = maxf(float(Game.SHIPS[ship_id].fire_rate), 0.20)
			_emit_shots()
		for i in range(shots.size() - 1, -1, -1):
			shots[i].position += shots[i].direction * 320.0 * delta
			shots[i].life -= delta
			if shots[i].life <= 0.0 or shots[i].position.y < -50:
				shots.remove_at(i)
	queue_redraw()

func _emit_shots() -> void:
	if size.x < 1 or size.y < 1:
		return
	var origin := size * Vector2(0.5, 0.76) - Vector2(0, 60)
	var pattern: String = Game.WEAPONS[weapon_id].pattern
	if pattern == "twin":
		_add_shot(origin + Vector2(-24, 0), Vector2.UP)
		_add_shot(origin + Vector2(24, 0), Vector2.UP)
	elif pattern == "spread":
		for angle in [-0.31, 0.0, 0.31]:
			_add_shot(origin, Vector2.UP.rotated(angle))
	else:
		_add_shot(origin, Vector2.UP)

func _add_shot(origin: Vector2, direction: Vector2) -> void:
	shots.append({"position": origin, "direction": direction, "life": 1.8})

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var map: Dictionary = Game.MAPS.get(map_id, Game.MAPS["cyber"])
	var base: Color = map.get("floor_color", Color("0d1c2a")) if mode == "map" else Color("0a1723")
	draw_rect(Rect2(Vector2.ZERO, size), base)
	if mode == "map":
		_draw_map(map)
	else:
		for x in range(0, int(size.x), 40):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.24, 0.4, 0.5, 0.13))
		for y in range(0, int(size.y), 40):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.24, 0.4, 0.5, 0.13))
		var col: Color = Game.WEAPONS[weapon_id].color
		for shot in shots:
			var pos: Vector2 = shot.position
			var direction: Vector2 = shot.direction
			draw_line(pos, pos - direction * 36, Color(col, 0.18), 10, true)
			draw_line(pos, pos - direction * 24, Color(col, 0.7), 3, true)
			var bullet := _texture(Game.WEAPONS[weapon_id].texture)
			draw_set_transform(pos, direction.angle() + PI / 2)
			draw_texture_rect(bullet, Rect2(-10, -20, 20, 40), false)
			draw_set_transform(Vector2.ZERO)
	var center := size * Vector2(0.5, 0.76 if mode == "weapon" else 0.52)
	var ship_size := minf(size.x * 0.32, 155.0)
	var ship_color: Color = Game.SHIPS[ship_id].color
	draw_circle(center + Vector2(0, 40), 27, Color(ship_color, 0.08))
	draw_line(center + Vector2(-10, 44), center + Vector2(-10, 75 + sin(_time * 12) * 6), Color(ship_color, 0.65), 5, true)
	draw_line(center + Vector2(10, 44), center + Vector2(10, 75 + cos(_time * 12) * 6), Color(ship_color, 0.65), 5, true)
	draw_texture_rect(_texture(Game.SHIPS[ship_id].texture), Rect2(center - Vector2.ONE * ship_size / 2, Vector2.ONE * ship_size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("324755"), false, 1)

func _draw_map(map: Dictionary) -> void:
	if map_id in ["coast", "desert", "volcano", "glacier", "toxic"]:
		var texture := _texture(map.icon)
		var extent := texture.get_size() * minf(size.x / texture.get_width(), size.y / texture.get_height())
		draw_texture_rect(texture, Rect2((size - extent) / 2, extent), false, Color(1, 1, 1, 0.55))
	else:
		for x in range(0, int(size.x), 45):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(map.color, 0.12))
		for y in range(0, int(size.y), 45):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(map.color, 0.12))
	var asset := "res://assets/obstacle_pillar.svg"
	if map_id == "forest":
		asset = "res://assets/obstacle_tree.svg"
	elif map_id == "space":
		asset = "res://assets/obstacle_asteroid.svg"
	elif map_id in ["coast", "desert"]:
		asset = "res://assets/obstacle_cargo.svg"
	elif map_id == "volcano":
		asset = "res://assets/obstacle_basalt.svg"
	elif map_id == "glacier":
		asset = "res://assets/obstacle_cryo.svg"
	elif map_id == "toxic":
		asset = "res://assets/obstacle_barrel.svg"
	for i in range(6):
		var pos := Vector2(0.20 + (i % 3) * 0.3, 0.23 + floori(float(i) / 3) * 0.5) * size
		pos += Vector2(sin(_time * 0.6 + i), cos(_time * 0.45 + i)) * 14
		var obstacle_size := Vector2(72, 46) if map_id in ["coast", "desert"] else (Vector2(64, 64) if map_id in ["volcano", "glacier", "toxic"] else Vector2(65, 65))
		draw_texture_rect(_texture(asset), Rect2(pos - obstacle_size / 2, obstacle_size), false)
