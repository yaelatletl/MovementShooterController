extends Node

var inputs : Dictionary = {}

func _ready():
	Input.connect("joy_connection_changed", self, "_on_joy_changed")
	
func _on_joy_changed(device : int):
	inputs[device]["player"]


func _input(event):
	if inputs.has(event.device):
		pass
	else:
		inputs[event.device] = {}
	
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if Input.get_joy_name(event.device) == "XInput Gamepad":
			_XInput_scheme(event)
			

func _XInput_scheme(event):
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_0: 
			if event.axis_value > 0:
				inputs[event.device]["right"] = clamp(event.axis_value, 0, 1)
			else:
				inputs[event.device]["left"] = clamp(-event.axis_value, 0, 1)
	
		if event.axis == JOY_AXIS_1:
			if event.axis_value > 0:
				inputs[event.device]["back"] = clamp(event.axis_value, 0, 1)
			else:
				inputs[event.device]["forward"] = clamp(-event.axis_value, 0, 1)
	
		if event.axis == JOY_AXIS_2:
			inputs[event.device]["look_x"] = event.axis_value

		if event.axis == JOY_AXIS_3:
			inputs[event.device]["look_y"] = event.axis_value
		
		if event.axis == JOY_AXIS_6:
			inputs[event.device]["shoot"] = event.axis_value
		if event.axis == JOY_AXIS_7:
			inputs[event.device]["zoom"] = event.axis_value
