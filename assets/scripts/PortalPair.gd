extends Node

@onready var portals := [$PortalA, $PortalB]
@onready var links := {
	$PortalA: $PortalB,
	$PortalB: $PortalA,
}
var cameras = []

@export var environment_path: NodePath = ""

@onready var environment = get_node(environment_path)

# Dictionary between regular bodies and their clones
var clones := {}
@onready var bodies := {
	$PortalA: [],
	$PortalB: []
	}

func init_portal(portal: Node) -> void:
	# Connect the mesh material shader to the viewport of the linked portal
	var linked: Node = links[portal]
	var link_viewport: SubViewport = linked.get_node("SubViewport")
	var portal_camera: Camera3D = link_viewport.get_node("Camera3D")
	var tex := link_viewport.get_texture()
	var mat = portal.get_node("Screen").get_node("Back").material_override
	mat.set_shader_parameter("texture_albedo", tex)
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


func get_camera_3d() -> Camera3D:
	if Engine.is_editor_hint():
		return get_node("/root/EditorCameraProvider").get_camera_3d()
	else:
		return get_viewport().get_camera_3d()


# Move the camera to a location near the linked portal; this is done by
# taking the position of the player relative to the linked portal, and
# rotating it pi radians
func move_camera(portal: Node) -> void:
	var linked: Node = links[portal]
	var portal_direction = portal.global_transform.basis.z
	var linked_direction = linked.global_transform.basis.z
	var angle = portal_direction.angle_to(linked_direction)
	var trans: Transform3D = linked.global_transform.inverse() \
			* get_camera_3d().global_transform
	trans = trans.rotated(Vector3.UP, angle)
	portal.get_node("CameraHolder").transform = trans
	var cam_pos: Transform3D = portal.get_node("CameraHolder").global_transform
	portal.get_node("SubViewport/Camera3D").global_transform = cam_pos


# Sync the viewport size with the window size
func sync_viewport(portal: Node) -> void:
	portal.get_node("SubViewport").size = get_viewport().size


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	# TODO: figure out why this is needed
	if Engine.is_editor_hint():
		if get_camera_3d() == null:
			return
		_ready()
	for camera in cameras:
		if not camera.is_inside_tree():
			return
		if get_camera_3d() != null:
			camera.fov = get_camera_3d().fov
	for portal in portals:
		move_camera(portal)
		sync_viewport(portal)


# Return whether the position is in front of a portal
func in_front_of_portal(portal: Node3D, pos: Transform3D) -> bool:
	var portal_pos = portal.global_transform
	var distance = pos.origin * portal_pos.z
	var further_from_portal = distance < 0
	#var approximately_in_front = is_zero_approx(distance)
	#var approximately_in_front = distance > 0
	var approximately_in_front = get_portal_plane(portal).is_point_over(pos.origin)
	return further_from_portal and not approximately_in_front

#Swapping is inconsistent with relative positions
# Swap the velocities and positions of a body and its clone
func swap_body_clone(body: PhysicsBody3D, clone: PhysicsBody3D, angle : float) -> void:
	var body_vel: Vector3 = Vector3.ZERO
	var clone_vel: Vector3 =  Vector3.ZERO
	if body is RigidBody3D:
		body.sleeping = true
		clone.sleeping = true
		body_vel = body.linear_velocity
		clone_vel = clone.linear_velocity
		body.linear_velocity = clone_vel
		clone.linear_velocity = body_vel
	var body_pos := body.global_transform
	var clone_pos := clone.global_transform
	if body is CharacterBody3D:
		body.get_node("weapons").global_transform.basis = get_camera_3d().global_transform.basis
		body.linear_velocity = body.linear_velocity.rotated(Vector3.UP, angle)
		body.global_transform.basis.rotated(Vector3.UP, angle)

	clone.global_transform = body_pos
	body.global_transform = clone_pos


