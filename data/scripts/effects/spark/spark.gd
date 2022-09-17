extends GPUParticles3D

@export var timer_path: NodePath
@onready var timer = get_node(timer_path)

func _ready() -> void:
	timer.connect("timeout",Callable(self,"queue_free"))
