extends SceneTree
## Adapt existing vector artwork into real Android layers, without redrawing it.
const SIZE := 432
const SAFE_RADIUS := 132.0

func _initialize() -> void:
 var original := FileAccess.get_file_as_string("res://icon.svg")
 if original.is_empty():
  push_error("Missing updated user logo: icon.svg")
  quit(1)
  return
 if original.find("<defs>")<0 or original.find("</defs>")<0 or original.find('<path d="M432.312')<0:
  push_error("Updated logo layers are unrecognized; refusing replacement artwork.")
  quit(1)
  return
 var definitions := original.substr(original.find("<defs>"),original.find("</defs>")+7-original.find("<defs>"))
 # The latest supplied SVG has a full-bleed rectangle, two radar groups,
 # then the aircraft and its glow paths. Preserve all supplied paths and defs.
 var body_start:=original.find(">")+1
 var aircraft_start:=original.find('<path d="M432.312')
 var background_art:=original.substr(body_start,aircraft_start-body_start)
 var aircraft:=original.substr(aircraft_start,original.find("<defs>")-aircraft_start)
 if definitions.is_empty() or background_art.is_empty() or aircraft.is_empty():
  push_error("Updated logo layers are unrecognized; refusing replacement artwork.")
  quit(1)
  return
 # Reuse the supplied borderless background and aircraft geometry/colors.
 var background_svg := '<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432" viewBox="0 0 1024 1024">'+background_art+definitions+'</svg>'
 var foreground_svg := '<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432" viewBox="0 0 432 432">'+'<g transform="translate(216 216) scale(0.33) translate(-512 -508)">'+aircraft+'</g>'+definitions+'</svg>'
 var background := Image.new()
 var foreground := Image.new()
 if background.load_svg_from_string(background_svg) != OK or foreground.load_svg_from_string(foreground_svg) != OK:
  push_error("Original logo layer rasterization failed.")
  quit(1)
  return
 for pair in [["adaptive_background",background_svg,background],["adaptive_foreground",foreground_svg,foreground]]:
  var file := FileAccess.open("res://assets/android_icons/%s.svg" % pair[0],FileAccess.WRITE)
  file.store_string(pair[1])
  if pair[2].save_png("res://assets/android_icons/%s.png" % pair[0]) != OK:
   quit(1)
   return
 var combined := background.duplicate() as Image
 combined.convert(Image.FORMAT_RGBA8)
 foreground.convert(Image.FORMAT_RGBA8)
 combined.blend_rect(foreground,Rect2i(0,0,SIZE,SIZE),Vector2i.ZERO)
 # Android displays the inner 72dp of its 108dp canvas. Legacy icons use that
 # same composition, full bleed, rather than shrinking the framed square again.
 var legacy := combined.get_region(Rect2i(72,72,288,288))
 for pixels in [48,72,96,144,192]:
  var resized := legacy.duplicate() as Image
  resized.resize(pixels,pixels,Image.INTERPOLATE_LANCZOS)
  if resized.save_png("res://assets/android_icons/launcher_%d.png" % pixels) != OK:
   quit(1)
   return
 var farthest := 0.0
 for y in SIZE:
  for x in SIZE:
   if background.get_pixel(x,y).a < 0.999:
    push_error("Adaptive background must be opaque to every edge.")
    quit(1)
    return
   if foreground.get_pixel(x,y).a > 0.01:
    farthest = maxf(farthest,Vector2(x+0.5-216,y+0.5-216).length())
 if farthest > SAFE_RADIUS:
  push_error("Foreground exceeds Android's circular safe zone: %s" % farthest)
  quit(1)
  return
 print("ADAPTIVE ICON PASS: opaque full-bleed background; original aircraft radius %.2f / 132px; legacy 48–192px" % farthest)
 quit()

func _section(source: String,start_marker: String,end_marker: String) -> String:
 var start := source.find(start_marker)
 var end := source.find(end_marker)
 if start < 0 or end <= start: return ""
 return source.substr(start,end-start)
