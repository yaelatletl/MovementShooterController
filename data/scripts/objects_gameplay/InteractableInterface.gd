extends InteractableGeneric
class_name InteractableInterface

signal interacted_successfully(body)


func interaction_triggered(interacting_body : Spatial):
	emit_signal("interacted_successfully", interacting_body)
	pass

