extends Component
# All speed variables

export(float) var n_speed : float = 04 # Normal
export(float) var s_speed : float = 12 # Sprint
export(float) var w_speed : float = 08 # Walking
export(float) var c_speed : float = 10 # Crouch
export(bool) var slide_on_crouch : bool = false
export(bool) var can_wallrun : bool = false
# Physics variables
export(float) var gravity      : float = 45 # Gravity force #45 is okay, don't change it 
export(float) var friction     : float = 25 # friction

export(NodePath) var collision : NodePath = ""
onready var col = get_node(collision)


func _physics_process(_delta) -> void:
	# Function for movement
	_movement(_delta)
	
	# Function for crouch
	_crouch(_delta)
	

	# Function for sprint
	_sprint(_delta)

func _movement(_delta) -> void:
	actor.direction = Vector3()
	actor.direction += (-actor.input["left"]    + actor.input["right"]) * actor.head_basis.x
	actor.direction += (-actor.input["forward"]  +  actor.input["back"]) * actor.head_basis.z
	
	# Check is on floor
	if actor.is_on_floor():
		actor.reset_wall_multi()
		actor.direction.y = 0 
		actor.direction = actor.direction.normalized()
		actor.direction = actor.direction.linear_interpolate(Vector3(), friction * _delta)
#		if actor.input["crouch"]:
	else:
		
		# Applies gravity
		if (actor.is_on_wall() and actor.run_speed>12 and can_wallrun):
			actor.velocity.y = lerp(actor.velocity.y, 0.1, 10*_delta)
			actor.direction +=  (actor.input["forward"] -actor.input["back"])*(-actor.wall_direction.cross(Vector3.UP) -actor.wall_direction)# * actor.head_basis.z)
			actor.direction = actor.direction.normalized()
		else:
			actor.velocity.y += -gravity * _delta
	
	
	
	# Interpolates between the current position and the future position of the character
	actor.direction.normalized()
	var inertia = actor.velocity.linear_interpolate(Vector3(), (0.75 * int(actor.is_on_floor()) + 1.25) *friction * _delta)
	if inertia.length() < 1:
		inertia = Vector3()
	var target = actor.direction * n_speed + inertia 
	actor.direction.y = 0
	var temp_velocity = actor.velocity.linear_interpolate(target, n_speed * _delta)
	
	# Applies interpolation to the velocity vector
	actor.velocity.x = temp_velocity.x
	actor.velocity.z = temp_velocity.z
	
	# Calls the motion function by passing the velocity vector
	actor.velocity = actor.move_and_slide(actor.velocity, Vector3(0,1,0), false, 4, PI/4, false)
	
	for index in actor.get_slide_count():
		var collision = actor.get_slide_collision(index)
		if collision.collider is RigidBody:
				collision.collider.apply_central_impulse(-collision.normal * actor.run_speed/collision.collider.mass)
	
func _crouch(_delta) -> void:
	# Inputs
	if not col:
		return
	
	# Get the character's head node
	
	# If the head node is not touching the ceiling
	if not actor.head.is_colliding():
		# Takes the character collision node
		
		
		# Get the character's collision shape
		var shape = col.shape.height
		
		# Changes the shape of the character's collision
		shape = lerp(shape, 2 - (actor.input["crouch"] * 2.1), w_speed  * _delta)
		
		# Apply the new character collision shape
		col.shape.height = shape



func _sprint(_delta) -> void:
	# Inputs
	# Make the character sprint
	if not actor.input["crouch"]: # If you are not crouching
		# switch between sprint and walking
		actor.reset_slide_multi()
		var toggle_speed : float = w_speed + ((s_speed - w_speed) * actor.input["sprint"]) #Normal Sprint Speed
		
		if actor.is_on_wall() and actor.is_far_from_floor() and actor.run_speed>12 and can_wallrun:
			toggle_speed *= actor.wall_multiplier #On wall sprint speed
			actor.wall_multiplier = lerp(actor.wall_multiplier, 1.0, _delta/20)
		# Create a character speed interpolation
		n_speed = lerp(n_speed, toggle_speed, 3 * _delta)
	else:
		# Create a character speed interpolation
		actor.velocity.y -= 0.1*actor.run_speed*_delta
		if slide_on_crouch and actor.run_speed>12 and actor.is_on_floor():
			n_speed = lerp(n_speed, w_speed * actor.multiplier , 15* _delta)
			actor.multiplier = lerp(actor.multiplier, 0.8, _delta*20)
			return
		elif actor.is_on_floor():
			n_speed = lerp(n_speed, c_speed, actor.multiplier*_delta)
			actor.reset_slide_multi()
			actor.reset_wall_multi()
