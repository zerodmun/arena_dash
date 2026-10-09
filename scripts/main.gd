extends Node2D
## Main: manages expanded 3400x2200 semi-3D arena, dynamic biomes,
## procedural obstacles, space meteor shower hazards, camera tracking, and spawners.

const ARENA_WIDTH := 6800.0
const ARENA_HEIGHT := 4400.0
const WALL_THICKNESS := 48.0

@onready var camera: Camera2D = $Camera2D
@onready var arena: Node2D = $Arena
@onready var player: Player = $Player
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var pickup_spawner: PickupSpawner = $PickupSpawner
@onready var hud: HUD = $HUD

var current_arena_rect: Rect2
var _shake_strength := 0.0
var _floor_canvas: Node2D
var _obstacles: Array[Node2D] = []
var _chunks: Array[LandscapeChunk] = []

# Environmental Hazard (Meteor Showers in Deep Space)
var _mission_generation := 0
var _meteor_timer := 4.0
var _active_meteors: Array[Node2D] = []


func _ready() -> void:
    process_physics_priority=10
    Game.game_started.connect(_on_game_started)
    Game.screen_shake_requested.connect(_on_screen_shake)
    _setup_arena()
    var cache:=CombatPool.new()
    cache.name="CombatPool"
    add_child(cache)
    var atmosphere := PlanetAtmosphere.new()
    atmosphere.camera = camera
    atmosphere.z_index = 4
    camera.add_child(atmosphere)


func _process(_delta: float) -> void:
    var vp:=get_viewport_rect().size
    var visible_rect:=Rect2(camera.global_position-vp*0.6,vp*1.2)
    for chunk in _chunks:
        chunk.visible=Rect2(chunk.position,LandscapeChunk.SIZE).intersects(visible_rect)

func _physics_process(delta: float) -> void:
    # Follow after actor simulation, before the interpolated camera's physics callback.
    if is_instance_valid(player):
        camera.global_position=camera.global_position.lerp(player.global_position,1.0-exp(-7.5*delta))
    if _shake_strength>0.05:
        _shake_strength=lerpf(_shake_strength,0.0,1.0-exp(-10.0*delta))
        camera.offset=Vector2(randf_range(-_shake_strength,_shake_strength),randf_range(-_shake_strength,_shake_strength))
    else:camera.offset=Vector2.ZERO
    if Game.is_running and Game.selected_map_id=="space":
        _meteor_timer-=delta
        if _meteor_timer<=0:
            _meteor_timer+=randf_range(6.0,9.0)
            _trigger_meteor_shower()


func _on_screen_shake(strength: float) -> void:
    _shake_strength = maxf(_shake_strength, strength)


func _on_game_started() -> void:
    _mission_generation += 1
    _clear_entities()
    for obstacle in _obstacles:
        if is_instance_valid(obstacle):
            obstacle.reset_motion()
    player.position = current_arena_rect.get_center()
    player.reset_physics_interpolation()
    camera.global_position = player.position
    camera.reset_smoothing()
    _meteor_timer = 5.0


func _setup_arena() -> void:
    current_arena_rect = Rect2(0.0, 0.0, ARENA_WIDTH, ARENA_HEIGHT)

    for child in arena.get_children():
        child.queue_free()
    _obstacles.clear()

    var map_info := Game.get_current_map()

    _build_floor(map_info)
    _build_semi_3d_walls(map_info)
    _build_obstacles()
    _extend_obstacles()

    if player:
        player.position = current_arena_rect.get_center()
        camera.global_position = player.position

    # Camera bounds
    camera.limit_left = int(-WALL_THICKNESS)
    camera.limit_top = int(-WALL_THICKNESS)
    camera.limit_right = int(ARENA_WIDTH + WALL_THICKNESS)
    camera.limit_bottom = int(ARENA_HEIGHT + WALL_THICKNESS)

    enemy_spawner.arena_rect = current_arena_rect.grow(-140.0)
    pickup_spawner.arena_rect = current_arena_rect.grow(-180.0)
    camera.reset_smoothing()


