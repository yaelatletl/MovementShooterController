extends Node
onready var actor = get_parent()
onready var shape = actor.get_node("collision")
func _ready() -> void:
	for node in actor.components:
		if node != "Input":
			actor.components[node].enabled = false

func _get_local_input() -> Dictionary:
	return actor.input	
	

func _save_state() -> Dictionary:
	return {
		translation = actor.translation,
		view_angle = actor.head.rotation,
		velocity = actor.velocity,
		height = shape.shape.height,
	}


func _network_process(input: Dictionary) -> void:
	for node in actor.components:
		actor.components[node]._functional_routine(input)
	pass


func _load_state(state: Dictionary) -> void:
	actor.translation = state['translation']
	actor.head.rotation = state['view_angle']
	actor.velocity = state['velocity']
	shape.shape.height = state['height']
