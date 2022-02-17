extends Node
class_name Component


onready var actor : Node = get_parent()
export(bool) var enabled : bool = true
export(String) var _component_name = ""
func _ready() -> void:
	_start()
	actor._register_component(_component_name, self)

func _functional_routine(input : Dictionary) -> void:
	pass

func _start():
	pass

func get_key(input : Dictionary, key : String) -> float:
	if input.has(key):
		return input[key]
	else:
		return 0.0
