extends Node
class_name Component


@onready var actor : Node = get_parent()
@export var enabled : bool = true
@export var _component_name: String = ""
func _ready() -> void:
	_start()
	actor._register_component(_component_name, self)
	
func _start():
	pass
