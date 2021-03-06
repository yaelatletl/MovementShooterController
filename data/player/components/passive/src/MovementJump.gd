extends Component

var jump_timer = null
var can_jump = true

export(float) var jump_height  : float = 15 # Jump height
export(bool) var jumps_from_wall : bool = false

func _toggle_jump():
	can_jump = false
	if jump_timer == null:
		jump_timer = get_tree().create_timer(0.2)
		jump_timer.connect("timeout", self, "_enable_jump")

func _physics_process(_delta):
		# Function for jump
	if enabled:
		_jump(_delta)
	

func _enable_jump():
	can_jump = true
	jump_timer = null
	
func _jump(_delta) -> void:
	# Makes the player jump if he is on the ground
	if actor.input["jump"] and can_jump:
		_toggle_jump()
		actor.reset_wall_multi()
		if not actor.is_far_from_floor():
			actor.velocity.y += jump_height
		if actor.is_on_wall() and jumps_from_wall:
			actor.velocity += (-actor.input["left"] + actor.input["right"]) * actor.head_basis.x * jump_height*1.2
