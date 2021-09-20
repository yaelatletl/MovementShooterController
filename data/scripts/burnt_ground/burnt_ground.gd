extends Node3D

@export var ray_path: NodePath;
@onready var ray = get_node(ray_path)
var ground : bool = false;

	
func _process(delta):
	if not ground:
		if ray.is_colliding():
			$mesh.global_transform.origin = ray.get_collision_point() + Vector3(0, 0.1, 0);
			ground = false;
