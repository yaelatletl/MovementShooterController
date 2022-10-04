extends Node

onready var portals := [$PortalA, $PortalB]
onready var links := {
	$PortalA: $PortalB,
	$PortalB: $PortalA,
}
var cameras = []

export(NodePath) var environment_path = ""

onready var environment = get_node(environment_path)

# Dictionary between regular bodies and their clones
var clones := {}
onready var bodies := {
	$PortalA: [],
	$PortalB: []
	}

func init_portal(portal: Node) -> void:
	# Connect the mesh material shader to the viewport of the linked portal
	var linked: Node = links[portal]
	var link_viewport: Viewport = linked.get_node("Viewport")
	var portal_camera: Camera = link_viewport.get_node("Camera")
	var tex := link_viewport.get_texture()
	var mat = portal.get_node("Screen").get_node("Back").material_override
	mat.set_shader_param("texture_albedo", tex)
	if environment != null:
		portal_camera.environment = environment.environment
	cameras.append(portal_camera)
	var plane_normal = get_portal_plane(portal).normal
	print("The normal of the portal plane is: ", plane_normal)
	print("The normal of the portal is ", portal.transform.basis.z)

	


# Init portals
func _ready() -> void:
	for portal in portals:
		init_portal(portal)


func get_camera() -> Camera:
	if Engine.is_editor_hint():
		return get_node("/root/EditorCameraProvider").get_camera()
	else:
		return get_viewport().get_camera()


# Move the camera to a location near the linked portal; this is done by
# taking the position of the player relative to the linked portal, and
# rotating it pi radians
func move_camera(portal: Node) -> void:
	var linked: Node = links[portal]
	var portal_direction = portal.global_transform.basis.z
	var linked_direction = linked.global_transform.basis.z
	#var angle = PI - portal_direction.angle_to(linked_direction)
	var angle = PI - linked.global_rotation.y 
	var trans: Transform = linked.global_transform.inverse() * get_camera().global_transform
	trans = trans.rotated(Vector3.UP, angle)
	portal.get_node("CameraHolder").transform = trans
	var cam_pos: Transform = portal.get_node("CameraHolder").global_transform
	portal.get_node("Viewport/Camera").global_transform = cam_pos


# Sync the viewport size with the window size
func sync_viewport(portal: Node) -> void:
	portal.get_node("Viewport").size = get_viewport().size


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	# TODO: figure out why this is needed
	if Engine.is_editor_hint():
		if get_camera() == null:
			return
		_ready()
	for camera in cameras:
		if not camera.is_inside_tree():
			return
		if get_camera() != null:
			camera.fov = get_camera().fov
	for portal in portals:
		move_camera(portal)
		sync_viewport(portal)


# Return whether the position is in front of a portal
func in_front_of_portal(portal: Spatial, pos: Transform) -> bool:
	var portal_pos = portal.global_transform
	var distance = portal_pos.xform_inv(pos.origin).z
	var further_from_portal = distance < 0
	#var approximately_in_front = is_zero_approx(distance)
	#var approximately_in_front = distance > 0
	var approximately_in_front = get_portal_plane(portal).is_point_over(pos.origin) and not is_zero_approx(distance)
	return further_from_portal and not approximately_in_front

#Swapping is inconsistent with relative positions
# Swap the velocities and positions of a body and its clone
func swap_body_clone(body: PhysicsBody, clone: PhysicsBody, angle : float, linked_z_basis : Vector3) -> void:
	var body_vel: Vector3 = Vector3.ZERO
	var clone_vel: Vector3 =  Vector3.ZERO
	if clone is KinematicBody:
		clone_vel = clone.get_meta("linear_velocity")
	elif clone is RigidBody:
		clone_vel = clone.linear_velocity
	if (body.has_method("_get_component") and body is KinematicBody) or body is RigidBody:
		print("Initial velocity of body: ", body.linear_velocity, " length: ", body.linear_velocity.length())
		body_vel = body.linear_velocity

	if body is RigidBody:
		body.sleeping = true
		clone.sleeping = true
	#Swap the velocities
	if (body.has_method("_get_component") and body is KinematicBody) or body is RigidBody:
		body.linear_velocity = clone_vel
		print("Velocity of body after swap: ", body.linear_velocity, " length: ", body.linear_velocity.length())

	if clone is KinematicBody:
		clone.set_meta("linear_velocity", body_vel)
	elif clone is RigidBody:
		clone.linear_velocity = body_vel

	var body_pos := body.global_transform
	var clone_pos := clone.global_transform
	if body is KinematicBody and body.has_method("_get_component"):
		body.get_node("weapons").global_transform.basis = get_camera().global_transform.basis
