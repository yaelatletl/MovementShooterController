extends Spatial
class_name InteractableGeneric 
var message = ""
onready var interaction_area = $PickArea


func _ready():
	var err = interaction_area.connect("body_entered", self, "_on_interaction_area_body_entered")
	assert(err == OK, "Failed to connect to body_entered signal, interaction area unproperly initialized")
	err = interaction_area.connect("body_exited", self, "_on_interaction_area_body_exited")
	assert(err == OK, "Failed to connect to body_exited signal, interaction area unproperly initialized")

func _on_interaction_area_body_entered(body):
	if body.has_method("request_interact"):
		body.request_interact(self, message)
	else:
		return

func _on_interaction_area_body_exited(body):
	if body.has_method("stop_interact"):
		body.stop_interact()
	else:
		return

func interact():
	pass
