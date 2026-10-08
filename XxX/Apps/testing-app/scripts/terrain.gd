class_name ArenaTerrain
extends Node2D
## Deterministic natural terrain, with contour shading and animated shallows.
var biome := "coast"
var terrain_size := Vector2(3400, 2200)
var _time := 0.0
var _refresh := 0.0

func _process(delta: float) -> void:
	_time += delta
	_refresh += delta
	if biome == "coast" and _refresh > 0.12:
		_refresh = 0.0
		queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91827
	if biome == "coast":
		draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("175565"))
		# The coast is built from layered continuous curves rather than a tiled grid.
		for layer in range(6):
			var shore := PackedVector2Array([Vector2(0, 0), Vector2(3400, 0)])
			for x in range(3400, -1, -40):
				var y := 520.0 + sin(x * 0.0025) * 170.0 + cos(x * 0.006) * 60.0 + layer * 34.0
				shore.append(Vector2(x, y))
			var colors := [Color("bba976"), Color("cbb887"), Color("ddcc9a"), Color("759a91"), Color("448c8e"), Color("29747e")]
			draw_colored_polygon(shore, colors[layer])
		for i in range(100):
			var x := rng.randf_range(0, 3400)
			var y := rng.randf_range(850, 2180)
			var length := rng.randf_range(25, 100)
			var offset := sin(_time * 0.8 + i) * 10.0
			draw_line(Vector2(x, y + offset), Vector2(x + length, y + offset - 3), Color(0.58, 0.88, 0.88, 0.13), 2.0, true)
		# Sand islands with shallow-water halos and raised rocky centers.
		for i in range(13):
			var pos := Vector2(rng.randf_range(100, 3300), rng.randf_range(950, 2100))
			var radius := rng.randf_range(35, 100)
			for layer in range(5):
				var island := PackedVector2Array()
				var radius_scale := 1.4 - layer * 0.14
				for point in range(48):
					var angle := float(point) / 48.0 * TAU
					var irregular := 1.0 + sin(angle * 3 + i) * 0.12 + cos(angle * 5) * 0.05
					island.append(pos + Vector2(cos(angle) * 1.35, sin(angle) * 0.8) * radius * radius_scale * irregular)
				var colors := [Color("29747e"), Color("438e90"), Color("73aaa1"), Color("cabb8b"), Color("dbcea4")]
				draw_colored_polygon(island, colors[layer])
	else:
		draw_rect(Rect2(Vector2.ZERO, terrain_size), Color("ac8152"))
		for i in range(32):
			var start := Vector2(rng.randf_range(-300, 3100), rng.randf_range(0, 2200))
			var width := rng.randf_range(180, 700)
			var dune := PackedVector2Array()
			for step in range(25):
				var t := float(step) / 24.0
				dune.append(start + Vector2(t * width, sin(t * PI) * -65))
			var low := dune.duplicate()
			for step in range(24, -1, -1):
				var t := float(step) / 24.0
				low.append(start + Vector2(t * width + 35, sin(t * PI) * 75 + 8))
			draw_colored_polygon(low, Color("987047"))
			draw_polyline(dune, Color("e4c291"), 5.0, true)
			for ridge in range(1, 5):
				var line := dune.duplicate()
				for index in line.size():
					line[index] += Vector2(-ridge * 8, -ridge * 7)
				draw_polyline(line, Color(0.91, 0.75, 0.52, 0.16), 2.0, true)
		for i in range(450):
			var pos := Vector2(rng.randf_range(0, 3400), rng.randf_range(0, 2200))
			draw_circle(pos, rng.randf_range(1.0, 3.0), Color(0.25, 0.18, 0.1, 0.16))
		# A weathered landing strip gives the outpost a readable landmark.
		draw_rect(Rect2(1350, 550, 700, 1100), Color(0.2, 0.23, 0.22, 0.5))
		for y in range(600, 1650, 160):
			draw_rect(Rect2(1695, y, 10, 75), Color("d2c5a1"))
