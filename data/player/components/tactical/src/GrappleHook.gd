extends Component

export(NodePath) var camera_path
export(PackedScene) var grapple_point
export(float) var hook_lenght = 3.0
export(float) var hook_tolerance = 1.5
export(float) var hook_stiffness = 2.5
export(float) var hook_time = 3
onready var camera : Camera = get_node(camera_path)

#Hook calculation vars
var is_actor_y_aligned = false
var attached_to = null
var direction = Vector3.ZERO
var distance = 0
var force = 0

#Object dynamics and hook points
var static_collision_point = Vector3.ZERO
var non_static_collision_point = Vector3.ZERO

var grapple_is_activated : bool = false

func _screen_middle() -> Vector2:
	return get_tree().get_root().size/2
	
func _launch_grapple():
	var middle = camera.project_ray_normal(_screen_middle())
	var new_grap : RigidBody = grapple_point.instance()
	new_grap.connect("body_hit", self, "_on_body_entered", [new_grap])
	new_grap.set_as_toplevel(true)
	new_grap.translation = camera.global_transform.origin + 1.5*middle
	add_child(new_grap)
	new_grap.apply_central_impulse(4*middle)

func _end_grapple_time():
	grapple_is_activated = false
	is_actor_y_aligned = false
	direction = Vector3.ZERO
	attached_to = null
	distance = 0
	force = 0
	
func _on_body_entered(_point : Vector3, _body : Node, grapple):
	if _body is Spatial:
		attached_to = _body
		static_collision_point = _point
		if _body is RigidBody or _body is KinematicBody:
			non_static_collision_point = _body.to_local(_point)
		grapple_is_activated = true
		get_tree().create_timer(hook_time).connect("timeout", self, "_end_grapple_time")
		grapple.queue_free()
		

func _physics_process(delta):
	if not enabled:
		return
	if actor.input["special"]:
		if not grapple_is_activated:
			_launch_grapple()
		else:
			_end_grapple_time()

	if attached_to != null:
	
		if attached_to is StaticBody:
			direction = (static_collision_point-actor.head.global_transform.origin).normalized()
			distance = static_collision_point.distance_to(actor.head.global_transform.origin)
			if static_collision_point.y < actor.head.global_transform.origin.y: 
				#won't work if we grapple to the ground, but swinging this way feels more natural
				is_actor_y_aligned = true
		if attached_to is RigidBody or attached_to is KinematicBody:
			direction = (attached_to.to_global(non_static_collision_point)-actor.head.global_transform.origin).normalized()
			distance = (attached_to.to_global(non_static_collision_point).distance_to(actor.head.global_transform.origin))
			if is_zero_approx(attached_to.to_global(non_static_collision_point).y-actor.head.global_transform.origin.y):
				is_actor_y_aligned = true
		
		#force += ( (hook_stiffness) * (distance - hook_lenght)) 
		force += clamp(( (hook_stiffness) * (distance - hook_lenght)), 0, 100) 
		#force = clamp(force -(0.5/clamp(distance, 0.1, hook_lenght)*delta), 0,1000)
		
		if distance < 2.2 or distance > hook_tolerance*hook_lenght or is_actor_y_aligned:
			_end_grapple_time()
		else: 
			if attached_to is RigidBody:
				attached_to.linear_velocity +=  delta*force*(-direction)/attached_to.mass
				actor.velocity +=  (0.75*force*(direction))/attached_to.mass*delta
			else:
				actor.velocity +=  force*(direction)*delta
			
