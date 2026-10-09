extends Control
var _hero: TextureRect
var _identity: VBoxContainer
var _actions: PanelContainer
func _ready() -> void:
 Game.is_running=false
 var bg:=ArcadeUI.image("res://assets/generated/campaign_horizon.svg",Vector2.ZERO)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 add_child(bg)
 _hero=ArcadeUI.image("res://assets/future_updates/aircraft/player_booster.svg",Vector2.ZERO)
 add_child(_hero)
 _identity=VBoxContainer.new()
 _identity.add_child(ArcadeUI.label("ARENA DASH",48,ArcadeUI.GOLD))
 _identity.add_child(ArcadeUI.label("FLIGHT COMMAND  /  CAMPAIGN OPERATIONS",18,ArcadeUI.CYAN))
 add_child(_identity)
 _actions=PanelContainer.new()
 _actions.add_theme_stylebox_override("panel",ArcadeUI.surface(28))
 add_child(_actions)
 var box:=VBoxContainer.new()
 box.add_theme_constant_override("separation",18)
 _actions.add_child(box)
 box.add_child(ArcadeUI.label("READY FOR TAKEOFF",28,ArcadeUI.GOLD))
 box.add_child(ArcadeUI.label("12 aircraft • 8 worlds\nChoose your craft. Secure every orbit.",20,ArcadeUI.MUTED))
 for item in [["ENTER HANGAR","button_play","res://scenes/hangar.tscn"],["PLANET CAMPAIGN","button_menu","res://scenes/level_select.tscn"]]:
  var btn:=ArcadeUI.button(item[0],item[1],item[0]=="ENTER HANGAR")
  btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(item[2]))
  box.add_child(btn)
 var settings:=ArcadeUI.button("SETTINGS","button_settings")
 settings.pressed.connect(func() -> void: ArcadeUI.settings(self))
 box.add_child(settings)
 resized.connect(_layout)
 _layout()
func _layout() -> void:
 var vp:=get_viewport_rect().size
 _identity.position=Vector2(48,48)
 _hero.position=Vector2(65,170)
 _hero.size=Vector2(vp.x*0.48,vp.y-230)
 _actions.position=Vector2(vp.x*0.57,vp.y*0.5-220)
 _actions.size=Vector2(vp.x*0.43-48,440)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ENTER and not has_node("FlightDialog"):
  get_tree().change_scene_to_file("res://scenes/hangar.tscn")
