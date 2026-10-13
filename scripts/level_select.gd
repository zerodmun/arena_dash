class_name LevelSelect
extends Control
## One bounded constellation world. HUD stays fixed while world content pans.
const WORLD_SIZE := Vector2(2420, 1780)
const POINTS := [Vector2(240,300), Vector2(650,240), Vector2(1040,420), Vector2(1460,250), Vector2(1950,360), Vector2(2130,760), Vector2(1680,850), Vector2(1250,740), Vector2(800,870), Vector2(300,790), Vector2(250,1280), Vector2(750,1370), Vector2(1220,1190), Vector2(1720,1390), Vector2(2170,1260)]
const DRAG_THRESHOLD := 12.0
@export_range(0.1, 1.0, 0.05) var minimum_zoom := 0.5
@export_range(1.0, 3.0, 0.1) var maximum_zoom := 2.0
var _fit_zoom_cache := 0.25
var _world_bounds := Rect2(Vector2.ZERO,WORLD_SIZE)
var _locks: Array[TextureRect] = []
var _base_scale := 1.0
var _zoom := 1.0
var _zoom_target := 1.0
var _zoom_anchor := Vector2.ZERO
var _touches: Dictionary = {}
var _pinch_ids: Array[int] = []
var _pinch_distance := 0.0
var _pinch_midpoint := Vector2.ZERO
var _gesture_was_pinch := false
var _zoom_in: Button
var _zoom_out: Button
var _zoom_fit: Button
var _zoom_readout: Label
var _zoom_dirty := false
var cards: Dictionary = {}
var _map_view: Control
var _world: Control
var _route: Control
var _offset := Vector2.ZERO
var _velocity := Vector2.ZERO
var _pointer := -2
var _press_position := Vector2.ZERO
var _last_position := Vector2.ZERO
var _dragging := false
var _focus_tween: Tween
var _next_label: Label
var _markers: Array[Label] = []
var _ratings: Array[HBoxContainer] = []
var _names: Array[Label] = []
var _centers: Array[Vector2] = []
var _selected := "cyber"
var _scene_scale := 1.0
var _briefing: PanelContainer
var _title: Label
var _detail: Label
var _deploy: Button
var _back: Button
var _settings: Button
var _hint: Label
var _last_motion_ms := 0
var _heading: Label
func _ready() -> void:
 SoundEffects.enter_screen("campaign")
 Game.is_running = false
 _selected = Game.latest_unlocked_planet()
 _zoom = Game.map_zoom
 _zoom_target = _zoom
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
 _map_view = Control.new()
 _map_view.clip_contents = true
 _map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(_map_view)
 _world = Control.new()
 _world.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _map_view.add_child(_world)
 _route = Control.new()
 _route.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _route.draw.connect(func() -> void: _draw_route(_route))
 _world.add_child(_route)
 _back = ArcadeUI.button("HANGAR", "button_back")
 _back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/hangar.tscn"))
 add_child(_back)
 _heading = ArcadeUI.label("PLANET CAMPAIGN", 32, Color("e1eaff"))
 _heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 add_child(_heading)
 _hint = ArcadeUI.label("", 14, Color("c1ceeb"))
 _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 add_child(_hint)
 _settings = ArcadeUI.button("", "button_settings")
 _settings.pressed.connect(func() -> void:
  _cancel_gesture()
  ArcadeUI.settings(self))
 add_child(_settings)
 _zoom_out = ArcadeUI.button("−")
 _zoom_in = ArcadeUI.button("+")
 _zoom_fit = ArcadeUI.button("FIT")
 _zoom_out.pressed.connect(func() -> void: _request_zoom(_zoom_target / 1.25, _map_view.get_global_rect().get_center()))
 _zoom_in.pressed.connect(func() -> void: _request_zoom(_zoom_target * 1.25, _map_view.get_global_rect().get_center()))
 _zoom_fit.pressed.connect(_fit_map)
 for button: Button in [_zoom_out, _zoom_in, _zoom_fit]:
  button.custom_minimum_size = Vector2(60,58)
  button.add_theme_font_size_override("font_size",22)
  add_child(button)
 _zoom_readout = ArcadeUI.label("",14,ArcadeUI.CYAN)
 _zoom_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 add_child(_zoom_readout)
 _next_label = ArcadeUI.label("", 15, ArcadeUI.CYAN)
 _next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _world.add_child(_next_label)
 for i in Campaign.ORDER.size():
  var id: String = Campaign.ORDER[i]
  var planet := PlanetButton.new()
  planet.planet_id = id
  # Locked nodes can be inspected; deployment remains guarded by Game.select_level.
  planet.mouse_filter = Control.MOUSE_FILTER_IGNORE
  planet.focus_mode = Control.FOCUS_NONE
  _world.add_child(planet)
  cards[id] = planet
  var lock_badge := ArcadeUI.image("res://assets/ui/badges/badge_lock.svg",Vector2(32,32))
  _world.add_child(lock_badge)
  _locks.append(lock_badge)
  var marker := ArcadeUI.label(str(i + 1), 18, ArcadeUI.GOLD if Game.is_level_unlocked(id) else Color("acc0e9"))
  marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _world.add_child(marker)
  _markers.append(marker)
  var stars := HBoxContainer.new()
  stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stars.alignment = BoxContainer.ALIGNMENT_CENTER
  stars.add_theme_constant_override("separation", 0)
  _world.add_child(stars)
  _ratings.append(stars)
  for star in 3:
   stars.add_child(ArcadeUI.image(ArcadeUI.KIT + ("badge_star_active.svg" if star < int(Game.completed_levels.get(id, 0)) else "badge_star_inactive.svg"), Vector2(26,26)))
  var name_label := ArcadeUI.label(Game.MAPS[id].name, 16, Color("c5d7ff"))
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _world.add_child(name_label)
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
 if not Game.map_focus_planet.is_empty():
  var destination := Game.map_focus_planet
  Game.map_focus_planet = ""
  _set_offset(_target_offset(Game.last_completed_planet))
  _select(destination)
  _focus_planet(destination, true)
 else:
  _focus_planet(_selected, false)
 # A short fade introduces the map; reduced-motion users get the static view.
 if not Game.reduced_motion:
  modulate.a = 0.0
  create_tween().tween_property(self,"modulate:a",1.0,0.28)