func clone_duplicate_material(clone: PhysicsBody3D) -> void:
	for child in clone.get_children():
		if child.has_method("get_surface_override_material"):
			# TODO: iterate over materials
			var material: Material = child.get_surface_override_material(0)
			material = material.duplicate(false)
			child.set_surface_override_material(0, material)


# Remove all cameras that are children of `node`
# TODO: Make this more flexible
func remove_cameras(node: Node) -> void:
	for child in node.get_children():
		remove_cameras(child)
		if child is Camera3D:
			child.free()


func handle_clones(portal: Node, body: PhysicsBody3D) -> void:
	if body is StaticBody3D:
		return
	var linked: Node = links[portal]

	var body_pos := body.global_transform
	var portal_pos = portal.global_transform
	var linked_pos = linked.global_transform
	var portal_direction = portal_pos.basis.z
	var linked_direction = linked_pos.basis.z
	var angle = portal_direction.angle_to(linked_direction)
	print("degrees: ", rad_to_deg(angle))
	if angle == PI:
		print("YEP YEP YEP")

	# Position of body relative to portal
	var rel_pos = portal_pos.inverse() * body_pos
	var clone: PhysicsBody3D
	
	if body in clones.keys():
		clone = clones[body]
	elif body in clones.values():
		return	
	else:
		clone = body.duplicate(0)
		if clone is CharacterBody3D:
			clone.get_node("passive_marker_man").visible = false
			clone.collision_layer = 0
			clone.collision_mask = 0
			
		clones[body] = clone
		add_child(clone)
		if clone is RigidBody3D:
			clone.linear_velocity = clone.linear_velocity.rotated(Vector3.UP, angle)
		clone_duplicate_material(clone)
		remove_cameras(clone)
	
	# Swap clone and actual if the actual object is more than halfway through 
	# the portal
	if not in_front_of_portal(portal, body_pos):
		swap_body_clone(body, clone, angle)
	clone.global_transform = linked_pos \
			* rel_pos.rotated(Vector3.UP, angle)
	
	


func get_portal_plane(portal: Node3D) -> Plane:
	#var global_portal_plane = Plane(portal.to_global(Vector3(0, 0, 1)), 0)
	#return portal.global_transform * global_portal_plane
	# Fix rotation first

	return portal.global_transform * Plane.PLANE_XY


func portal_plane_rel_body(portal: Node3D, body: PhysicsBody3D) -> Color:
	var global_plane := get_portal_plane(portal)
	var plane: Plane = -body.global_transform.inverse() * global_plane
	return Color(plane.x, plane.y, plane.z, plane.d)


func add_clip_plane(portal: Node3D, body: PhysicsBody3D) -> void:
	if body is StaticBody3D:
		return
	var plane_pos := portal_plane_rel_body(portal, body)
	for body_child in body.get_children():
		if body_child.has_method("get_surface_override_material"):
			# TODO: iterate over materials
			var material = body_child.get_surface_override_material(0)
			if material.has_method("set_shader_parameter"):
				material.set_shader_parameter("portal_plane", plane_pos)


func handle_body_overlap_portal(portal: Node3D, body: PhysicsBody3D) -> void:
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



func handle_body_exit_portal(portal: Node, body: PhysicsBody3D) -> void:
	if not body in clones:
		return
	var clone: Node = clones[body]
	if is_instance_valid(clone):
		clones.erase(body)
		clone.queue_free()

func _on_portal_a_body_entered(body: PhysicsBody3D) -> void:
	bodies[$PortalA].append(body)

func _on_portal_b_body_entered(body: PhysicsBody3D) -> void:
	bodies[$PortalB].append(body)

func _on_portal_a_body_exited(body: PhysicsBody3D) -> void:
	handle_body_exit_portal($PortalA, body)
	bodies[$PortalA].erase(body)


func _on_portal_b_body_exited(body: PhysicsBody3D) -> void:
	handle_body_exit_portal($PortalB, body)
	bodies[$PortalB].erase(body)
