extends Component
var fuel = 150
@export(float) var fuel_limit = 150
@export(float) var depleation_rate = 1
@export(float) var refill_rate = .1

func _physics_process(delta):
	if actor.input["extra_jump"] and not (not actor.is_far_from_floor() or actor.is_on_wall()) and fuel > 0:
		actor.velocity.y = lerp(actor.velocity.y, 10, 100*delta)
		fuel -= depleation_rate
	elif fuel <= fuel_limit and (not actor.is_far_from_floor() or actor.is_on_wall()): 
		fuel += refill_rate