func _select(id: String) -> void:
 SoundEffects.play("select" if Game.is_level_unlocked(id) else "locked")
 _selected = id
 var unlocked := Game.is_level_unlocked(id)
 var i := Campaign.index(id)
 var status := "LOCKED" if not unlocked else ("THREE-STAR CLEAR" if Game.is_level_cleared(id) else ("RETRY FOR 3 STARS" if Game.best_stars(id)>0 else "READY"))
 _title.text = "%02d  /  %s  /  %s" % [i+1, I18n.t(Game.MAPS[id].name),I18n.t(status)]
 _detail.text = I18n.t("%s  •  %d drones%s\n%s",[I18n.t(Campaign.DIFFICULTY[i]),Campaign.target(id),I18n.t(" + guardian") if Campaign.has_boss(id) else "",I18n.t(Campaign.challenge(id)) if unlocked else I18n.t("Earn 3 stars on %s to unlock this orbit.",[I18n.t(Game.MAPS[Campaign.ORDER[i-1]].name)])])
 _detail.text+="\n"+"★ %d / 3" % Game.best_stars(id)+"  •  "+I18n.t("3 stars: at most %d damage  •  within %d s",[Campaign.damage_budget(Game.selected_ship_id),int(Campaign.par_time(id))])
 _deploy.disabled = not unlocked
 for key: String in cards:
  cards[key].selected = key == id
  cards[key].modulate = Color.WHITE if Game.is_level_unlocked(key) else Color(0.68,0.70,0.83)
