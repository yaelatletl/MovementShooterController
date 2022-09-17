extends Node3D


func send_power(powered: bool) -> void:
	var bodies: Array = $PowerConnector.get_overlapping_bodies()
	if bodies.is_empty():
		return
	var body: PhysicsBody3D = bodies[0]
	if body.has_method("recv_power"):
		body.recv_power(powered)


func _on_Switch_body_entered(body: PhysicsBody3D) -> void:
	send_power(true)


func _on_Switch_body_exited(body: PhysicsBody3D) -> void:
	send_power(false)
