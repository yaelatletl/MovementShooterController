extends Component

export(float) var jump_height : float = 15
export(int) var jumps_before_floor : int = 1 #Times you can jump without touching the floor
export(bool) var walls_add_jumps : bool = false

var triggerable : bool = true
var jump_timer = null

var remaining_jumps = 1

var movement = null

func _ready():
	movement = actor._get_component("movement")

func _toggle_jump():
	if jump_timer == null:
		jump_timer = get_tree().create_timer(0.5)
		jump_timer.connect("timeout", self, "_enable_jump")

func _enable_jump():
	triggerable = true
	jump_timer = null

func _physics_process(delta):
	if movement != null:
		if actor.is_on_floor() or actor.is_on_wall():
			movement.gravity = movement.DEFAULT_GRAVITY
		else:
			movement.gravity = lerp(movement.gravity, movement.DEFAULT_GRAVITY, delta * 10)
	if not enabled:
		return
	#We may be able to use cross product to know if the current normal is parallel
	#to the previous to avoid jumping twice in the same wall
	if not actor.is_far_from_floor() or (walls_add_jumps and actor.is_on_wall()):
		remaining_jumps = jumps_before_floor
	if not actor.is_far_from_floor() or actor.is_on_wall():
		_toggle_jump()
	if (actor.input["jump"]) and triggerable and (remaining_jumps!=0 or jumps_before_floor == -1):
		if actor.is_far_from_floor() or actor.is_on_wall():
			remaining_jumps -= 1
			if movement != null:
				movement.gravity /= 2
			actor.linear_velocity.y += jump_height
			actor.linear_velocity *= 1.2
			triggerable = false
