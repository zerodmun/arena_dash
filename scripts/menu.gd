extends Control
var _coins: Label
var _catalog_summary: Label
var _hero: TextureRect
var _identity: VBoxContainer
var _actions: PanelContainer
var _background: TextureRect
var _hero_base := Vector2.ZERO
var _time := 0.0
var _active := true
func _ready() -> void:
 SoundEffects.enter_screen("menu")
 Game.is_running=false
 var bg:=ArcadeUI.image("res://assets/ui/theme/space_landscape.svg",Vector2.ZERO)
 _background=bg
 bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 bg.size=get_viewport_rect().size
 bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 add_child(bg)
 _hero=ArcadeUI.image(Game.get_current_ship().texture,Vector2.ZERO)
 Game.ship_selected.connect(_refresh_aircraft)
 add_child(_hero)
 _identity=VBoxContainer.new()
 var title:=ArcadeUI.label("ARENA DASH",58,ArcadeUI.CYAN)
 title.add_theme_color_override("font_shadow_color",Color("182437"))
 title.add_theme_constant_override("shadow_offset_y",2)
 title.add_theme_constant_override("outline_size",3)
 title.add_theme_color_override("font_outline_color",Color("263e55"))
 _identity.add_child(title)
 _identity.add_child(ArcadeUI.label("FLIGHT COMMAND  /  CAMPAIGN OPERATIONS",18,ArcadeUI.CYAN))
 var coin_row:=HBoxContainer.new()
 coin_row.add_theme_constant_override("separation",12)
 coin_row.add_child(ArcadeUI.image("res://assets/ui/icons/icon_coin.svg",Vector2(28,28)))
 _coins=ArcadeUI.label("",20,ArcadeUI.GOLD)
 coin_row.add_child(_coins)
 _identity.add_child(coin_row)
 Game.economy_changed.connect(_refresh_coins)
 I18n.changed.connect(_refresh_coins)
 _refresh_coins()
 add_child(_identity)
 _actions=PanelContainer.new()
 _actions.add_theme_stylebox_override("panel",ArcadeUI.panel(28))
 add_child(_actions)
 var box:=VBoxContainer.new()
 box.add_theme_constant_override("separation",18)
 _actions.add_child(box)
 box.add_child(ArcadeUI.label("READY FOR TAKEOFF",28,ArcadeUI.GOLD))
 _catalog_summary=ArcadeUI.label("",20,ArcadeUI.MUTED)
 box.add_child(_catalog_summary)
 I18n.changed.connect(_refresh_catalog_summary)
 _refresh_catalog_summary()
 for item in [["ENTER HANGAR","button_play","res://scenes/hangar.tscn"],["PLANET CAMPAIGN","button_menu","res://scenes/level_select.tscn"]]:
  var btn:=ArcadeUI.button(item[0],item[1],item[0]=="ENTER HANGAR")
  btn.pressed.connect(func() -> void: Navigation.go_to(item[2]))
  box.add_child(btn)
 var settings:=ArcadeUI.button("SETTINGS","button_settings")
 settings.pressed.connect(func() -> void: ArcadeUI.settings(self))
 box.add_child(settings)
 resized.connect(_layout)
 _layout()
func _layout(available := Rect2()) -> void:
 var safe:=available if available.has_area() else ArcadeUI.safe_rect(get_viewport_rect().size)
 var vp:=safe.size
 _identity.position=safe.position+Vector2(48,48)
 var extent:=Vector2(vp.x*0.48,vp.y-230)
 var display_scale:=clampf(float(Game.get_current_ship().visual_scale)/0.28,0.85,1.12)
 _hero.size=extent*display_scale
 _hero_base=safe.position+Vector2(65,170)+(extent-_hero.size)*0.5
 _hero.position=_hero_base
 _actions.position=safe.position+Vector2(vp.x*0.57,vp.y*0.5-220)
 _actions.size=Vector2(vp.x*0.43-48,440)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ENTER and not has_node("FlightDialog"):
  SoundEffects.play("confirm")
  Navigation.go_to("res://scenes/hangar.tscn")

func _refresh_coins() -> void:
 _coins.text=I18n.t("Coins: %d",[Game.coins])

func _refresh_catalog_summary() -> void:
 _catalog_summary.text=I18n.t("%d aircraft • %d worlds\nChoose your craft. Secure every orbit.",[Game.SHIPS.size(),Campaign.ORDER.size()])

func _refresh_aircraft(_id: String) -> void:
 _hero.texture=load(Game.get_current_ship().texture)
 _layout()

func _process(delta: float) -> void:
 if not _active or not is_visible_in_tree():return
 if Game.reduced_motion:
  _hero.position=_hero_base
  _background.position=Vector2.ZERO
  _background.size=size
  return
 _time=fmod(_time+delta,TAU*100.0)
 # Overscan keeps the original artwork covering the screen at every loop phase.
 _background.size=size+Vector2(32,24)
 _background.position=Vector2(-16+sin(_time*0.10)*10,-12+cos(_time*0.10)*7)
 _hero.position=_hero_base+Vector2(sin(_time*0.5)*4,sin(_time*0.8)*7)

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED:_active=false
 elif what==NOTIFICATION_APPLICATION_RESUMED:_active=true
