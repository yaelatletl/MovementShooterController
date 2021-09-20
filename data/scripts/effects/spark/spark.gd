extends GPUParticles3D

@export var timer_path: NodePath;
@onready var timer = get_node(timer);

func _ready() -> void:
	timer.timeout.connect(queue_free);
