extends Component

var waiting_for_interaction : Node = null
var current_timer : SceneTreeTimer = null
var interaction_time_fulfilled : bool = false
var interaction_time : float = 0.0

signal time_left_changed(time_left)

func _ready():
	_component_name = "interactor"

func request_interact(interactable : Spatial, message : String, time :float= 0.0):
	#We need to pass the message to the HUD
	actor._get_component("HUD").interact_board.show_message(message)
	waiting_for_interaction = interactable
	interaction_time = time

func start_interaction():
	current_timer = get_tree().create_timer(interaction_time)
	current_timer.connect("timeout", self, "interaction_time_fulfilled")


func interaction_time_fulfilled():
	interaction_time_fulfilled = true

func stop_interact():
	if current_timer != null:
		current_timer.disconnect("timeout", self, "interaction_time_fulfilled")
		current_timer = null
	interaction_time_fulfilled = false
	emit_signal("time_left_changed", interaction_time)
	clear_interact()

func clear_interact():
	if actor._get_component("HUD"):
		actor._get_component("HUD").interact_board.hide_message()
	if current_timer != null:
		current_timer.disconnect("timeout", self, "interaction_time_fulfilled")
		current_timer = null
	waiting_for_interaction = null
	interaction_time = 0.0
	interaction_time_fulfilled = false

func _physics_process(delta):
	if actor.input["use"]:
		if is_instance_valid(waiting_for_interaction):
			if current_timer == null:
				start_interaction()
			else:
				#We are still waiting for the interaction to be fulfilled,
				#we show the interaction time left to the player through the HUD signal (Must be connected elsewhere)
				emit_signal("time_left_changed", current_timer.time_left)
			if waiting_for_interaction.has_method("interaction_triggered"):
				if interaction_time_fulfilled:
					waiting_for_interaction.interaction_triggered(actor)
	elif interaction_time > 0.0:
		stop_interact()

func request_actor():
	return actor