func _layout(available := Rect2()) -> void:
 if not _briefing: return
 var safe := available if available.has_area() else ArcadeUI.safe_rect(get_viewport_rect().size)
 var vp := safe.size
 _back.position = safe.position + Vector2(24,18); _back.size = Vector2(170,58)
 _settings.position = safe.position + Vector2(vp.x-84,18); _settings.size = Vector2(60,58)
 _heading.position = safe.position + Vector2(210,20); _heading.size = Vector2(vp.x-600,54)
 _heading.text = I18n.t("PLANET CAMPAIGN")
 _heading.add_theme_font_size_override("font_size",22)
 _hint.position = safe.position + Vector2(210,64)
 _hint.size = Vector2(vp.x-600,24)
 _hint.text = I18n.t("Drag to explore • Pinch or wheel to zoom")
 for i in 3:
  var button: Button = [_zoom_out,_zoom_in,_zoom_fit][i]
  button.position = safe.position + Vector2(vp.x-330+i*72,18)
  button.size = Vector2(64,58)
 _zoom_fit.text = I18n.t("FIT")
 _zoom_out.tooltip_text = I18n.t("Zoom out")
 _zoom_in.tooltip_text = I18n.t("Zoom in")
 _zoom_fit.tooltip_text = I18n.t("Fit all planets")
 _zoom_readout.position = safe.position + Vector2(vp.x-330,70)
 _zoom_readout.size = Vector2(208,20)
 _map_view.position = safe.position + Vector2(24,90)
 _map_view.size = Vector2(vp.x-48, maxf(120, vp.y-260))
 _base_scale = clampf(vp.y / 720.0, 0.78, 1.15)
 _fit_zoom_cache = _calculate_fit_zoom()
 _zoom = clampf(_zoom, _minimum_zoom(), maximum_zoom)
 _zoom_target = _zoom
 _scene_scale = _base_scale * _zoom
 _world.scale = Vector2.ONE * _scene_scale
 _world.size = WORLD_SIZE
 _route.size = WORLD_SIZE
 _centers.clear()
 for i in Campaign.ORDER.size():
  var center: Vector2 = POINTS[i]
  _centers.append(center)
  var planet: PlanetButton = cards[Campaign.ORDER[i]]
  planet.position = center - Vector2(82,82)
  planet.size = Vector2(164,164)
  _markers[i].position = center + Vector2(-18,-112)
  _markers[i].size = Vector2(36,26)
  _ratings[i].position = center + Vector2(-48,82)
  _ratings[i].size = Vector2(96,28)
  _names[i].position = center + Vector2(-145,112)
  _names[i].size = Vector2(290,24)
  _names[i].text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  _names[i].text = I18n.t(Game.MAPS[Campaign.ORDER[i]].name)
  if not Game.is_level_unlocked(Campaign.ORDER[i]):
   _names[i].text += " • " + I18n.t("LOCKED")
 _next_label.text = I18n.t("CAMPAIGN COMPLETE") if Game.is_level_cleared(Campaign.ORDER[-1]) else I18n.t("NEXT PLANET") + "  •  " + I18n.t("READY")
 _next_label.position = POINTS[Campaign.index(Game.latest_unlocked_planet())] + Vector2(-145,-144)
 _next_label.size = Vector2(290,24)
 _briefing.position = safe.position + Vector2(24,vp.y-158)
 _briefing.size = Vector2(vp.x-48,134)
 _title.add_theme_font_size_override("font_size",18 if vp.x<1400 else 24)
 _deploy.custom_minimum_size.x = 180 if vp.x<1400 else 240
 _update_zoom_visuals()
 _focus_planet(_selected, false)
 _route.queue_redraw()

func _target_offset(id: String) -> Vector2:
 return _map_view.size * 0.5 - POINTS[Campaign.index(id)] * _scene_scale