func _build_floor(map_info: Dictionary) -> void:
    var bg_col: Color = map_info.get("bg_color", Color(0.015, 0.02, 0.04))

    var outer_bg := ColorRect.new()
    outer_bg.size = Vector2(ARENA_WIDTH + 800.0, ARENA_HEIGHT + 800.0)
    outer_bg.position = Vector2(-400.0, -400.0)
    outer_bg.color = bg_col
    outer_bg.z_index = -20
    arena.add_child(outer_bg)

    for y in 4:
        for x in 4:
            var chunk := LandscapeChunk.new()
            chunk.biome = Game.selected_map_id
            chunk.coordinate = Vector2i(x, y)
            chunk.position = Vector2(x * 1700, y * 1100)
            chunk.z_index = -10
            arena.add_child(chunk)
            _chunks.append(chunk)
    # Original map illustrations become bounded landmarks, never stretched to fill.
    var shader := Shader.new()
    shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); vec2 d=min(UV,vec2(1.0)-UV); float a=smoothstep(0.0,0.18,min(d.x,d.y)); COLOR=vec4(c.rgb,c.a*a*0.55); }"
    for point in [Vector2(1700, 1100), Vector2(5100, 3300)]:
        var landmark := Sprite2D.new()
        landmark.texture = load(map_info.icon)
        landmark.position = point
        landmark.scale = Vector2.ONE * 1.5
        var material := ShaderMaterial.new()
        material.shader = shader
        landmark.material = material
        landmark.z_index = -9
        arena.add_child(landmark)


func _draw_arena_floor() -> void:
    if _floor_canvas == null:
        return
    var rect := current_arena_rect
    var map_info := Game.get_current_map()

    var floor_col: Color = map_info.get("floor_color", Color(0.035, 0.06, 0.10))
    var line_col: Color = map_info.get("grid_color", Color(0.04, 0.30, 0.50, 0.22))
    var dot_col: Color = map_info.get("node_color", Color(0.22, 0.74, 1.0, 0.40))
    var wall_glow: Color = map_info.get("wall_color", Color(0.22, 0.74, 1.0, 0.95))

    # Arena interior floor
    _floor_canvas.draw_rect(rect, floor_col, true)

    # Semi-3D cyber/biome grid
    var cell_size := 100.0

    # Vertical grid lines
    var x := rect.position.x
    while x <= rect.end.x:
        _floor_canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line_col, 1.2)
        x += cell_size

    # Horizontal grid lines
    var y := rect.position.y
    while y <= rect.end.y:
        _floor_canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line_col, 1.2)
        y += cell_size

    # Glowing grid intersection nodes
    x = rect.position.x
    while x <= rect.end.x:
        y = rect.position.y
        while y <= rect.end.y:
            _floor_canvas.draw_circle(Vector2(x, y), 2.2, dot_col)
            y += cell_size
        x += cell_size

    # Perimeter boundary warning line
    _floor_canvas.draw_rect(rect.grow(-12.0), Color(wall_glow.r, wall_glow.g, wall_glow.b, 0.45), false, 2.5)


func _build_semi_3d_walls(map_info: Dictionary) -> void:
    var r := current_arena_rect
    var t := WALL_THICKNESS
    var wall_glow: Color = map_info.get("wall_color", Color(0.22, 0.74, 1.0, 0.95))

    # Top Wall
    _add_3d_wall(Vector2(-t, -t), Vector2(r.size.x + t * 2.0, t), true, wall_glow)
    # Bottom Wall
    _add_3d_wall(Vector2(-t, r.end.y), Vector2(r.size.x + t * 2.0, t), true, wall_glow)
    # Left Wall
    _add_3d_wall(Vector2(-t, -t), Vector2(t, r.size.y + t * 2.0), false, wall_glow)
    # Right Wall
    _add_3d_wall(Vector2(r.end.x, -t), Vector2(t, r.size.y + t * 2.0), false, wall_glow)


