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
	var trans: Transform = linked.global_transform.inverse() \
			* get_camera().global_transform
	var up := Vector3(0, 1, 0)
	trans = trans.rotated(up, PI)
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
func in_front_of_portal(portal: Node, pos: Transform) -> bool:
	var portal_pos = portal.global_transform
	var distance = portal_pos.xform_inv(pos.origin).z
	var further_from_portal = distance < 0
	var approximately_in_front = is_zero_approx(distance)
	return further_from_portal and not approximately_in_front


# Swap the velocities and positions of a body and its clone
func swap_body_clone(body: PhysicsBody, clone: PhysicsBody) -> void:
	var body_vel: Vector3 = Vector3.ZERO
	var clone_vel: Vector3 =  Vector3.ZERO
	if body is RigidBody:
		body.sleeping = true
		clone.sleeping = true
		body_vel = body.linear_velocity
		clone_vel = clone.linear_velocity
		body.linear_velocity = clone_vel
		clone.linear_velocity = body_vel
	var body_pos := body.global_transform
	var clone_pos := clone.global_transform
	if body is KinematicBody:
		body.get_node("weapons").global_transform.basis = get_camera().global_transform.basis
		body.linear_velocity = body.linear_velocity.rotated(Vector3.UP, PI)
		body.global_transform.basis.rotated(Vector3.UP, PI)

	clone.global_transform = body_pos
	body.global_transform = clone_pos


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
	var angle = portal_direction.angle_to(linked_direction)
	var up := Vector3(0, 1, 0)

	# Position of body relative to portal
	var rel_pos = portal_pos.inverse() * body_pos

	var clone: PhysicsBody
	if body in clones.keys():
		clone = clones[body]
	elif body in clones.values():
		return
	# Swap clone and actual if the actual object is more than halfway through 
	# the portal
	
	else:
		clone = body.duplicate(0)
		if clone is KinematicBody:
			clone.collision_layer = 0
			clone.collision_mask = 0
			
		#clone.mode = RigidBody.MODE_KINEMATIC
		clones[body] = clone
		add_child(clone)
		if clone is RigidBody:
			clone.linear_velocity = clone.linear_velocity.rotated(up, PI)
		clone_duplicate_material(clone)
		remove_cameras(clone)
	if not in_front_of_portal(portal, body_pos):
		swap_body_clone(body, clone)
		#yield(get_tree().create_timer(1.2), "timeout")
	clone.global_transform = linked_pos \
			* rel_pos.rotated(up, PI)
	
	


func get_portal_plane(portal: Spatial) -> Plane:
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
		for body in portal.get_node("Area").get_overlapping_bodies():
			handle_body_overlap_portal(portal, body)


func handle_body_exit_portal(portal: Node, body: PhysicsBody) -> void:
	if not body in clones:
		return
	var clone: Node = clones[body]
	if is_instance_valid(clone):
		clones.erase(body)
		clone.queue_free()


func _on_portal_a_body_exited(body: PhysicsBody) -> void:
	handle_body_exit_portal($PortalA, body)


func _on_portal_b_body_exited(body: PhysicsBody) -> void:
	handle_body_exit_portal($PortalB, body)
