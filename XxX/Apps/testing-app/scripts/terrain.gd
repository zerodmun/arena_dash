class_name ArenaTerrain
extends Node2D
## Deterministic natural terrain and environmental biomes, with contour shading and animated effects.
var biome := "coast"
var terrain_size := Vector2(3400, 2200)
var _time := 0.0
var _refresh := 0.0

func _process(delta: float) -> void:
	_time += delta
	_refresh += delta
	if (biome in ["coast", "volcano", "toxic"]) and _refresh > 0.10:
		_refresh = 0.0
		queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91827
	match biome:
		"coast":
			_draw_coast(rng)
		"desert":
			_draw_desert(rng)
		"volcano":
			_draw_volcano(rng)
		"glacier":
			_draw_glacier(rng)
		"toxic":
			_draw_toxic(rng)
		"cyber":
			_draw_cyber(rng)
		"forest":
			_draw_forest(rng)
		"space":
			_draw_space(rng)
		_:
			_draw_desert(rng)

func _draw_coast(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("175565"))
	# The coast is built from layered continuous curves
	for layer in range(6):
		var shore := PackedVector2Array([Vector2(0, 0), Vector2(3400, 0)])
		for x in range(3400, -1, -40):
			var y := 520.0 + sin(x * 0.0025) * 170.0 + cos(x * 0.006) * 60.0 + layer * 34.0
			shore.append(Vector2(x, y))
		var colors := [Color("bba976"), Color("cbb887"), Color("ddcc9a"), Color("759a91"), Color("448c8e"), Color("29747e")]
		draw_colored_polygon(shore, colors[layer])
	# Animated shallow water surf ripples
	for i in range(120):
		var x := rng.randf_range(0, 3400)
		var y := rng.randf_range(800, 2180)
		var length := rng.randf_range(30, 110)
		var offset := sin(_time * 0.9 + i) * 12.0
		draw_line(Vector2(x, y + offset), Vector2(x + length, y + offset - 3), Color(0.58, 0.88, 0.88, 0.16), 2.5, true)
	# Sand islands with shallow-water halos and raised rocky centers
	for i in range(14):
		var pos := Vector2(rng.randf_range(120, 3280), rng.randf_range(920, 2120))
		var radius := rng.randf_range(40, 110)
		for layer in range(5):
			var island := PackedVector2Array()
			var radius_scale := 1.4 - layer * 0.14
			for point in range(48):
				var angle := float(point) / 48.0 * TAU
				var irregular := 1.0 + sin(angle * 3 + i) * 0.12 + cos(angle * 5) * 0.05
				island.append(pos + Vector2(cos(angle) * 1.35, sin(angle) * 0.8) * radius * radius_scale * irregular)
			var colors := [Color("29747e"), Color("438e90"), Color("73aaa1"), Color("cabb8b"), Color("dbcea4")]
			draw_colored_polygon(island, colors[layer])

func _draw_desert(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("ac8152"))
	for i in range(36):
		var start := Vector2(rng.randf_range(-300, 3100), rng.randf_range(0, 2200))
		var width := rng.randf_range(200, 750)
		var dune := PackedVector2Array()
		for step in range(25):
			var t := float(step) / 24.0
			dune.append(start + Vector2(t * width, sin(t * PI) * -65))
		var low := dune.duplicate()
		for step in range(24, -1, -1):
			var t := float(step) / 24.0
			low.append(start + Vector2(t * width + 38, sin(t * PI) * 78 + 8))
		draw_colored_polygon(low, Color("987047"))
		draw_polyline(dune, Color("e4c291"), 5.5, true)
		for ridge in range(1, 5):
			var line := dune.duplicate()
			for index in line.size():
				line[index] += Vector2(-ridge * 8, -ridge * 7)
			draw_polyline(line, Color(0.91, 0.75, 0.52, 0.18), 2.0, true)
	for i in range(480):
		var pos := Vector2(rng.randf_range(0, 3400), rng.randf_range(0, 2200))
		draw_circle(pos, rng.randf_range(1.0, 3.5), Color(0.25, 0.18, 0.1, 0.18))
	# A weathered military landing strip gives the outpost an unmistakable landmark
	draw_rect(Rect2(1300, 500, 800, 1200), Color(0.18, 0.22, 0.21, 0.55))
	draw_rect(Rect2(1310, 510, 780, 1180), Color(0.25, 0.28, 0.27, 0.35))
	for y in range(560, 1660, 150):
		draw_rect(Rect2(1690, y, 16, 75), Color("f0e6c8"))
	# Runway threshold stripes
	for x in range(1340, 2060, 48):
		draw_rect(Rect2(x, 520, 24, 60), Color("d2c5a1"))
		draw_rect(Rect2(x, 1620, 24, 60), Color("d2c5a1"))

