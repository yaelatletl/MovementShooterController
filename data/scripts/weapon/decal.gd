extends Node3D

@export var timer_path: NodePath;
@onready var timer = get_node(timer_path);

func _ready() -> void:
	timer.timeout.connect(queue_free);
