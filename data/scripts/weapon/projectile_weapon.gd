extends Weapon
class_name ProjectileWeapon
var projectile_type
var camera = null
var character = null

func set_projectile(type):
	projectile_type = type

func _shoot_cast(relative_node = "")->void:
	shoot_projectile(relative_node)
	
func shoot_projectile(separator_name = "")->void:
	var active = ray
	if separator_name != "":
		active = ray.get_node(separator_name)
	var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
	if active is Position3D or active is RayCast:
		#Handle more than one raycast 
		for child_ray in active.get_children():
			if child_ray is RayCast:
				make_projectile_shoot(child_ray.global_transform.origin, child_ray.cast_to)
	if active is RayCast:
		# Shoot form main barrel 
		make_projectile_shoot(barrel.global_transform.origin, ray.cast_to)
	
func make_projectile_shoot(origin, offset):
	if character == null:
		character = actor.get_parent()
	if camera == null:
		camera = actor.head.get_node("neck").get_node("camera")
	offset = Vector3(offset.x, offset.y, 0)
	var direction = camera.to_global(Vector3.ZERO) - camera.to_global(Vector3(0,0,100) + offset)
	# Add the projectile to the scene through pooling
	Pooling.add_projectile(projectile_type, origin, direction, character) 
