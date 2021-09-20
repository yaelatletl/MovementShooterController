extends Node3D

var speed : float = 200;
@export var timer_path: NodePath;
@onready var timer = get_node(timer_path);

func _ready() -> void:
	$mesh.position.z = -$mesh.mesh.mid_height/2;
	timer.timeout.connect(queue_free);

func _process(_delta) -> void:
	position -= (global_transform.basis.z * speed) * _delta;
