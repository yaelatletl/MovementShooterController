extends Node3D

var speed : float = 200
@export var timer_path: NodePath
@onready var timer = get_node(timer_path)

func _ready() -> void:
	$mesh.position.z = -$mesh.mesh.height/2
	timer.connect("timeout",Callable(self,"queue_free"))

func _process(_delta) -> void:
	global_transform.origin -= (global_transform.basis.z * speed) * _delta
