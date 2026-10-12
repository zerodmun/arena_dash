class_name LevelSelect
extends Control
## A winding, numbered constellation route inspired by the supplied reference.
const POINTS := [Vector2(1580,650), Vector2(1730,300), Vector2(1310,410), Vector2(970,640), Vector2(565,410), Vector2(915,185), Vector2(1365,115), Vector2(430,125)]
var cards: Dictionary = {}
var _page := 0
var _page_back: Button
var _page_next: Button
var _markers: Array[Label] = []
var _ratings: Array[HBoxContainer] = []
var _names: Array[Label] = []
var _centers: Array[Vector2] = []
var _selected := "cyber"
var _scene_scale := 1.0
var _time := 0.0
var _briefing: PanelContainer
var _title: Label
var _detail: Label
var _deploy: Button
var _back: Button
var _settings: Button
var _heading: Label
var _rocket: TextureRect
func _ready() -> void:
 SoundEffects.enter_screen("campaign")
 Game.is_running = false
 _selected = Game.selected_map_id if Game.is_level_unlocked(Game.selected_map_id) else "cyber"
 var background := ArcadeUI.image("res://assets/ui/theme/space_landscape.svg", Vector2.ZERO)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 add_child(background)
 # Adapted existing horizon artwork leaves navigation entirely interactive.
 var veil := ColorRect.new()
 veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 veil.color = Color(.03,.06,.12,.18)
 veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(veil)
 var route := Control.new()
 route.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 route.mouse_filter = Control.MOUSE_FILTER_IGNORE
 route.draw.connect(func() -> void: _draw_route(route))
 add_child(route)
 _back = ArcadeUI.button("HANGAR", "button_back")
 _back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/hangar.tscn"))
 add_child(_back)
 _heading = ArcadeUI.label("PLANET CAMPAIGN", 32, Color("e1eaff"))
 _heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 add_child(_heading)
 _settings = ArcadeUI.button("", "button_settings")
 _settings.pressed.connect(func() -> void: ArcadeUI.settings(self))
 add_child(_settings)
 _page_back=ArcadeUI.button("‹", "button_back")
 _page_next=ArcadeUI.button("›", "button_play")
 _page_back.pressed.connect(func() -> void: _select(Campaign.ORDER[0]))
 _page_next.pressed.connect(func() -> void: _select(Campaign.ORDER[8]))
 add_child(_page_back)
 add_child(_page_next)
 _rocket = ArcadeUI.image("res://assets/future_updates/aircraft/player_rocket.svg", Vector2.ZERO)
 _rocket.rotation = -0.6
 add_child(_rocket)
 for i in Campaign.ORDER.size():
  var id: String = Campaign.ORDER[i]
  var planet := PlanetButton.new()
  planet.planet_id = id
  # Locked nodes can be inspected; deployment remains guarded by Game.select_level.
  planet.pressed.connect(func() -> void: _select(id))
  add_child(planet)
  cards[id] = planet
  var marker := ArcadeUI.label(str(i + 1), 18, ArcadeUI.GOLD if Game.is_level_unlocked(id) else Color("acc0e9"))
  marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  add_child(marker)
  _markers.append(marker)
  var stars := HBoxContainer.new()
  stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stars.alignment = BoxContainer.ALIGNMENT_CENTER
  stars.add_theme_constant_override("separation", 0)
  add_child(stars)
  _ratings.append(stars)
  for star in 3:
   stars.add_child(ArcadeUI.image(ArcadeUI.KIT + ("badge_star_active.svg" if star < int(Game.completed_levels.get(id, 0)) else "badge_star_inactive.svg"), Vector2(26,26)))
  var name_label := ArcadeUI.label(Game.MAPS[id].name, 16, Color("c5d7ff"))
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  add_child(name_label)
  _names.append(name_label)
 _briefing = PanelContainer.new()
 _briefing.add_theme_stylebox_override("panel", ArcadeUI.panel())
 add_child(_briefing)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 20)
 _briefing.add_child(row)
 var info := VBoxContainer.new()
 info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(info)
 _title = ArcadeUI.label("", 24, ArcadeUI.GOLD)
 info.add_child(_title)
 _detail = ArcadeUI.label("", 16, Color("c1ceeb"))
 _detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 info.add_child(_detail)
 _deploy = ArcadeUI.button("PREPARE FLIGHT", "button_play",true)
 _deploy.custom_minimum_size.x = 240
 _deploy.pressed.connect(func() -> void:
  if Game.select_level(_selected): get_tree().change_scene_to_file("res://scenes/hangar.tscn"))
 row.add_child(_deploy)
 I18n.changed.connect(func() -> void: _layout(); _select(_selected))
 resized.connect(_layout)
 _layout()
 _select(_selected)
 # A short fade introduces the map; reduced-motion users get the static view.
 if not Game.reduced_motion:
  modulate.a = 0.0
  create_tween().tween_property(self,"modulate:a",1.0,0.28)
