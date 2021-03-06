extends RigidBody
class_name Projectile

export(float) var type : int = 0
export(float) var damage : int = 0
export(float) var speed : int = 100
export(float) var lifetime : float = 5.0

signal request_destroy()

func is_projectile(): # Helps avoid cyclic references
	return true 

func _init():
	connect("body_entered", self, "_on_body_entered")

func add_exceptions(actor):
	add_collision_exception_with(actor)

func network_sync() -> void:
	Gamestate.set_in_all_clients(self, "translation", translation)

func stop() -> void:
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	for exeptions in get_collision_exceptions():
		remove_collision_exception_with(exeptions)
	emit_signal("request_destroy")

func move(pos, dir) -> void:
	#print("Position passed to move:", pos)
	get_tree().create_timer(lifetime).connect("timeout", self, "stop")
	sleeping = false
	global_transform.origin = pos
	if is_inside_tree():
		linear_velocity = dir.normalized() * speed
		#add_central_force(dir.normalized() * speed)
		#apply_central_impulse(dir.normalized() * speed)


func _on_body_entered(body) -> void:
	if body.has_method("is_projectile"):
		if body.type == type:
			return
	print("Projectile hit:", body)
	if body.has_method("_damage"):
		body._damage(damage)
	stop()

