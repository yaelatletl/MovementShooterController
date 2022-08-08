extends InteractableGeneric

enum {
	MODE_HEAVY
	MODE_LIGHT
}
onready var hinge = $Hinge
onready var blade : RigidBody = $DoorBlade
var current_vel = 1

var triggerable = true
var closing = false

func interaction_triggered(interactor_body : Spatial):
	if not triggerable:
		return
	var push_vec = Vector3.ZERO
	if is_instance_valid(interactor_body):
		#push_vec = hinge.global_transform.basis.z.direction_to(interactor_body.global_transform.origin).cross(Vector3.UP)
		push_vec = interactor_body.global_transform.origin.direction_to(blade.global_transform.origin)
	current_vel *= -1
	triggerable = false
	
	if abs(blade.rotation_degrees.y) > 75:
		closing = true
	else:
		closing = false
	#	closing = true
		#hinge.set_param(hinge.PARAM_MOTOR_TARGET_VELOCITY, current_vel)
		#hinge.set_flag(hinge.FLAG_ENABLE_MOTOR, true)
	#else:
	if closing:
		blade.apply_central_impulse(350*-push_vec)
	else:
		blade.apply_central_impulse(250* push_vec)

	#hinge.set_param(hinge.PARAM_LIMIT_LOWER, -5)
	#hinge.set_param(hinge.PARAM_LIMIT_UPPER, 5)
	yield(get_tree().create_timer(1.0), "timeout")
	#hinge.set_param(hinge.PARAM_LIMIT_UPPER, 90)
	#hinge.set_param(hinge.PARAM_LIMIT_LOWER, -90)
	#hinge.set_flag(hinge.FLAG_ENABLE_MOTOR, false)
	triggerable = true

func _physics_process(delta):
	if not triggerable:
		return
	#print(blade.rotation_degrees.y, blade.linear_velocity.length())
	if abs(blade.rotation_degrees.y) < 25:
		if is_zero_approx(abs(blade.rotation_degrees.y)) and closing:
			blade.linear_velocity = lerp(blade.linear_velocity, Vector3.ZERO, delta)
			blade.angular_velocity = lerp(blade.angular_velocity, Vector3.ZERO, delta)
		blade.linear_velocity -= 0.1*delta*blade.linear_velocity.normalized()
		blade.angular_velocity -= 0.1*delta*blade.angular_velocity.normalized()


func close_door():
	hinge.set_flag(hinge.FLAG_ENABLE_MOTOR, true)
	hinge.set_param(hinge.PARAM_MOTOR_TARGET_VELOCITY, current_vel)