func _select(id: String) -> void:
 SoundEffects.play("select" if Game.is_level_unlocked(id) else "locked")
 _selected = id
 var page:=Campaign.index(id)/8
 if _page!=page:
  _page=page
  _layout()
 var unlocked := Game.is_level_unlocked(id)
 var i := Campaign.index(id)
 var status := "LOCKED" if not unlocked else ("THREE-STAR CLEAR" if Game.is_level_cleared(id) else ("RETRY FOR 3 STARS" if Game.best_stars(id)>0 else "READY"))
 _title.text = "%02d  /  %s  /  %s" % [i+1, I18n.t(Game.MAPS[id].name),I18n.t(status)]
 _detail.text = I18n.t("%s  •  %d drones%s\n%s",[I18n.t(Campaign.DIFFICULTY[i]),Campaign.target(id),I18n.t(" + guardian") if Campaign.has_boss(id) else "",I18n.t(Campaign.challenge(id)) if unlocked else I18n.t("Earn 3 stars on %s to unlock this orbit.",[I18n.t(Game.MAPS[Campaign.ORDER[i-1]].name)])])
 _detail.text+="\n"+I18n.t("3 stars: at most %d damage  •  within %d s",[Campaign.damage_budget(Game.selected_ship_id),int(Campaign.par_time(id))])
 _deploy.disabled = not unlocked
 for key: String in cards:
  cards[key].selected = key == id
  cards[key].modulate = Color.WHITE if Game.is_level_unlocked(key) else Color(0.68,0.70,0.83)
