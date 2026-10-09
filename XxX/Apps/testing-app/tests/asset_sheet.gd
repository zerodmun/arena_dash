extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 root.size = Vector2i(1600, 1000)
 var base := Control.new()
 root.add_child(base)
 var paths: Array[String] = []
 scan("res://assets", paths)
 var page := 0
 for start in range(0, paths.size(), 24):
  for child in base.get_children():
   child.free()
  for i in range(start, mini(start + 24, paths.size())):
   var tex := load(paths[i]) as Texture2D
   if not tex: continue
   var box := TextureRect.new()
   box.texture = tex
   box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   box.position = Vector2((i-start)%6*265, (i-start)/6*245)
   box.size = Vector2(250,210)
   base.add_child(box)
   var label := Label.new()
   label.text = paths[i].get_file()
   label.position = box.position + Vector2(0,210)
   label.add_theme_font_size_override("font_size",14)
   base.add_child(label)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/assets_%d.png" % page)
  page += 1
 quit()
func scan(path: String, paths: Array[String]) -> void:
 var dir := DirAccess.open(path)
 for f in dir.get_files():
  if f.ends_with(".svg") or f.ends_with(".png"): paths.append(path + "/" + f)
 for sub in dir.get_directories(): scan(path + "/" + sub, paths)