#		body.linear_velocity = body.linear_velocity.rotated(Vector3.UP, angle) 
		#body.global_transform.basis.rotated(Vector3.UP, angle)

	clone.global_transform = body_pos
	body.global_transform = clone_pos 
	
	body.global_transform.origin -= linked_z_basis.normalized() * 0.001


func clone_duplicate_material(clone: PhysicsBody) -> void:
	for child in clone.get_children():
		if child.has_method("get_surface_material"):
			# TODO: iterate over materials
			var material: Material = child.get_surface_material(0)
			material = material.duplicate(false)
			child.set_surface_material(0, material)


# Remove all cameras that are children of `node`
# TODO: Make this more flexible
func remove_cameras(node: Node) -> void:
	for child in node.get_children():
		remove_cameras(child)
		if child is Camera:
			child.free()


func handle_clones(portal: Node, body: PhysicsBody) -> void:
	if body is StaticBody:
		return
	var linked: Node = links[portal]

	var body_pos := body.global_transform
	var portal_pos = portal.global_transform
	var linked_pos = linked.global_transform
	var portal_direction = portal_pos.basis.z
	var linked_direction = linked_pos.basis.z
#	var angle = PI - portal_direction.angle_to(linked_direction)
	var angle = PI - linked.global_rotation.y 	

	# Position of body relative to portal
	var rel_pos = portal.to_local(body_pos.origin) * Vector3(-1, 1, -1)
	var rel_rot = body_pos.basis.rotated(Vector3.UP, angle)
	var clone: PhysicsBody
	
	if body in clones.keys():
		clone = clones[body]
	elif body in clones.values():
		return	
	else:
		clone = body.duplicate(0)
		if clone is KinematicBody:
			clone.get_node("passive_marker_man").visible = false
			#clone.collision_layer = 0
			#clone.collision_mask = 0
			
		clones[body] = clone
		add_child(clone)
	if clone is RigidBody:
		clone.linear_velocity = body.linear_velocity.rotated(Vector3.UP, angle) 
	elif clone is KinematicBody and body.has_method("_get_component"):
		clone.set_meta("linear_velocity", body.linear_velocity.rotated(Vector3.UP, angle))
	clone_duplicate_material(clone)
	remove_cameras(clone)
	
	# Swap clone and actual if the actual object is more than halfway through 
	# the portal
	if not in_front_of_portal(portal, body_pos):
		swap_body_clone(body, clone, angle, linked_direction)
	
	clone.global_transform.origin = linked.to_global(rel_pos)
	clone.global_transform.basis = rel_rot
	
	


func get_portal_plane(portal: Spatial) -> Plane:
	#var global_portal_plane = Plane(portal.to_global(Vector3(0, 0, 1)), 0)
	#return portal.global_transform.xform(global_portal_plane)
	# Fix rotation first

	return portal.global_transform.xform(Plane.PLANE_XY)


func portal_plane_rel_body(portal: Spatial, body: PhysicsBody) -> Color:
	var global_plane := get_portal_plane(portal)
	var plane: Plane = -body.global_transform.inverse().xform(global_plane)
	return Color(plane.x, plane.y, plane.z, plane.d)


func add_clip_plane(portal: Spatial, body: PhysicsBody) -> void:
	if body is StaticBody:
		return
	var plane_pos := portal_plane_rel_body(portal, body)
	for body_child in body.get_children():
		if body_child.has_method("get_surface_material"):
			# TODO: iterate over materials
			var material = body_child.get_surface_material(0)
			if material.has_method("set_shader_param"):
				material.set_shader_param("portal_plane", plane_pos)


func handle_body_overlap_portal(portal: Spatial, body: PhysicsBody) -> void:
	handle_clones(portal, body)
	add_clip_plane(portal, body)


# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	# Don't handle physics while in the editor
	if Engine.is_editor_hint():
		return

	# Check for bodies overlapping portals
	for portal in portals:
		for body in bodies[portal]:
			handle_body_overlap_portal(portal, body)



func handle_body_exit_portal(portal: Node, body: PhysicsBody) -> void:
	if not body in clones:
		return
	var clone: Node = clones[body]
	if is_instance_valid(clone):
		clones.erase(body)
		clone.queue_free()

func _on_portal_a_body_entered(body: PhysicsBody) -> void:
	bodies[$PortalA].append(body)

func _on_portal_b_body_entered(body: PhysicsBody) -> void:
	bodies[$PortalB].append(body)

func _on_portal_a_body_exited(body: PhysicsBody) -> void:
	handle_body_exit_portal($PortalA, body)
	bodies[$PortalA].erase(body)


func _on_portal_b_body_exited(body: PhysicsBody) -> void:
	handle_body_exit_portal($PortalB, body)
	bodies[$PortalB].erase(body)
