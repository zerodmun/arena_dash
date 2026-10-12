class_name CombatPool
extends Node
## Existing hostile shots and world effects only. Player shots never enter this pool.
var _hostile: Array[EnemyShot]=[]
var _bursts: Array[ExplosionParticles]=[]
var created_hostile:=0
var created_bursts:=0
func _ready() -> void:
 name="CombatPool"
 for i in 64:_hostile.append(_new_hostile())
 for i in 24:_bursts.append(_new_burst())
func _new_hostile() -> EnemyShot:
 var node:=EnemyShot.new()
 node.pool=self
 add_child(node)
 created_hostile+=1
 return node
func _new_burst() -> ExplosionParticles:
 var node:=ExplosionParticles.new()
 node.pool=self
 add_child(node)
 created_bursts+=1
 return node
func hostile(pos: Vector2,dir: Vector2,speed: float,damage: int) -> EnemyShot:
 var node: EnemyShot
 while not _hostile.is_empty() and not is_instance_valid(node):node=_hostile.pop_back()
 if not is_instance_valid(node):node=_new_hostile()
 node.activate(pos,dir,speed,damage)
 return node
func burst(pos: Vector2,color: Color,source_id: int = 0,source_kind: String = "world_effect") -> void:
 var node: ExplosionParticles
 while not _bursts.is_empty() and not is_instance_valid(node):node=_bursts.pop_back()
 if not is_instance_valid(node):node=_new_burst()
 node.activate(pos,color,source_id,source_kind)
func recycle(node: Node,lease: int = -1) -> void:
 # A delayed return cannot hide/requeue an object activated for another shot.
 if not is_instance_valid(node):return
 if node is ExplosionParticles:
  if node.active or (lease>=0 and node.lease!=lease):return
 elif node is EnemyShot and node.active:return
 # Called deferred after physics callbacks, so monitoring/shapes can change safely.
 node.visible=false
 node.set_physics_process(false)
 if node is Area2D:
  node.monitoring=false
  node.get_node("CollisionShape2D").disabled=true
 if node is EnemyShot:
  if node in _hostile:return
  if _hostile.size()<64:_hostile.append(node)
  else:node.queue_free()
 elif node is ExplosionParticles:
  if node in _bursts:return
  if _bursts.size()<32:_bursts.append(node)
  else:node.queue_free()

func _exit_tree() -> void:
 ExplosionParticles.gradients.clear()
 _hostile.clear();_bursts.clear()