func _draw_volcano(rng: RandomNumberGenerator) -> void:
	# Magma Caldera: Volcanic basalt crust, glowing molten lava channels
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("181210"))
	# Jagged basalt terrain plates
	for i in range(24):
		var center := Vector2(rng.randf_range(100, 3300), rng.randf_range(100, 2100))
		var poly := PackedVector2Array()
		for pt in range(8):
			var angle := float(pt) / 8.0 * TAU
			poly.append(center + Vector2(cos(angle), sin(angle)) * rng.randf_range(120, 340))
		draw_colored_polygon(poly, Color("221a16"))
		draw_polyline(poly, Color("342822"), 3.0, true)
	# Glowing animated lava river streams
	for r in range(4):
		var river := PackedVector2Array()
		var y_start := 300.0 + r * 500.0
		for x in range(0, 3450, 60):
			var pulse := sin(_time * 1.5 + x * 0.005 + r) * 35.0
			var y := y_start + sin(x * 0.002 + r * 1.2) * 140.0 + pulse
			river.append(Vector2(x, y))
		draw_polyline(river, Color("b91c1c"), 48.0, true)
		draw_polyline(river, Color("f97316"), 28.0, true)
		draw_polyline(river, Color("fef08a"), 10.0, true)
	# Thermal fissure glow spots & volcanic embers
	for i in range(120):
		var pos := Vector2(rng.randf_range(50, 3350), rng.randf_range(50, 2150))
		var radius := rng.randf_range(4.0, 16.0)
		draw_circle(pos, radius, Color(0.98, 0.45, 0.1, 0.25))
		draw_circle(pos, radius * 0.5, Color(1.0, 0.85, 0.25, 0.45))

func _draw_glacier(rng: RandomNumberGenerator) -> void:
	# Glacial Tundra: Deep polar sapphire ice shelf with crystalline pressure crevasses
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("082032"))
	for layer in range(5):
		var shelf := PackedVector2Array([Vector2(0, 0), Vector2(3400, 0)])
		for x in range(3400, -1, -50):
			var y := 400.0 + sin(x * 0.003) * 150.0 + layer * 70.0
			shelf.append(Vector2(x, y))
		var colors := [Color("0e3854"), Color("1b4965"), Color("2b6b8b"), Color("62b6cb"), Color("bee9e8")]
		draw_colored_polygon(shelf, colors[layer])
	# Deep crystalline sapphire ice crevasses
	for i in range(20):
		var start := Vector2(rng.randf_range(100, 3300), rng.randf_range(300, 1900))
		var crevasse := PackedVector2Array([start])
		var curr := start
		for seg in range(6):
			curr += Vector2(rng.randf_range(60, 140), rng.randf_range(-40, 60))
			crevasse.append(curr)
		draw_polyline(crevasse, Color("0284c7"), 12.0, true)
		draw_polyline(crevasse, Color("e0f2fe"), 3.0, true)
	# Polar frost flakes and ice glints
	for i in range(350):
		var pos := Vector2(rng.randf_range(0, 3400), rng.randf_range(0, 2200))
		draw_circle(pos, rng.randf_range(1.5, 3.5), Color(0.75, 0.92, 1.0, 0.45))