func _add_3d_wall(pos: Vector2, size: Vector2, is_horizontal: bool, bevel_col: Color) -> void:
    var body := StaticBody2D.new()
    body.position = pos + size * 0.5
    body.collision_layer = 1
    body.collision_mask = 0

    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

    # Floor Drop Shadow
    var shadow := ColorRect.new()
    shadow.size = size + Vector2(8, 12)
    shadow.position = -size * 0.5 + Vector2(2, 6)
    shadow.color = Color(0.0, 0.0, 0.0, 0.6)
    body.add_child(shadow)

    # Main Wall Face
    var wall_base := ColorRect.new()
    wall_base.size = size
    wall_base.position = -size * 0.5
    wall_base.color = Color(0.04, 0.06, 0.12)
    body.add_child(wall_base)

    # 3D Raised Bevel Strip
    var bevel := ColorRect.new()
    if is_horizontal:
        bevel.size = Vector2(size.x, 5.0)
        bevel.position = Vector2(-size.x * 0.5, size.y * 0.5 - 5.0 if pos.y < current_arena_rect.get_center().y else -size.y * 0.5)
    else:
        bevel.size = Vector2(5.0, size.y)
        bevel.position = Vector2(size.x * 0.5 - 5.0 if pos.x < current_arena_rect.get_center().x else -size.x * 0.5, -size.y * 0.5)
    bevel.color = bevel_col
    body.add_child(bevel)

    arena.add_child(body)


func _build_obstacles() -> void:
    var obstacle_scene := load("res://scenes/obstacle.tscn") as PackedScene
    if obstacle_scene == null:
        return

    var map_id: String = Game.selected_map_id

    if map_id in ["coast", "desert"]:
        for y in [450.0, 1000.0, 1650.0]:
            for x in [550.0, 1100.0, 2300.0, 2850.0]:
                var obs := obstacle_scene.instantiate() as Obstacle
                obs.position = Vector2(x, y) + Vector2(randf_range(-60, 60), randf_range(-60, 60))
                obs.position *= 2.0
                obs._bounds = current_arena_rect.grow(-140)
                obs.set_type(Obstacle.Type.CARGO)
                arena.add_child(obs)
                _obstacles.append(obs)
    elif map_id == "forest":
        # Forest Planet Biome: Dinosaur Skull Relics & Ancient Canopy Trees
        var dino_coords: Array[Vector2] = [
            Vector2(700, 600), Vector2(1700, 500), Vector2(2700, 600),
            Vector2(1100, 1100), Vector2(2300, 1100),
            Vector2(700, 1600), Vector2(1700, 1700), Vector2(2700, 1600),
            Vector2(1400, 850), Vector2(2000, 1350)
        ]
        for pos in dino_coords:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.DINO_SKULL)
            arena.add_child(obs)
            _obstacles.append(obs)

        var tree_coords: Array[Vector2] = [
            Vector2(500, 1100), Vector2(2900, 1100),
            Vector2(1200, 550), Vector2(2200, 550),
            Vector2(1200, 1650), Vector2(2200, 1650),
            Vector2(1700, 1450), Vector2(1700, 650)
        ]
        for pos in tree_coords:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.ANCIENT_TREE)
            arena.add_child(obs)
            _obstacles.append(obs)

    elif map_id == "space":
        # Cosmic Void Biome: Dense Asteroid Field
        var asteroid_coords: Array[Vector2] = [
            Vector2(600, 500), Vector2(1100, 600), Vector2(1700, 450), Vector2(2300, 600), Vector2(2800, 500),
            Vector2(800, 1100), Vector2(1400, 950), Vector2(2000, 1250), Vector2(2600, 1100),
            Vector2(600, 1700), Vector2(1100, 1600), Vector2(1700, 1750), Vector2(2300, 1600), Vector2(2800, 1700),
            Vector2(1400, 1350), Vector2(2000, 850)
        ]
        for pos in asteroid_coords:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.ASTEROID)
            arena.add_child(obs)
            _obstacles.append(obs)

    elif map_id == "volcano":
        # Magma Caldera: Jagged Basalt Spire Obstacles
        for pos in [
            Vector2(650, 500), Vector2(1200, 600), Vector2(2200, 550), Vector2(2800, 500),
            Vector2(750, 1100), Vector2(1300, 850), Vector2(2100, 1350), Vector2(2650, 1100),
            Vector2(600, 1700), Vector2(1200, 1600), Vector2(1700, 1750), Vector2(2200, 1650), Vector2(2800, 1700),
            Vector2(1700, 450)
        ]:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.BASALT)
            arena.add_child(obs)
            _obstacles.append(obs)

    elif map_id == "glacier":
        # Glacial Tundra: Cryo Monolith & Crystalline Ice Blocks
        for pos in [
            Vector2(600, 550), Vector2(1150, 500), Vector2(2250, 500), Vector2(2800, 550),
            Vector2(800, 1100), Vector2(1350, 800), Vector2(2050, 1400), Vector2(2600, 1100),
            Vector2(650, 1650), Vector2(1150, 1700), Vector2(1700, 1720), Vector2(2250, 1650), Vector2(2750, 1650),
            Vector2(1700, 480)
        ]:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.CRYO)
            arena.add_child(obs)
            _obstacles.append(obs)

    elif map_id == "toxic":
        # Toxic Citadel: Heavy Biohazard Containment Silos
        for pos in [
            Vector2(700, 550), Vector2(1250, 550), Vector2(2150, 550), Vector2(2700, 550),
            Vector2(750, 1100), Vector2(1300, 900), Vector2(2100, 1300), Vector2(2650, 1100),
            Vector2(700, 1650), Vector2(1250, 1650), Vector2(1700, 1700), Vector2(2150, 1650), Vector2(2700, 1650),
            Vector2(1700, 500)
        ]:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.TOXIC_SILO)
            arena.add_child(obs)
            _obstacles.append(obs)

    else:
        # Cyber Matrix: Quantum Pillars & Tactical Barricades
        var pillar_coords: Array[Vector2] = [
            Vector2(650, 550), Vector2(1700, 480), Vector2(2750, 550),
            Vector2(850, 1100), Vector2(2550, 1100),
            Vector2(650, 1650), Vector2(1700, 1720), Vector2(2750, 1650),
            Vector2(1200, 800), Vector2(2200, 800),
            Vector2(1200, 1400), Vector2(2200, 1400)
        ]
        for pos in pillar_coords:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.PILLAR)
            arena.add_child(obs)
            _obstacles.append(obs)

        var barrier_coords: Array[Vector2] = [
            Vector2(1100, 550), Vector2(2300, 550),
            Vector2(650, 1100), Vector2(2750, 1100),
            Vector2(1100, 1650), Vector2(2300, 1650)
        ]
        for pos in barrier_coords:
            var obs := obstacle_scene.instantiate() as Obstacle
            obs.position = pos
            obs.position *= 2.0
            obs._bounds = current_arena_rect.grow(-140)
            obs.set_type(Obstacle.Type.BARRIER)
            arena.add_child(obs)
            _obstacles.append(obs)


