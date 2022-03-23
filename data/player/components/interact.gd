extends Component

var waiting_for_interaction = null

func _ready():
	_component_name = "interactor"

func request_interact(interactable : Spatial, message : String, time :float= 0.0):
	#We need to pass the message to the HUD
	actor._get_component("HUD").interact_board.show_message(message)
	waiting_for_interaction = interactable

func stop_interact():
	actor._get_component("HUD").interact_board.hide_message()
	waiting_for_interaction = null

func _input(event):
	if Input.is_action_just_pressed("use"):
		if is_instance_valid(waiting_for_interaction):
			if waiting_for_interaction.has_method("interaction_triggered"):
					waiting_for_interaction.interaction_triggered()
