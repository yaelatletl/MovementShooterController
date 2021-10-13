extends RayCast

onready var actor = get_parent()

export(float) var sensibility : float = 0.2;  # Mouse sensitivitys



func _camera_rotation(_event) -> void:
	# If the mouse is locked
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		
		if _event is InputEventMouseMotion:
			# Rotates the camera on the x axis
			rotation.x += -deg2rad(actor.input["look_y"] * sensibility);
			
			# Rotates the camera on the y axis
			rotation.y += -deg2rad(actor.input["look_x"] * sensibility);
		
		# Creates a limit for the camera on the x axis
		var max_angle: int = 85; # Maximum camera angle
		rotation.x = min(rotation.x,  deg2rad(max_angle))
		rotation.x = max(rotation.x, -deg2rad(max_angle))

func _input(_event) -> void:
	
	# Calls the function to rotate the camera
	_camera_rotation(_event);
