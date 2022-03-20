extends RigidBody
class_name Projectile

export(float) var type : int = 0
export(float) var damage : int = 0
export(float) var speed : int = 1
export(float) var lifetime : float = 5.0
export(Vector3) var direction : Vector3 = Vector3(0, 0, 0)

signal request_destroy()

func is_projectile(): # Helps avoid cyclic references
	return true 

func _ready() -> void:
	connect("body_entered", self, "on_body_entered")

func on_body_entered(body) -> void:
	if body.has_method("is_projectile"):
		if body.type == type:
			return
	if body.has_method("_damage"):
		body._damage(damage)
	stop()

func network_sync() -> void:
	Gamestate.set_in_all_clients(self, "translation", translation)

func stop() -> void:
	direction = Vector3(0, 0, 0)
	sleeping = true
	for exeptions in get_collision_exceptions():
		remove_collision_exception_with(exeptions)
	emit_signal("request_destroy")

func move(pos, dir) -> void:
	#print("Position passed to move:", pos)
	get_tree().create_timer(lifetime).connect("timeout", self, "stop")
	sleeping = false
	global_transform.origin = pos
	if is_inside_tree():
		apply_central_impulse(direction * speed)
