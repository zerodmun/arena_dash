class_name CombatPool
extends Node
## Scene-owned warm pools; inactive projectiles have no collision, processing or group membership.
const BULLET_SCENE:=preload("res://scenes/bullet.tscn")
var _bullets: Array[Bullet]=[]
var _hostile: Array[EnemyShot]=[]
var _bursts: Array[ExplosionParticles]=[]
var created_bullets:=0
var created_hostile:=0
var created_bursts:=0
func _ready() -> void:
 name="CombatPool"
 for i in 96:_bullets.append(_new_bullet())
 for i in 64:_hostile.append(_new_hostile())
 for i in 24:_bursts.append(_new_burst())
func _new_bullet() -> Bullet:
 var node:=BULLET_SCENE.instantiate() as Bullet
 node.pool=self
 add_child(node)
 created_bullets+=1
 return node
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
func bullet(pos: Vector2,dir: Vector2,weapon: String) -> Bullet:
 var node: Bullet
 while not _bullets.is_empty() and not is_instance_valid(node):node=_bullets.pop_back()
 if not is_instance_valid(node):node=_new_bullet()
 node.activate(pos,dir,weapon)
 return node
func hostile(pos: Vector2,dir: Vector2,speed: float,damage: int) -> EnemyShot:
 var node: EnemyShot
 while not _hostile.is_empty() and not is_instance_valid(node):node=_hostile.pop_back()
 if not is_instance_valid(node):node=_new_hostile()
 node.activate(pos,dir,speed,damage)
 return node
func burst(pos: Vector2,color: Color) -> void:
 var node: ExplosionParticles
 while not _bursts.is_empty() and not is_instance_valid(node):node=_bursts.pop_back()
 if not is_instance_valid(node):node=_new_burst()
 node.activate(pos,color)
func recycle(node: Node) -> void:
 # Called deferred after physics callbacks, so monitoring/shapes can change safely.
 node.visible=false
 node.set_physics_process(false)
 if node is Area2D:
  node.monitoring=false
  node.get_node("CollisionShape2D").disabled=true
 if node is Bullet:
  if _bullets.size()<96:_bullets.append(node)
  else:node.queue_free()
 elif node is EnemyShot:
  if _hostile.size()<64:_hostile.append(node)
  else:node.queue_free()
 elif node is ExplosionParticles:
  if _bursts.size()<32:_bursts.append(node)
  else:node.queue_free()

func _exit_tree() -> void:
 ExplosionParticles.gradients.clear()
 _bullets.clear();_hostile.clear();_bursts.clear()
