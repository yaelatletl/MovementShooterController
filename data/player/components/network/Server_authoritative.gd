extends Component

remotesync var on_the_net_transform : Vector3 = Vector3()
remotesync var on_the_net_camera_look : Vector3 = Vector3()
remotesync var on_the_net_height : float = 2.0
remotesync var on_the_net_velocity : Vector3 = Vector3()

export(NodePath) var head_path
onready var head = get_node(head_path)
onready var shape = actor.get_node("collision")

func _physics_process(delta: float) -> void:
	if not get_tree().has_network_peer():
		return
	
	if get_tree().is_network_server():
		rset_unreliable("on_the_net_transform", actor.global_transform.origin)
		rset_unreliable("on_the_net_camera_look", head.rotation)
		rset_unreliable("on_the_net_height", shape.shape.height)
		rset_unreliable("on_the_net_velocity", actor.velocity)
	else:
		actor.global_transform.origin = lerp(actor.global_transform.origin, on_the_net_transform, delta*actor.global_transform.origin.distance_to(on_the_net_transform))
		shape.shape.height = lerp(shape.shape.height, on_the_net_height, delta)
		actor.velocity = lerp(actor.velocity, on_the_net_velocity, delta*actor.velocity.distance_to(on_the_net_velocity))
	
func _process(delta: float) -> void:
	if not get_tree().has_network_peer():
		return
	if not get_tree().is_network_server():
		head.rotation = lerp_angles(head.rotation, on_the_net_camera_look, 50*delta)
		
func lerp_angles(rotation_from : Vector3, rotation_to : Vector3, delta: float) -> Vector3:
	return Vector3(
		lerp_angle(rotation_from.x, rotation_to.x, delta),
		lerp_angle(rotation_from.y, rotation_to.y, delta),
		lerp_angle(rotation_from.z, rotation_to.z, delta)
		)
