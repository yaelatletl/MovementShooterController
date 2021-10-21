extends Component

remotesync var on_the_net_transform : Vector3 = Vector3()
remotesync var on_the_net_camera_look : Vector3 = Vector3()
remotesync var on_the_net_height : float = 2.0
puppet var local_net_transform : Vector3 = Vector3()
puppet var local_net_camera_look : Vector3 = Vector3()
puppet var local_net_height : float = 2.0
export(NodePath) var head_path
export(float) var sync_delta : float = 1
export(float) var sync_delta_angle : float = 15
onready var head = get_node(head_path)
onready var shape = actor.get_node("collision")
var average_true_transform : Vector3 
var average_true_view : Vector3
var average_true_height : float

func update_server_from_client():
	#We update here where the player thinks they are. 
	rset_unreliable_id(1, "local_net_transform", actor.global_transform.origin)
	rset_unreliable_id(1, "local_net_height", shape.shape.height)
	rset_unreliable_id(1, "local_net_camera_look", actor.head.rotation)


func interpolate_reality_to_expectation(delta):
	if get_tree().is_network_server():
		if actor.global_transform.origin.distance_to(local_net_transform) < sync_delta * 2:
			average_true_transform = actor.global_transform.origin.slerp(local_net_transform, delta)
		else:
			average_true_transform = actor.global_transform.origin
		if abs(shape.shape.height - local_net_height) > 0.2 and local_net_height <= 2:
			average_true_height = lerp(shape.shape.height, local_net_height, delta)
		else:
			average_true_height = shape.shape.height
			
func update_client_from_server():
	#We send the real position (as where the player actually is for the server)
	if get_tree().is_network_server():
		rset_unreliable("on_the_net_transform", average_true_transform )
		rset_unreliable("on_the_net_height", average_true_height)
		rset_unreliable("on_the_net_camera_look", average_true_view)


func sync_from_server(delta):
	if not get_tree().is_network_server():
		if actor.global_transform.origin.distance_to(on_the_net_transform) < sync_delta * 2:
			actor.global_transform.origin.slerp(on_the_net_transform, delta)
		else:
			actor.global_transform.origin = on_the_net_transform
		if abs(shape.shape.height - on_the_net_height) > 0.2 and on_the_net_height <= 2:
			shape.shape.height = lerp(shape.shape.height, on_the_net_height, delta)
		else:
			shape.shape.height = on_the_net_height
#		actor.head.rotation.slerp(on_the_net_camera_look, delta)
		pass



func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if get_tree().is_network_server():
		interpolate_reality_to_expectation(delta)
		update_client_from_server()
	else:
		if is_network_master():
			update_server_from_client()
		sync_from_server(delta*10)
	pass

#func _physics_process(delta: float) -> void:
#	if not enabled: 
#		return
#	if get_tree().get_rpc_sender_id() != int(actor.name):
#		print("Recieving data from ", get_tree().get_rpc_sender_id(), " expected from ", actor.name)
#		return
#	var new_delta = delta * 50
#	if get_tree().network_peer != null:
#		average_true_transform  = actor.global_transform.origin
#		average_true_view  = actor.head.rotation
#		average_true_height  = shape.shape.height
#		if get_tree().is_network_server():
#			if not local_net_transform.length() > 0 or not local_net_camera_look.length() > 0 or not local_net_height > 0:
#				return
#
#			if average_true_transform.distance_to(local_net_transform) < sync_delta:
#				average_true_transform = local_net_transform.slerp( actor.global_transform.origin, new_delta)
#			if average_true_view.angle_to(local_net_camera_look) < deg2rad(sync_delta_ange) or average_true_view.angle_to(local_net_camera_look) > deg2rad(-sync_delta_ange):
#				average_true_view = lerp_angles(local_net_camera_look, actor.head.rotation, new_delta)
#			average_true_height = lerp(local_net_height,  shape.shape.height, new_delta)
#			_from_server_update()
#
#		if get_parent().is_network_master():
#			local_net_transform = actor.global_transform.origin 
#			local_net_height = shape.shape.height
#			local_net_camera_look = head.rotation 
#			_from_client_update()
#	if on_the_net_height != null:
#		average_true_height = lerp(shape.shape.height, on_the_net_height, new_delta)
#	if on_the_net_transform != null:
#		average_true_transform = actor.global_transform.origin.slerp(on_the_net_transform, new_delta)
#	if average_true_transform.length() > 0:
#		actor.global_transform.origin = on_the_net_transform
#	if average_true_height > 0:
#		shape.shape.height = average_true_height
			
func _process(delta: float) -> void:
	if not enabled:
		return
#	var new_delta = delta * 10
#	if on_the_net_camera_look != null:
#		average_true_view = lerp_angles(actor.head.rotation, on_the_net_camera_look, new_delta)
#	if average_true_view.length() > 0:
#		actor.head.rotation = on_the_net_camera_look
	sync_rotation(delta*10)

func sync_rotation(delta : float) -> void:
		
	if get_tree().is_network_server():
		if actor.head.rotation.angle_to(local_net_camera_look) < sync_delta_angle/2:
			average_true_view = lerp_angles(actor.head.rotation, on_the_net_camera_look, delta)
		else:
			average_true_view = actor.actor.head.rotation
	
	if not get_tree().is_network_server():
		if actor.head.rotation.angle_to(on_the_net_camera_look) < sync_delta_angle*2:
			actor.head.rotation = lerp_angles(actor.head.rotation, on_the_net_camera_look, delta)
		else:
			actor.head.rotation = on_the_net_camera_look
	

#		else:
#			new_delta *= 50
#			actor.global_transform.origin = sync_transform(actor.global_transform.origin, on_the_net_transform, new_delta)
#			shape.shape.height = lerp(shape.shape.height, on_the_net_height, new_delta)
#			if actor.global_transform.origin.origin.distance_to(on_the_net_transform.origin) > sync_delta:
#				actor.global_transform.origin = on_the_net_transform
#				shape.shape.height = on_the_net_height
#			if not is_network_master():
#				actor.head.transform = on_the_net_camera_look
func lerp_angles(rotation_from : Vector3, rotation_to : Vector3, delta: float) -> Vector3:
	return Vector3(
		lerp_angle(rotation_from.x, rotation_to.x, delta),
		lerp_angle(rotation_from.y, rotation_to.y, delta),
		lerp_angle(rotation_from.z, rotation_to.z, delta)
		)
		
func lerp_transform(local_transform : Transform, network_transform : Transform, delta : float) -> Transform:
	var quat_local = local_transform.basis.get_rotation_quat()
	var quat_network = network_transform.basis.get_rotation_quat()
	return Transform(Basis(quat_local.slerp(quat_network, delta).normalized()), local_transform.origin.slerp(network_transform.origin,delta))