func _draw_toxic(rng: RandomNumberGenerator) -> void:
	# Toxic Citadel: Corroded industrial bio-refinery with fluorescent acid canals
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("0c1410"))
	# Industrial steel plating foundation
	var tile_size := 200.0
	for x in range(0, 3400, int(tile_size)):
		draw_line(Vector2(x, 0), Vector2(x, 2200), Color(0.12, 0.22, 0.16, 0.4), 2.0)
	for y in range(0, 2200, int(tile_size)):
		draw_line(Vector2(0, y), Vector2(3400, y), Color(0.12, 0.22, 0.16, 0.4), 2.0)
	# Acid waste canal
	for r in range(3):
		var canal := PackedVector2Array()
		var y_base := 400.0 + r * 650.0
		for x in range(0, 3450, 70):
			var wave := sin(_time * 1.8 + x * 0.006 + r) * 20.0
			canal.append(Vector2(x, y_base + sin(x * 0.003) * 90.0 + wave))
		draw_polyline(canal, Color("14532d"), 42.0, true)
		draw_polyline(canal, Color("84cc16"), 22.0, true)
		draw_polyline(canal, Color("bef264"), 8.0, true)
	# Biohazard hazard zones and warning markings
	for i in range(16):
		var pos := Vector2(rng.randf_range(200, 3200), rng.randf_range(200, 2000))
		draw_rect(Rect2(pos, Vector2(180, 80)), Color("1e293b"))
		draw_rect(Rect2(pos + Vector2(10, 10), Vector2(160, 60)), Color(0.1, 0.35, 0.15, 0.5))
		for h in range(5):
			draw_line(pos + Vector2(25 + h * 30, 20), pos + Vector2(40 + h * 30, 60), Color("facc15"), 3.0)

func _draw_cyber(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("020b14"))
	# Circuit pathways & hex grid nodes
	var step := 120.0
	for x in range(0, 3400, int(step)):
		draw_line(Vector2(x, 0), Vector2(x, 2200), Color(0.06, 0.35, 0.55, 0.22), 1.5)
	for y in range(0, 2200, int(step)):
		draw_line(Vector2(0, y), Vector2(3400, y), Color(0.06, 0.35, 0.55, 0.22), 1.5)
	for i in range(90):
		var pos := Vector2(rng.randf_range(50, 3350), rng.randf_range(50, 2150))
		draw_circle(pos, 4.0, Color("00f2fe"))
		draw_circle(pos, 10.0, Color(0, 0.95, 1.0, 0.18))

func _draw_forest(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("08140c"))
	# Canopy rings & bioluminescent moss pools
	for i in range(40):
		var pos := Vector2(rng.randf_range(100, 3300), rng.randf_range(100, 2100))
		var radius := rng.randf_range(60, 160)
		draw_circle(pos, radius, Color(0.04, 0.22, 0.12, 0.45))
		draw_circle(pos, radius * 0.6, Color(0.08, 0.38, 0.18, 0.55))
		draw_circle(pos, radius * 0.25, Color("22c55e", 0.35))

func _draw_space(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("030208"))
	# Cosmic nebula clouds
	for i in range(12):
		var pos := Vector2(rng.randf_range(200, 3200), rng.randf_range(200, 2000))
		var rad := rng.randf_range(200, 450)
		draw_circle(pos, rad, Color(0.45, 0.15, 0.65, 0.08))
		draw_circle(pos + Vector2(40, -30), rad * 0.7, Color(0.15, 0.35, 0.75, 0.09))
	# Starfield with varying magnitudes
	for i in range(500):
		var pos := Vector2(rng.randf_range(0, 3400), rng.randf_range(0, 2200))
		var r := rng.randf_range(1.0, 3.2)
		var tint := Color("ffffff") if i % 3 == 0 else Color("80d8ff")
		draw_circle(pos, r, tint)
