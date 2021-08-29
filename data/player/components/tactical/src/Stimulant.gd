extends Component

#Stimulant: Increases velocity by "velocity_constant" per phys frame during "stim_duration" 
#numbers above 1.1 get easily out of hand, use with care. 

var active : bool = false
export(float) var velocity_constant : float = 0.8
export(float) var stim_duration : float = 5

func toggle_stim(turn_off = false) -> void:
	if not active:
		active = true
		get_tree().create_timer(stim_duration).connect("timeout", self, "toggle_stim", [true])
	if turn_off:
		active = false

func _process(delta) -> void:
	if actor.input["special"]:
		toggle_stim()
		
	if active:
		actor.velocity += actor.velocity.normalized()*Vector3(1,0,1)*velocity_constant
