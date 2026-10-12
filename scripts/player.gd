class_name Player
extends CharacterBody2D
## Player: semi-3D HD aircraft with aerodynamic banking, customizable ships,
## thruster effects, and multi-weapon firing patterns.

var base_scale := 0.28

@export var speed := 360.0
@export var fire_rate := 0.18
@export var invuln_time := 1.2

var last_aim := Vector2.UP

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Node2D = $ShootPoint
@onready var hurtbox: Area2D = $Hurtbox
@onready var thrusters: CPUParticles2D = $ThrusterTrail

var weapon_controller: WeaponController
var _invuln := 0.0
var _roll_tilt := 0.0
var _joystick: GameJoystick
var _recoil: Tween


func _ready() -> void:
    weapon_controller=WeaponController.new(self)
    add_to_group("player")
    Game.game_started.connect(_reset_flight)
    hurtbox.body_entered.connect(_on_hurtbox_body_entered)
    Game.ship_selected.connect(func(_id: String) -> void: apply_customization())
    Game.weapon_selected.connect(func(_id: String) -> void: apply_customization())
    apply_customization()


func apply_customization() -> void:
    var ship := Game.get_current_ship()
    speed = float(ship.get("speed", 360.0))
    fire_rate = EquipmentCatalog.firing_interval(ship, Game.get_current_weapon())
    
    if sprite:
        var tex_path: String = ship.get("texture", "res://assets/player.svg")
        sprite.texture = load(tex_path)
        base_scale = float(ship.visual_scale)
        sprite.scale = Vector2.ONE * base_scale
    # Each instance owns its shapes; customization cannot resize another actor.
    var collision := CircleShape2D.new()
    collision.radius = float(ship.collision_radius)
    $CollisionShape2D.shape = collision
    $Hurtbox/CollisionShape2D.shape = collision
    shoot_point.position = ship.muzzle
    if thrusters: thrusters.position = ship.thruster

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
    weapon_controller.reset()

func _physics_process(delta: float) -> void:
    if not Game.is_running:
        velocity = Vector2.ZERO
        return
    PerfDiagnostics.consume_input()
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
    _roll_tilt = lerpf(_roll_tilt, clampf(angular_diff * 1.5, -0.3, 0.3), 1.0-exp(-12.0*delta))
    sprite.scale.x = base_scale * (1.0 - absf(_roll_tilt) * 0.35)
    sprite.skew = -_roll_tilt * 0.3

    _update_invulnerability(delta)

    if weapon_controller.tick(delta, Input.is_action_pressed("fire")):
        _shot_feedback()

func _get_input_direction() -> Vector2:
    if not is_instance_valid(_joystick):_joystick=get_tree().get_first_node_in_group("joystick") as GameJoystick
    if _joystick != null and _joystick.pressed:
        return _joystick.output
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _shoot() -> void:
    # Explicit immediate request used by controlled development scenarios.
    if weapon_controller.request_fire()>0:_shot_feedback()

func _shot_feedback() -> void:
    SoundEffects.play_shoot()

    # Muzzle recoil punch
    if _recoil and _recoil.is_running():_recoil.kill()
    var punch := create_tween()
    _recoil=punch
    punch.tween_property(sprite, "scale", Vector2(base_scale * 1.18, base_scale * 0.85), 0.05)
    punch.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.08)


func _update_invulnerability(delta: float) -> void:
    if _invuln > 0.0:
        _invuln -= delta
        sprite.visible = true if OS.is_debug_build() and OS.has_feature("arena_review") and _invuln > 10.0 else int(_invuln * 16.0) % 2 == 0
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
    receive_hit(1)
    if not enemy.is_boss: enemy.kill()

func receive_hit(damage: int = 1) -> void:
    if _invuln > 0 or not Game.is_running: return
    Game.take_damage(damage)
    _invuln = invuln_time
