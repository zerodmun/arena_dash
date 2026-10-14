class_name MissionAssets
extends Node
## One mission's dynamic textures. Only ResourceLoader reads happen on workers.
## Scene construction and resource retrieval remain on the main thread.
signal settled
var map_id := ""
var _wanted := ""
var _pending: Array[String] = []
var retained: Dictionary = {}
var failed := false
func _ready() -> void: set_process(false)
func warm(id: String) -> void:
 if id == _wanted and not (failed and _pending.is_empty()): return
 _wanted = id
 if _pending.is_empty(): _begin()
 set_process(true)
func _begin() -> void:
 retained.clear()
 failed = false
 map_id = _wanted
 var info: Dictionary = Game.MAPS[map_id]
 var paths: Array[String] = [info.icon]
 if Campaign.advanced(map_id):
  paths.append(info.tile);paths.append(info.overlay)
  for role: String in Campaign.ROSTERS[Campaign.index(map_id)] + ["boss"]:
   var path := Campaign.enemy_art(map_id,role)
   if not paths.has(path): paths.append(path)
 var obstacles := {
  "cyber":["pillar","barrier"],"forest":["dino","tree"],
  "coast":["cargo"],"desert":["cargo"],"advanced_desert":["cargo"],
  "volcano":["basalt"],"lava":["basalt"],"glacier":["cryo"],"ice":["cryo"],
  "crystal":["cryo"],"toxic":["barrel"],"advanced_toxic":["barrel"],"storm":["barrier"]
 }
 # Advanced arenas retain the original pillar/barrier layout plus their biome cover.
 if Campaign.advanced(map_id):
  paths.append("res://assets/obstacle_pillar.svg")
  paths.append("res://assets/obstacle_barrier.svg")
 for kind: String in obstacles.get(map_id,[]): paths.append("res://assets/obstacle_%s.svg" % kind)
 if map_id in ["space","dark_void"]: paths.append("res://assets/future_updates/environment/obstacle_space_rock_large.svg")
 for path in paths:
  if _pending.has(path): continue
  if ResourceLoader.load_threaded_request(path,"",false,ResourceLoader.CACHE_MODE_REUSE)==OK:
   _pending.append(path)
  else: failed=true
func _process(_delta: float) -> void:
 for i in range(_pending.size()-1,-1,-1):
  var path := _pending[i]
  var status := ResourceLoader.load_threaded_get_status(path)
  if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
  if status == ResourceLoader.THREAD_LOAD_LOADED:
   retained[path] = ResourceLoader.load_threaded_get(path)
  elif status == ResourceLoader.THREAD_LOAD_FAILED:
   ResourceLoader.load_threaded_get(path)
   failed = true
  else: failed=true
  _pending.remove_at(i)
 if not _pending.is_empty(): return
 if map_id != _wanted:
  _begin()
  return
 set_process(false)
 settled.emit()
func wait_until_ready(id: String) -> bool:
 warm(id)
 while not _pending.is_empty() or map_id != id: await settled
 return not failed
func _exit_tree() -> void:
 # Requests are only joined during engine shutdown, never a screen transition.
 for path in _pending: ResourceLoader.load_threaded_get(path)
 _pending.clear();retained.clear()