func _layout(available := Rect2()) -> void:
 if not _briefing: return
 var safe:=available if available.has_area() else ArcadeUI.safe_rect(get_viewport_rect().size)
 var vp := safe.size
 _back.position = Vector2(24,18); _back.size = Vector2(170,58)
 _settings.position = Vector2(vp.x-84,18); _settings.size = Vector2(60,58)
 _heading.position = Vector2(210,20); _heading.size = Vector2(vp.x-420,54)
 _scene_scale = minf(vp.x / 1920.0, (vp.y-270) / 810.0)
 var origin := safe.position+Vector2((vp.x-1920*_scene_scale)*0.5, 95)
 _page_back.position=safe.position+Vector2(vp.x*0.5-230,20)
 _page_next.position=safe.position+Vector2(vp.x*0.5+170,20)
 _page_back.size=Vector2(60,54)
 _page_next.size=Vector2(60,54)
 _page_back.disabled=_page==0
 _page_next.disabled=_page==1
 _heading.text=I18n.t("PLANET CAMPAIGN")+"  %d / 2" % (_page+1)
 _heading.add_theme_font_size_override("font_size",22)
 _centers.clear()
 for i in Campaign.ORDER.size():
  var visible_on_page:=i/8==_page
  cards[Campaign.ORDER[i]].visible=visible_on_page
  _markers[i].visible=visible_on_page
  _ratings[i].visible=visible_on_page
  _names[i].visible=visible_on_page
  _names[i].text=I18n.t(Game.MAPS[Campaign.ORDER[i]].name)
  if not visible_on_page:continue
  var center: Vector2 = origin + POINTS[i%8]*_scene_scale
  _centers.append(center)
  var diameter := 172*_scene_scale
  cards[Campaign.ORDER[i]].position = center-Vector2.ONE*diameter*0.5
  cards[Campaign.ORDER[i]].size = Vector2.ONE*diameter
  _markers[i].position = center+Vector2(-18,-diameter*0.5-23)
  _markers[i].size = Vector2(36,26)
  _ratings[i].position = center+Vector2(-48,diameter*0.46)
  _ratings[i].size = Vector2(96,28)
  _names[i].position = center+Vector2(-110,diameter*0.46+28)
  _names[i].size = Vector2(220,24)
  _names[i].add_theme_font_size_override("font_size",14 if _scene_scale < 0.8 else 16)
 _rocket.position = Vector2(vp.x*0.12,vp.y*0.45)
 _rocket.size = Vector2(100,130)*_scene_scale
 _rocket.visible = true
 _briefing.position = Vector2(24,vp.y-158)
 _briefing.size = Vector2(vp.x-48,134)
 for control in [_back,_settings,_heading,_rocket,_briefing]: control.position+=safe.position
 _title.add_theme_font_size_override("font_size",18 if vp.x<1400 else 24)
 _deploy.custom_minimum_size.x = 180 if vp.x<1400 else 240
func _process(delta: float) -> void:
 if Game.reduced_motion: return
 _time += delta
 get_child(2).queue_redraw()
func _draw_route(canvas: Control) -> void:
 if _centers.size()<2: return
 # Low-alpha nebula lighting adds blue/purple depth without new bitmap assets.
 var safe:=ArcadeUI.safe_rect(get_viewport_rect().size)
 var vp := safe.size
 for i in 10:
  canvas.draw_circle(vp*Vector2(0.54,0.47),vp.x*(0.22+i*0.013),Color(.17,.2,.32,.01))
 for i in _centers.size()-1:
  var a := _centers[i]
  var b := _centers[i+1]
  var control_a := a + Vector2((b.x-a.x)*0.7,0)
  var control_b := b - Vector2((b.x-a.x)*0.3,(b.y-a.y)*0.2)
  var count := maxi(18,int(a.distance_to(b)/12))
  for dot in count:
   var t := float(dot)/count
   var point := a.bezier_interpolate(control_a,control_b,b,t)
   var clear := true
   for center in _centers:
    if center.distance_to(point)<cards.cyber.size.x*0.54: clear=false
   if clear:
    var col := Color("79eaff") if Game.is_level_cleared(Campaign.ORDER[_page*8+i]) else Color("f4d578")
    if not Game.is_level_unlocked(Campaign.ORDER[_page*8+i]): col=Color("8b90cf")
    canvas.draw_circle(point,1.8+sin(_time*1.5+t*8)*0.25,col)
 for i in _centers.size():
  canvas.draw_circle(_centers[i]+Vector2(0,-cards.cyber.size.y*0.5-10),15,Color("102456"))
  canvas.draw_arc(_centers[i]+Vector2(0,-cards.cyber.size.y*0.5-10),15,0,TAU,24,Color("77cfff"),1.5,true)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE:
   SoundEffects.play("back")
   get_tree().change_scene_to_file("res://scenes/hangar.tscn")
  elif event.keycode in [KEY_LEFT,KEY_RIGHT]:
   _select(Campaign.ORDER[wrapi(Campaign.index(_selected)+(1 if event.keycode==KEY_RIGHT else -1),0,Campaign.ORDER.size())])
  elif event.keycode == KEY_ENTER:
   if Game.select_level(_selected):
    SoundEffects.play("confirm")
    get_tree().change_scene_to_file("res://scenes/hangar.tscn")
   else: SoundEffects.play("locked")
