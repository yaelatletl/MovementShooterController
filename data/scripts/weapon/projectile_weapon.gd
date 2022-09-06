extends Weapon
class_name ProjectileWeapon
var projectile_type
var actor_temp
var camera = null

func set_projectile(type):
	projectile_type = type

func setup_spread(spread_pattern, spread_multiplier) -> void:
	var ray = actor.get_node("{}/ray".format([gun_name], "{}"))
	var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
	camera = actor.head.get_node("neck").get_node("camera")
	for point in spread_pattern:
		var new_cast = RayCast.new()
		ray.add_child(new_cast)
		new_cast.global_transform.origin = barrel.global_transform.origin 
		new_cast.translation.y += point.y
		new_cast.translation.x += point.x
		new_cast.enabled = true
		new_cast.cast_to.x = point.x * spread_multiplier 
		new_cast.cast_to.y = point.y * spread_multiplier 
		new_cast.cast_to.z = -200

func _shoot_cast()->void:
	shoot_projectile()
	
func shoot_projectile()->void:
	if camera == null:
		camera = actor.head.get_node("neck").get_node("camera")
	var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
	if ray is Position3D:
		#Handle more than one raycast 
		for child_ray in ray.get_children():
			if child_ray is RayCast:
				# Get raycast range
				var origin = child_ray.global_transform.origin + child_ray.to_global(child_ray.cast_to).normalized()/2
				Pooling.add_projectile(projectile_type, origin, child_ray.to_global(child_ray.cast_to), actor_temp)
				# Check raycast is colliding
	elif ray is RayCast:
		var direction = camera.to_global(Vector3.ZERO) - camera.to_global(Vector3(0,0,100))
		# Get raycast range
		Pooling.add_projectile(projectile_type, barrel.global_transform.origin, direction, actor_temp) #direction was ray.get_parent().to_global(ray.cast_to)
		print("origin: ", barrel.global_transform.origin, "global from parent: ", ray.get_parent().to_global(ray.cast_to), "global from ray: ", ray.to_global(ray.cast_to))
		print("ray info: CAST TO: ", ray.cast_to, "ORIGIN (Global, local): ", ray.global_transform.origin, ray.translation)
		
	
