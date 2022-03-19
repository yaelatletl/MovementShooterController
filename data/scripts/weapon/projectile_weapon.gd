extends Weapon
class_name ProjectileWeapon
var projectile_type

func _init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed , use_randomness = false, spread_pattern = [], spread_multiplier = 0.0, projectile = 0).(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier) -> void:
	._init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier)
	projectile_type = projectile

func _shoot_cast()->void:
	var ray = actor.get_node("{}/ray".format([gun_name], "{}"))
	var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
	if ray is Position3D:
		#Handle more than one raycast 
		for child_ray in ray.get_children():
			if child_ray is RayCast:
				# Get raycast range
				Pooling.add_projectile(projectile_type, child_ray.to_global(child_ray.cast_to), barrel.global_transform.origin)
				# Check raycast is colliding
	elif ray is RayCast:
		# Get raycast range
		Pooling.add_projectile(projectile_type, ray.to_global(ray.cast_to), barrel.global_transform.origin)
		
	