func _set_offset(value: Vector2) -> void:
 var extent := _world_bounds.size * _scene_scale
 for axis in 2:
  var low := _map_view.size[axis]-_world_bounds.end[axis]*_scene_scale
  var high := -_world_bounds.position[axis]*_scene_scale
  _offset[axis] = (_map_view.size[axis]-extent[axis])*0.5-_world_bounds.position[axis]*_scene_scale if extent[axis] <= _map_view.size[axis] else clampf(value[axis],low,high)
 _world.position = _offset
 # Hide distant artwork without rebuilding nodes or loading any gameplay scenes.
 var visible_area := Rect2(-_offset / _scene_scale, _map_view.size / _scene_scale).grow(180)
 for i in Campaign.ORDER.size():
  var on_screen := visible_area.has_point(POINTS[i])
  cards[Campaign.ORDER[i]].visible = on_screen
  _markers[i].visible = on_screen
  _ratings[i].visible = on_screen
  _names[i].visible = on_screen
  _locks[i].visible = on_screen and not Game.is_level_unlocked(Campaign.ORDER[i])

func _focus_planet(id: String, smooth: bool) -> void:
 _zoom_target = _zoom
 if _focus_tween: _focus_tween.kill()
 _velocity = Vector2.ZERO
 if smooth and not Game.reduced_motion:
  _focus_tween = create_tween()
  _focus_tween.tween_method(_set_offset, _offset, _target_offset(id), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 else:
  _set_offset(_target_offset(id))

func _process(delta: float) -> void:
 if not is_equal_approx(_zoom, _zoom_target):
  var step := lerpf(_zoom, _zoom_target, 1.0-exp(-18.0*delta))
  if absf(step-_zoom_target)<0.001: step = _zoom_target
  _apply_zoom(step, _zoom_anchor)
 if _pointer == -2 and _velocity.length() > 1:
  var before := _offset
  _set_offset(_offset + _velocity * delta)
  if is_equal_approx(before.x, _offset.x): _velocity.x = 0
  if is_equal_approx(before.y, _offset.y): _velocity.y = 0
  _velocity *= exp(-6.0 * delta)

func _bounds_at_scale(map_scale: float) -> Rect2:
 var bounds := Rect2(Vector2.ZERO,WORLD_SIZE)
 var diameter := maxf(164,48/map_scale)
 var badge_scale := clampf(map_scale,0.75,1.0)/map_scale
 var star_scale := clampf(map_scale,0.5,1.0)/map_scale
 for center: Vector2 in POINTS:
  bounds = bounds.merge(Rect2(center+Vector2(-18*badge_scale,-diameter*0.5-30*badge_scale),Vector2(36,26)*badge_scale))
  bounds = bounds.merge(Rect2(center+Vector2(-145,diameter*0.5+28*star_scale+7/map_scale),Vector2(290,maxf(24,20/map_scale))))
 var next: Vector2 = POINTS[Campaign.index(Game.latest_unlocked_planet())]
 bounds = bounds.merge(Rect2(next+Vector2(-145,-diameter*0.5-50*badge_scale),Vector2(290,maxf(24,20/map_scale))))
 return bounds

func _calculate_fit_zoom() -> float:
 var value := minf(_map_view.size.x/WORLD_SIZE.x,_map_view.size.y/WORLD_SIZE.y)/_base_scale
 # At overview scale, fixed-size touch targets and text can extend past world edges.
 for iteration in 16:
  var bounds := _bounds_at_scale(_base_scale*value)
  var fit := minf(_map_view.size.x/bounds.size.x,_map_view.size.y/bounds.size.y)/_base_scale
  if absf(value-fit)<0.00001: break
  value = fit
 return value

func _fit_zoom() -> float:
 return _fit_zoom_cache

func _minimum_zoom() -> float:
 # Permit a complete overview on landscape screens as well as the normal 0.5x floor.
 return minf(minimum_zoom, _fit_zoom())

func _update_zoom_visuals() -> void:
 # Text is laid out at a minimum screen font size; overview names ellipsize into
 # their own world slot. The full name and status remain in the fixed briefing.
 var diameter := maxf(164.0, 48.0/_scene_scale)
 var text_scale := clampf(_scene_scale,0.75,1.0)/_scene_scale
 var star_scale := clampf(_scene_scale,0.5,1.0)/_scene_scale
 var name_scale := minf(1.0,1.0/_scene_scale)
 for i in Campaign.ORDER.size():
  var center: Vector2 = POINTS[i]
  var planet: PlanetButton = cards[Campaign.ORDER[i]]
  planet.size = Vector2.ONE*diameter
  planet.position = center-planet.size*0.5
  _locks[i].size = Vector2.ONE*maxf(32,18/_scene_scale)
  _locks[i].position = center+Vector2(diameter*0.22,diameter*0.22)-_locks[i].size*0.5
  _markers[i].scale = Vector2.ONE*text_scale
  _markers[i].position = center+Vector2(-18*text_scale,-diameter*0.5-30*text_scale)
  _ratings[i].scale = Vector2.ONE*star_scale
  _ratings[i].position = center+Vector2(-48*star_scale,diameter*0.5+3/_scene_scale)
  _names[i].position = center+Vector2(-145,diameter*0.5+28*star_scale+7/_scene_scale)
  _names[i].scale = Vector2.ONE*name_scale
  _names[i].size = Vector2(290,maxf(24,20/_scene_scale))/name_scale
  _names[i].add_theme_font_size_override("font_size",int(ceil(maxf(16,12/_scene_scale))))
 var next := Campaign.index(Game.latest_unlocked_planet())
 _next_label.position = POINTS[next]+Vector2(-145,-diameter*0.5-50*text_scale)
 _next_label.add_theme_font_size_override("font_size",int(ceil(maxf(15,12/_scene_scale))))
 _next_label.scale = Vector2.ONE*name_scale
 _next_label.size = Vector2(290,maxf(24,20/_scene_scale))/name_scale
 _next_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 _world_bounds = _bounds_at_scale(_scene_scale)
 _zoom_readout.text = "%d%%" % int(round(_zoom*100))
 _zoom_out.disabled = _zoom_target <= _minimum_zoom()+0.001
 _zoom_in.disabled = _zoom_target >= maximum_zoom-0.001
 _route.queue_redraw()

func _apply_zoom(value: float, anchor: Vector2) -> void:
 var world_point := (anchor-_offset)/_scene_scale
 _zoom = clampf(value,_minimum_zoom(),maximum_zoom)
 _scene_scale = _base_scale*_zoom
 _world.scale = Vector2.ONE*_scene_scale
 _update_zoom_visuals()
 _set_offset(anchor-world_point*_scene_scale)
 Game.map_zoom = _zoom
 _zoom_dirty = true

func _request_zoom(value: float, global_anchor: Vector2) -> void:
 if _focus_tween: _focus_tween.kill()
 _zoom_anchor = global_anchor-_map_view.global_position
 _zoom_target = clampf(value,_minimum_zoom(),maximum_zoom)
 if _pointer != -2: _dragging = true
 if Game.reduced_motion: _apply_zoom(_zoom_target,_zoom_anchor)
 _zoom_out.disabled = _zoom_target <= _minimum_zoom()+0.001
 _zoom_in.disabled = _zoom_target >= maximum_zoom-0.001

func _fit_map() -> void:
 _cancel_gesture()
 _velocity = Vector2.ZERO
 _request_zoom(_fit_zoom(),_map_view.get_global_rect().get_center())
 # Zoom and translation run together; zoom preserves the center of this moving camera.
 _focus_tween = create_tween()
 var target_scale := _base_scale*_zoom_target
 var bounds := _bounds_at_scale(target_scale)
 var center_offset := (_map_view.size-bounds.size*target_scale)*0.5-bounds.position*target_scale
 _focus_tween.tween_method(_set_offset,_offset,center_offset,0.35 if not Game.reduced_motion else 0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _cancel_gesture() -> void:
 _pointer = -2
 _touches.clear()
 _pinch_ids.clear()
 _gesture_was_pinch = false
 _velocity = Vector2.ZERO
 _zoom_target = _zoom

func _touch_press(at: Vector2, index: int) -> void:
 if (_touches.is_empty() and not _map_view.get_global_rect().has_point(at)) or _pointer == -1: return
 _touches[index] = at
 if _touches.size()==1:
  _gesture_was_pinch = false
  _pointer_press(at,index)
 elif _touches.size()==2:
  _pinch_ids.assign(_touches.keys())
  _pinch_midpoint = (_touches[_pinch_ids[0]]+_touches[_pinch_ids[1]])*0.5
  _pinch_distance = _touches[_pinch_ids[0]].distance_to(_touches[_pinch_ids[1]])
  _gesture_was_pinch = true
  _dragging = true
  _velocity = Vector2.ZERO
  _zoom_target = _zoom
  if _focus_tween: _focus_tween.kill()
 get_viewport().set_input_as_handled()

func _touch_move(at: Vector2, index: int) -> void:
 if not _touches.has(index): return
 _touches[index] = at
 if _pinch_ids.size()==2:
  var midpoint: Vector2 = (_touches[_pinch_ids[0]]+_touches[_pinch_ids[1]])*0.5
  var distance: float = _touches[_pinch_ids[0]].distance_to(_touches[_pinch_ids[1]])
  _set_offset(_offset+midpoint-_pinch_midpoint)
  if _pinch_distance > 8 and distance > 8:
   _apply_zoom(_zoom*distance/_pinch_distance,midpoint-_map_view.global_position)
  _zoom_target = _zoom
  _pinch_midpoint = midpoint
  _pinch_distance = distance
  _last_motion_ms = Time.get_ticks_msec()
  get_viewport().set_input_as_handled()
 elif _pointer == index:
  _pointer_move(at,get_process_delta_time())

func _touch_release(at: Vector2, index: int, canceled: bool) -> void:
 if not _touches.has(index): return
 if canceled: _dragging = true
 _touches.erase(index)
 if _gesture_was_pinch:
  if _touches.is_empty():
   _pinch_ids.clear()
   _pointer = -2
   _velocity = Vector2.ZERO
   _gesture_was_pinch = false
  elif _pinch_ids.has(index) or _pointer == index:
   _pinch_ids.clear()
   _pointer = _touches.keys()[0]
   _last_position = _touches[_pointer]
   _press_position = _last_position
   _dragging = true
  get_viewport().set_input_as_handled()
 elif _pointer == index:
  _pointer_release(at)

func _exit_tree() -> void:
 if _zoom_dirty: Game.save_settings()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
  _cancel_gesture()
  if _zoom_dirty:
   Game.save_settings()
   _zoom_dirty = false

func _draw_route(canvas: Control) -> void:
 for i in _centers.size()-1:
  var a := _centers[i]
  var b := _centers[i+1]
  var count := maxi(18, int(a.distance_to(b)/14))
  var col := Color("79eaff") if Game.is_level_cleared(Campaign.ORDER[i]) else Color("8b90cf")
  for dot in count:
   var point := a.lerp(b, float(dot)/count)
   if point.distance_to(a)>cards[Campaign.ORDER[i]].size.x*0.5+10 and point.distance_to(b)>cards[Campaign.ORDER[i+1]].size.x*0.5+10:
    canvas.draw_circle(point, 2, Color(col, 0.6))
 for i in _centers.size():
  var badge_center := _markers[i].position+_markers[i].size*_markers[i].scale*0.5
  var radius := 15*_markers[i].scale.x
  canvas.draw_circle(badge_center,radius,Color("102456"))
  canvas.draw_arc(badge_center,radius,0,TAU,24,Color("77cfff"),1.5,true)

func _pointer_press(at: Vector2, pointer: int) -> void:
 if _pointer != -2 or not _map_view.get_global_rect().has_point(at): return
 if _focus_tween: _focus_tween.kill()
 _pointer = pointer
 _press_position = at
 _last_position = at
 _last_motion_ms = Time.get_ticks_msec()
 _dragging = false
 _velocity = Vector2.ZERO
 get_viewport().set_input_as_handled()

func _pointer_move(at: Vector2, seconds: float) -> void:
 if _pointer == -2: return
 if at.distance_to(_press_position) >= DRAG_THRESHOLD: _dragging = true
 if _dragging:
  var movement := at - _last_position
  # Include the threshold distance on the first drag frame.
  if _last_position == _press_position: movement = at - _press_position
  _set_offset(_offset + movement)
  _zoom_anchor += movement
  _velocity = _velocity.lerp(movement / maxf(seconds, 0.008), 0.45).limit_length(2200)
 _last_position = at
 _last_motion_ms = Time.get_ticks_msec()
 get_viewport().set_input_as_handled()

func _pointer_release(at: Vector2) -> void:
 if _pointer == -2: return
 if Time.get_ticks_msec() - _last_motion_ms > 120: _velocity = Vector2.ZERO
 if not _dragging and at.distance_to(_press_position)<DRAG_THRESHOLD and _map_view.get_global_rect().has_point(at):
  var local := (at - _map_view.global_position - _offset) / _scene_scale
  for id: String in Campaign.ORDER:
   var planet: PlanetButton = cards[id]
   if planet._has_point(local - planet.position):
    _select(id)
    break
 else:
  if not _dragging: _velocity = Vector2.ZERO
 _pointer = -2
 get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
 if has_node("FlightDialog"): return
 if event is InputEventScreenTouch and event.device != InputEvent.DEVICE_ID_EMULATION:
  if event.pressed: _touch_press(event.position,event.index)
  else: _touch_release(event.position,event.index,event.canceled)
 elif event is InputEventScreenDrag and event.device != InputEvent.DEVICE_ID_EMULATION:
  _touch_move(event.position,event.index)
 elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
  if event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed: _pointer_press(event.position, -1)
   elif _pointer == -1: _pointer_release(event.position)
  elif event.pressed and _map_view.get_global_rect().has_point(event.position):
   if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
    var direction := 1.0 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1.0
    _request_zoom(_zoom_target*pow(1.15,direction*event.factor),event.position)
    get_viewport().set_input_as_handled()
   elif event.button_index in [MOUSE_BUTTON_WHEEL_LEFT,MOUSE_BUTTON_WHEEL_RIGHT]:
    if _focus_tween: _focus_tween.kill()
    _set_offset(_offset+Vector2(100 if event.button_index==MOUSE_BUTTON_WHEEL_LEFT else -100,0)*event.factor)
    get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and _pointer == -1:
  _pointer_move(event.position, get_process_delta_time())
 elif event is InputEventMagnifyGesture and _map_view.get_global_rect().has_point(event.position):
  _request_zoom(_zoom_target*event.factor,event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventPanGesture and _map_view.get_global_rect().has_point(event.position):
  if _focus_tween: _focus_tween.kill()
  _set_offset(_offset - event.delta * 30)
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if has_node("FlightDialog"): return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE:
   SoundEffects.play("back")
   get_tree().change_scene_to_file("res://scenes/hangar.tscn")
  elif event.keycode in [KEY_LEFT,KEY_RIGHT]:
   _select(Campaign.ORDER[wrapi(Campaign.index(_selected)+(1 if event.keycode==KEY_RIGHT else -1),0,Campaign.ORDER.size())])
   _focus_planet(_selected, true)
  elif event.keycode == KEY_ENTER:
   if Game.select_level(_selected):
    SoundEffects.play("confirm")
    get_tree().change_scene_to_file("res://scenes/hangar.tscn")
   else: SoundEffects.play("locked")
