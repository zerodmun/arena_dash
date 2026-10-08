class_name Player
extends CharacterBody2D
## Player: semi-3D HD aircraft with aerodynamic banking, customizable ships,
## thruster effects, and multi-weapon firing patterns.

var base_scale := 0.28

@export var bullet_scene: PackedScene
@export var speed := 360.0
@export var fire_rate := 0.18
@export var invuln_time := 1.2

var last_aim := Vector2.UP

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Node2D = $ShootPoint
@onready var hurtbox: Area2D = $Hurtbox
@onready var thrusters: CPUParticles2D = $ThrusterTrail

var _fire_cd := 0.0
var _invuln := 0.0
var _roll_tilt := 0.0


func _ready() -> void:
	add_to_group("player")
	Game.game_started.connect(_reset_flight)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	Game.ship_selected.connect(func(_id: String) -> void: apply_customization())
	Game.weapon_selected.connect(func(_id: String) -> void: apply_customization())
	apply_customization()


func apply_customization() -> void:
	var ship := Game.get_current_ship()
	speed = float(ship.get("speed", 360.0))
	fire_rate = float(ship.get("fire_rate", 0.18))
	
	if sprite:
		var tex_path: String = ship.get("texture", "res://assets/player.svg")
		sprite.texture = load(tex_path)
		var ship_id: String = ship.get("id", "valkyrie")
		if ship_id == "titan":
			base_scale = 0.30
			sprite.scale = Vector2(0.30, 0.30)
		elif ship_id == "phantom":
			base_scale = 0.26
			sprite.scale = Vector2(0.26, 0.26)
		else:
			base_scale = 0.28
			sprite.scale = Vector2(0.28, 0.28)

	if thrusters:
		var ship_color: Color = ship.get("color", Color(0.22, 0.74, 1.0))
		var grad := Gradient.new()
		grad.set_color(0, ship_color)
		grad.set_color(1, Color(ship_color.r, ship_color.g, ship_color.b, 0.0))
		thrusters.color_ramp = grad


func _reset_flight() -> void:
	velocity = Vector2.ZERO
	last_aim = Vector2.UP
	rotation = 0.0
	_invuln = invuln_time
	_fire_cd = 0.25

func _physics_process(delta: float) -> void:
	if not Game.is_running:
		velocity = Vector2.ZERO
		return
	var dir := _get_input_direction()
	velocity = dir * speed
	move_and_slide()

	if dir.length_squared() > 0.01:
		last_aim = dir
		if thrusters:
			thrusters.emitting = true
	else:
		if thrusters:
			thrusters.emitting = false

	# Smooth rotation toward heading
	var target_rot := last_aim.angle() + PI / 2.0
	rotation = rotate_toward(rotation, target_rot, 16.0 * delta)

	# Semi-3D roll/banking: tilt sideways when steering
	var angular_diff := wrapf(target_rot - rotation, -PI, PI)
	_roll_tilt = lerpf(_roll_tilt, clampf(angular_diff * 1.5, -0.3, 0.3), 12.0 * delta)
	sprite.scale.x = base_scale * (1.0 - absf(_roll_tilt) * 0.35)
	sprite.skew = -_roll_tilt * 0.3

	_update_invulnerability(delta)

	_fire_cd -= delta
	if Game.is_running and Input.is_action_pressed("fire") and _fire_cd <= 0.0:
		_shoot()
		_fire_cd = fire_rate


func _get_input_direction() -> Vector2:
	var joystick := get_tree().get_first_node_in_group("joystick")
	if joystick != null and joystick.pressed:
		return joystick.output
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _shoot() -> void:
	if bullet_scene == null:
		return
	var weapon := Game.get_current_weapon()
	var pattern: String = weapon.get("pattern", "single")
	var root := get_tree().current_scene

	var aim_norm := last_aim.normalized()
	var perp := Vector2(-aim_norm.y, aim_norm.x)

	if pattern == "twin":
		# Dual parallel wing beams
		_spawn_bullet(shoot_point.global_position + perp * 26.0, aim_norm, "twin_laser", root)
		_spawn_bullet(shoot_point.global_position - perp * 26.0, aim_norm, "twin_laser", root)
	elif pattern == "spread":
		# 3-way spread shot
		_spawn_bullet(shoot_point.global_position, aim_norm.rotated(-deg_to_rad(18.0)), "quantum_spread", root)
		_spawn_bullet(shoot_point.global_position, aim_norm, "quantum_spread", root)
		_spawn_bullet(shoot_point.global_position, aim_norm.rotated(deg_to_rad(18.0)), "quantum_spread", root)
	else:
		# Single concentrated plasma bolt
		_spawn_bullet(shoot_point.global_position, aim_norm, Game.selected_weapon_id, root)

	if SoundEffects:
		SoundEffects.play_shoot()

	# Muzzle recoil punch
	var punch := create_tween()
	punch.tween_property(sprite, "scale", Vector2(base_scale * 1.18, base_scale * 0.85), 0.05)
	punch.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.08)


func _spawn_bullet(pos: Vector2, dir: Vector2, w_id: String, parent: Node) -> void:
	var bullet := bullet_scene.instantiate() as Bullet
	bullet.global_position = pos
	parent.add_child(bullet)
	bullet.setup(dir, w_id)


func _update_invulnerability(delta: float) -> void:
	if _invuln > 0.0:
		_invuln -= delta
		sprite.visible = int(_invuln * 16.0) % 2 == 0
		modulate = Color(1.5, 1.5, 2.0, 0.85)
	else:
		sprite.visible = true
		modulate = Color.WHITE


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if _invuln > 0.0 or not Game.is_running:
		return
	var enemy := body as Enemy
	if enemy == null:
		return
	Game.take_damage()
	_invuln = invuln_time
	enemy.kill()