# Environmental Hazard: Meteor Shower Strike
func _trigger_meteor_shower() -> void:
    if not Game.is_running or player == null or not is_instance_valid(player):
        return

    # Target 2-3 impact zones around player vicinity
    var count := randi_range(2, 3)
    for i in count:
        var offset := Vector2(randf_range(-650, 650), randf_range(-450, 450))
        var impact_pos: Vector2 = player.global_position + offset
        impact_pos.x = clampf(impact_pos.x, 150.0, ARENA_WIDTH - 150.0)
        impact_pos.y = clampf(impact_pos.y, 150.0, ARENA_HEIGHT - 150.0)
        _spawn_meteor_strike(impact_pos, randf_range(0.0, 0.8))


func _spawn_meteor_strike(pos: Vector2, delay: float) -> void:
    var generation := _mission_generation
    await get_tree().create_timer(delay, false).timeout
    if generation != _mission_generation: return
    if not Game.is_running:
        return

    # 1. Warning Ground Telegraph Circle
    var warning := Node2D.new()
    warning.add_to_group("mission_hazards")
    warning.position = pos
    arena.add_child(warning)

    var ring := ColorRect.new()
    ring.size = Vector2(160, 160)
    ring.position = Vector2(-80, -80)
    ring.color = Color(1.0, 0.2, 0.1, 0.35)
    warning.add_child(ring)

    var tw_warn := warning.create_tween()
    tw_warn.tween_property(ring, "scale", Vector2(1.2, 1.2), 0.35).from(Vector2(0.3, 0.3))
    tw_warn.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.35)
    tw_warn.tween_property(ring, "modulate:a", 0.9, 0.4)

    # 2. Incoming Meteor Fireball
    await get_tree().create_timer(1.1, false).timeout
    if generation != _mission_generation: return
    if not Game.is_running:
        warning.queue_free()
        return

    var meteor := Sprite2D.new()
    meteor.add_to_group("mission_hazards")
    meteor.texture = preload("res://assets/hazard_meteor.svg")
    meteor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    meteor.scale = Vector2(0.4, 0.4)
    meteor.position = pos + Vector2(-350, -600)
    meteor.rotation = deg_to_rad(45.0)
    arena.add_child(meteor)

    var tw_meteor := meteor.create_tween()
    tw_meteor.tween_property(meteor, "position", pos, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

    await tw_meteor.finished
    if generation != _mission_generation or not Game.is_running: return

    # 3. Ground Impact Explosion
    warning.queue_free()
    meteor.queue_free()

    Game.request_screen_shake(14.0)
    if SoundEffects:
        SoundEffects.play_explosion()

    # Explosion Blast Shockwave
    var blast := ColorRect.new()
    blast.add_to_group("mission_hazards")
    blast.size = Vector2(220, 220)
    blast.position = pos - Vector2(110, 110)
    blast.color = Color(1.0, 0.6, 0.1, 0.8)
    arena.add_child(blast)

    var tw_blast := blast.create_tween()
    tw_blast.tween_property(blast, "scale", Vector2(1.6, 1.6), 0.25).from(Vector2(0.5, 0.5))
    tw_blast.parallel().tween_property(blast, "modulate:a", 0.0, 0.25)
    tw_blast.tween_callback(blast.queue_free)

    # Area of Effect Damage
    var blast_radius := 130.0

    # Damage/Kill enemies caught in blast
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy is Node2D and is_instance_valid(enemy):
            if enemy.global_position.distance_to(pos) <= blast_radius:
                enemy.kill()
                Game.add_score(50)

    # Damage player if caught in blast
    if player and is_instance_valid(player):
        if player.global_position.distance_to(pos) <= blast_radius * 0.85:
            Game.take_damage()


func _clear_entities() -> void:
    for shot in get_tree().get_nodes_in_group("enemy_shots"):
        shot.despawn()
    for hazard in get_tree().get_nodes_in_group("mission_hazards"):
        hazard.queue_free()
    for node in get_tree().get_nodes_in_group("enemies"):
        node.queue_free()
    for node in get_tree().get_nodes_in_group("bullets"):
        node.despawn()
    for node in get_tree().get_nodes_in_group("pickups"):
        node.queue_free()

func _extend_obstacles() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7439 + Campaign.index(Game.selected_map_id)
    var types := {"cyber": Obstacle.Type.BARRIER, "forest": Obstacle.Type.ANCIENT_TREE, "space": Obstacle.Type.ASTEROID, "coast": Obstacle.Type.CARGO, "desert": Obstacle.Type.CARGO, "volcano": Obstacle.Type.BASALT, "glacier": Obstacle.Type.CRYO, "toxic": Obstacle.Type.TOXIC_SILO}
    var scene: PackedScene = load("res://scenes/obstacle.tscn")
    for i in 36:
        var pos := Vector2.ZERO
        var safe := false
        for attempt in 30:
            pos = Vector2(rng.randf_range(240, ARENA_WIDTH - 240), rng.randf_range(240, ARENA_HEIGHT - 240))
            if i < 8:
                pos = current_arena_rect.get_center() + Vector2.from_angle(i * TAU / 8) * 720
            safe = pos.distance_to(current_arena_rect.get_center()) > 400
            for existing in _obstacles:
                if pos.distance_to(existing.position) < 300: safe = false
            if safe: break
        if not safe: continue
        var obstacle := scene.instantiate() as Obstacle
        obstacle.position = pos
        obstacle._bounds = current_arena_rect.grow(-140)
        obstacle.set_type(types[Game.selected_map_id])
        arena.add_child(obstacle)
        _obstacles.append(obstacle)
