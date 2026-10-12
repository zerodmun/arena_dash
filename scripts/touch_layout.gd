class_name TouchLayout
extends RefCounted
const IDS := ["joystick","fire"]
static func defaults() -> Dictionary:
 return {"joystick":{"position":Vector2(0.12,0.82),"size":1.0,"opacity":0.65,"fixed":true},"fire":{"position":Vector2(0.91,0.82),"size":1.0,"opacity":0.85}}
static func sanitize(raw: Variant) -> Dictionary:
 var result:=defaults()
 if not raw is Dictionary: return result
 for id: String in IDS:
  var data: Variant=raw.get(id,{})
  if not data is Dictionary: continue
  var point: Variant=data.get("position",result[id].position)
  if point is Vector2 and point.is_finite(): result[id].position=point.clamp(Vector2(0.0,0.0),Vector2.ONE)
  for key in ["size","opacity"]:
   var value: Variant=data.get(key,result[id][key])
   if (value is float or value is int) and is_finite(float(value)):
    result[id][key]=clampf(float(value),0.8 if key=="size" else 0.35,1.4 if key=="size" else 1.0)
 var joystick: Variant=raw.get("joystick",{})
 if joystick is Dictionary:
  var fixed: Variant=joystick.get("fixed",true)
  if fixed is bool: result.joystick.fixed=fixed
 return result
static func diameter(id: String,data: Dictionary,vp: Vector2) -> float:
 return vp.y*(0.28 if id=="joystick" else 0.19)*float(data.size)
static func footprint_radius(id: String,extent: float) -> float:
 # Include the knob texture at full travel, not only the base circle.
 return extent*(.56 if id=="joystick" else .5)
static func safe_area(vp: Vector2) -> Rect2:
 # Shooting stays below the interactive HUD; movement may use the entire left half.
 return Rect2(Vector2(vp.x*0.025,vp.y*0.28),Vector2(vp.x*0.95,vp.y*0.69)).intersection(ArcadeUI.safe_rect(vp))
static func allowed_area(id: String,vp: Vector2,usable := Rect2()) -> Rect2:
 var safe:=usable if usable.has_area() else ArcadeUI.safe_rect(vp)
 var middle:=safe.get_center().x
 if id=="joystick": return Rect2(safe.position,Vector2(safe.size.x*.5,safe.size.y))
 var right:=Rect2(Vector2(middle,safe.position.y),Vector2(safe.size.x*.5,safe.size.y))
 return right.intersection(Rect2(Vector2(vp.x*0.025,vp.y*0.28),Vector2(vp.x*0.95,vp.y*0.69)))
static func clamp_center(center: Vector2,radius: float,vp: Vector2,id := "fire",usable := Rect2()) -> Vector2:
 var area:=allowed_area(id,vp,usable)
 return center.clamp(area.position+Vector2.ONE*radius,area.end-Vector2.ONE*radius)
static func resolved(raw: Dictionary,vp: Vector2,usable := Rect2()) -> Dictionary:
 var data:=sanitize(raw)
 var result: Dictionary={}
 for id: String in IDS:
  var area:=allowed_area(id,vp,usable)
  var extent:=minf(diameter(id,data[id],vp),minf(area.size.x,area.size.y)/(1.12 if id=="joystick" else 1.0))
  result[id]={"center":clamp_center(data[id].position*vp,footprint_radius(id,extent),vp,id,usable),"diameter":extent,"opacity":data[id].opacity}
 result.joystick.fixed=data.joystick.fixed
 return result
static func place(data: Dictionary,id: String,point: Vector2,vp: Vector2,usable := Rect2()) -> bool:
 var layout:=resolved(data,vp,usable)
 # Reject a fire drag directly onto movement, rather than jumping to the divider.
 if id=="fire" and point.distance_to(layout.joystick.center)<(layout.fire.diameter+layout.joystick.diameter)*.5: return false
 var center:=clamp_center(point,footprint_radius(id,layout[id].diameter),vp,id,usable)
 data[id].position=center/vp
 return true
