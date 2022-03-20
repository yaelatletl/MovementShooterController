extends Weapon
class_name ProjectileWeapon
var projectile_type
var actor_temp

func _init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed , use_randomness = false, spread_pattern = [], spread_multiplier = 0.0, projectile = 0).(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier) -> void:
	._init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier)
	projectile_type = projectile
	

func setup_spread(spread_pattern, spread_multiplier) -> void:
	var ray = actor.get_node("{}/ray".format([gun_name], "{}"))
	var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
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
	var ray = actor.get_node("{}/ray".format([gun_name], "{}"))
	var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
	if ray is Position3D:
		#Handle more than one raycast 
		for child_ray in ray.get_children():
			if child_ray is RayCast:
				# Get raycast range
				var origin = child_ray.global_transform.origin + child_ray.to_global(child_ray.cast_to).normalized()/2
				Pooling.add_projectile(projectile_type, barrel.global_transform.origin, child_ray.to_global(child_ray.cast_to), actor_temp)
				# Check raycast is colliding
	elif ray is RayCast:
		# Get raycast range
		Pooling.add_projectile(projectile_type, barrel.global_transform.origin, ray.to_global(ray.cast_to), actor_temp)
		
	
