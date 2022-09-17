extends RigidBody3D
class_name Projectile

var damage_type = Pooling.DAMAGE_TYPE.KINECTIC

@export var type : int = 0
@export var damage: float = 0
@export var speed: float = 100
@export var lifetime: float = 5.0

signal request_destroy()

func is_projectile(): # Helps avoid cyclic references
	return true 

func _init():
	connect("body_entered",Callable(self,"_on_body_entered"))

func _ready():
	get_tree().create_timer(0.1).connect("timeout",Callable(self,"_network_sync"))

func add_exceptions(actor):
	add_collision_exception_with(actor)

func _network_sync() -> void:
	if is_inside_tree():
		Gamestate.set_in_all_clients(self, "position", position)
		get_tree().create_timer(0.1).connect("timeout",Callable(self,"_network_sync"))
	
func stop() -> void:
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	for exeptions in get_collision_exceptions():
		remove_collision_exception_with(exeptions)
	emit_signal("request_destroy")

func move(pos, dir) -> void:
	get_tree().create_timer(lifetime).connect("timeout",Callable(self,"stop"))
	sleeping = false
	global_transform.origin = pos
	if is_inside_tree():
		linear_velocity = dir.normalized() * speed


func _on_body_entered(body) -> void:
	if body.has_method("is_projectile"):
		if body.type == type:
			return
	print("Projectile hit:", body)
	if body.has_method("_damage"):
		body._damage(damage, damage_type)
	stop()

