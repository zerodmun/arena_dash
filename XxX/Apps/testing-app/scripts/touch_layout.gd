class_name TouchLayout
extends RefCounted
const IDS := ["joystick","fire"]
static func defaults() -> Dictionary:
 return {"joystick":{"position":Vector2(0.12,0.82),"size":1.0,"opacity":0.65},"fire":{"position":Vector2(0.91,0.82),"size":1.0,"opacity":0.85}}
static func sanitize(raw: Variant) -> Dictionary:
 var result:=defaults()
 if not raw is Dictionary: return result
 for id: String in IDS:
  var data: Variant=raw.get(id,{})
  if not data is Dictionary: continue
  var point: Variant=data.get("position",result[id].position)
  if point is Vector2 and point.is_finite(): result[id].position=point.clamp(Vector2(0.02,0.02),Vector2(0.98,0.98))
  for key in ["size","opacity"]:
   var value: Variant=data.get(key,result[id][key])
   if (value is float or value is int) and is_finite(float(value)):
    result[id][key]=clampf(float(value),0.8 if key=="size" else 0.35,1.4 if key=="size" else 1.0)
 return result
static func diameter(id: String,data: Dictionary,vp: Vector2) -> float:
 return vp.y*(0.28 if id=="joystick" else 0.19)*float(data.size)
static func safe_area(vp: Vector2) -> Rect2:
 # Leave space for score, objective, notifications and guardian status.
 var area:=Rect2(Vector2(vp.x*0.025,vp.y*0.28),Vector2(vp.x*0.95,vp.y*0.69))
 if OS.get_name() in ["Android","iOS"]:
  var physical:=Vector2(DisplayServer.window_get_size())
  var device:=Rect2(DisplayServer.get_display_safe_area())
  if physical.x>0 and physical.y>0 and device.has_area():
   device.position-=Vector2(DisplayServer.window_get_position())
   var scale:=vp/physical
   area=area.intersection(Rect2(device.position*scale,device.size*scale))
 return area
static func clamp_center(center: Vector2,radius: float,vp: Vector2) -> Vector2:
 var area:=safe_area(vp)
 return center.clamp(area.position+Vector2.ONE*radius,area.end-Vector2.ONE*radius)
static func resolved(raw: Dictionary,vp: Vector2) -> Dictionary:
 var data:=sanitize(raw)
 var result: Dictionary={}
 for id: String in IDS:
  var extent:=diameter(id,data[id],vp)
  result[id]={"center":clamp_center(data[id].position*vp,extent*0.5,vp),"diameter":extent,"opacity":data[id].opacity}
 if result.fire.center.distance_to(result.joystick.center)<(result.fire.diameter+result.joystick.diameter)*0.5+vp.y*0.025:
  result.joystick.center=clamp_center(Vector2(vp.x*0.12,vp.y*0.82),result.joystick.diameter*0.5,vp)
  result.fire.center=clamp_center(Vector2(vp.x*0.91,vp.y*0.82),result.fire.diameter*0.5,vp)
 return result
static func place(data: Dictionary,id: String,point: Vector2,vp: Vector2) -> bool:
 var layout:=resolved(data,vp)
 var center:=clamp_center(point,layout[id].diameter*0.5,vp)
 var other: String="fire" if id=="joystick" else "joystick"
 if center.distance_to(layout[other].center)<(layout[id].diameter+layout[other].diameter)*0.5+vp.y*0.025: return false
 data[id].position=center/vp
 return true
