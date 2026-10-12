extends Node
func _ready() -> void: call_deferred("run")
func run() -> void:
 Game.save_path="res://qa/control-position-save.cfg"
 Game._load_save()
 var valid: bool=Game.control_layout.joystick.position.distance_to(Vector2(.31,.36))<.01 and not Game.control_layout.joystick.fixed
 var scene: Node2D=load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene);get_tree().current_scene=scene
 for frame in 4: await get_tree().process_frame
 var joy: GameJoystick=scene.hud.joystick
 valid=valid and not joy.fixed_control and joy._default_pos.is_equal_approx(TouchLayout.resolved(Game.control_layout,get_viewport().get_visible_rect().size).joystick.center)
 scene.free();Game.is_running=false;SoundEffects.stop_all()
 await get_tree().create_timer(.2).timeout
 print("CONTROL POSITION FRESH START: ","PASS" if valid else "FAIL")
 get_tree().quit(0 if valid else 1)
