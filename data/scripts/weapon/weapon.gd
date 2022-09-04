extends Node
class_name Weapon

var spark = preload("res://data/scenes/spark.tscn")
var trail = preload("res://data/scenes/trail.tscn")
var decal = preload("res://data/scenes/decal.tscn")
var firerate : float
var actor : Node = null
var gun_name : String
remote var bullets : int
remote var ammo : int
var max_bullets : int
var damage : int
var reload_speed : float
var default_fov : int = 100
var zoom_fov : int = 40
var uses_randomness : bool = false
	
var max_range : int = 200
var spread_pattern : Array = []
var spread_multiplier : float = 0

	
# Get effect node
var effect = null
var anim = null
var animc = null
var mesh = null	
var ray = null
var audio = null

func _init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed , use_randomness = false, spread_pattern = [], spread_multiplier = 0.0) -> void:
	self.actor = actor
	self.gun_name = gun_name
	self.firerate = firerate
	self.bullets = bullets
	self.ammo = ammo
	self.max_bullets = max_bullets
	self.damage = damage
	self.reload_speed = reload_speed
	self.uses_randomness = bool(use_randomness)
	self.spread_pattern = spread_pattern
	self.spread_multiplier = spread_multiplier
	if self.uses_randomness:
		print("RANDOM")
		randomize()

func _ready():
	if actor == null:
		printerr("actor must be set before adding to scene")
		return
	update_actor_relatives(actor)

func check_relatives() -> bool:
	if actor == null:
		return false
	if anim == null:
		return false
	if animc == null:
		return false
	if mesh == null:	
		return false
	if effect == null:
		return false
	if ray == null:
		return false
	if audio == null:
		return false
	return true

func update_actor_relatives(actor) -> void:
	# Get animation node
	anim = actor.get_node("{}/mesh/anim".format([gun_name], "{}"))
	mesh = actor.get_node("{}".format([gun_name], "{}"))
	effect = actor.get_node("{}/effect".format([gun_name], "{}"))
	
	# Get current animation
	animc = anim.current_animation
	
	ray = actor.get_node("{}/ray".format([gun_name], "{}"))
	audio = actor.get_node("{}/audio".format([gun_name], "{}"))
	if spread_pattern.size() > 0:
		setup_spread(spread_pattern, spread_multiplier)


func setup_spread(spread_pattern, spread_multiplier) -> void:
	if ray is RayCast:
		ray.cast_to.z = -max_range
	for point in spread_pattern:
		var new_cast = RayCast.new()
		new_cast.enabled = true
		new_cast.cast_to.x = point.x * spread_multiplier 
		new_cast.cast_to.y = point.y * spread_multiplier 
		new_cast.cast_to.z = -max_range
		ray.add_child(new_cast)

func _draw() -> void:
	if not check_relatives():
		return
	# Check is visible
	if not mesh.visible:
		# Play draw animaton
		anim.play("Draw")
	
func _hide() -> void:
	if not check_relatives():
		return
	# Check is visible
	if mesh.visible:
		# Play hide animaton
		anim.play("Hide")
	
func _sprint(sprint, _delta) -> void:
	if not check_relatives():
		return
	if sprint and actor.character.direction:
		mesh.rotation.x = lerp(mesh.rotation.x, -deg2rad(40), 5 * _delta)
	else:
		mesh.rotation.x = lerp(mesh.rotation.x, 0, 5 * _delta)

func _shoot_cast() -> void: #Implemented as a virtual method, so that it can be overriden by child classes
	shoot_raycast()

func shoot_raycast() -> void:
	if not check_relatives():
		return
	if ray is Position3D:
		#Handle more than one raycast 
		for child_ray in ray.get_children():
			if child_ray is RayCast:
				# Get raycast range
				make_ray_shoot(child_ray)
							
				# Check raycast is colliding
	elif ray is RayCast:
		# Get raycast range
		make_ray_shoot(ray)

func _shoot(_delta) -> void:
	if not check_relatives():
		return

	if bullets > 0:
		# Play shoot animation if not reloading
		if animc != "Shoot" and animc != "Reload" and animc != "Draw" and animc != "Hide":
			bullets -= 1
			Gamestate.set_in_all_clients(self, "bullets", bullets)
			# recoil
			actor.camera.rotation.x = lerp(actor.camera.rotation.x, rand_range(1, 2), _delta)
			actor.camera.rotation.y = lerp(actor.camera.rotation.y, rand_range(-1, 1), _delta)
			
			# Shake the camera
			actor.camera.shake_force = 0.002
			actor.camera.shake_time = 0.2
			
			# Change light energy
			effect.get_node("shoot").light_energy = 2
			
			# Emitt fire particles
			effect.get_node("fire").emitting = true
			
			# Emitt smoke particles
			effect.get_node("smoke").emitting = true
			
			# Play shoot sound
			audio.get_node("shoot").pitch_scale = rand_range(0.9, 1.1)
			audio.get_node("shoot").play()
			
			# Play shoot animation using firate speed
			anim.play("Shoot", 0, firerate)
			
			
			
			
			# Get raycast weapon range
			_shoot_cast()
	else:
		# Play out sound
		if not audio.get_node("out").playing:
			audio.get_node("out").pitch_scale = rand_range(0.9, 1.1)
			audio.get_node("out").play()

func make_ray_shoot(ray : RayCast):
	if not check_relatives():
		return
	var original_cast_to = ray.cast_to
	if uses_randomness:
		ray.cast_to.x = rand_range(-ray.cast_to.z/2, ray.cast_to.z/2)
		ray.cast_to.y = rand_range(-ray.cast_to.z/2, ray.cast_to.z/2)
		ray.cast_to.z = -200
	print(ray.cast_to)
	if ray.is_colliding():
		# Get barrel node
		var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
		# Get main scene
		var main = actor.get_tree().get_root().get_child(0)
				
		# Create a instance of trail scene
		var local_trail = trail.instance()
		#local_trail.set_as_toplevel(true)
		# Change trail position to out of barrel position
		local_trail.global_transform.origin = barrel.global_transform.origin
		
		# Change trail rotation to camera rotation
		#local_trail.rotation = actor.camera.global_transform.basis.get_euler()
		local_trail.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3(1, 1, 0))
		#local_trail.look_at(ray.get_collision_point(), actor.camera.global_transform.basis.y)
		#local_trail.global_rotation = actor.camera.global_transform.origin.direction_to(ray.to_global(ray.cast_to))
		# Add the trail to main scene
		main.add_child(local_trail)
		var local_damage = int(rand_range(damage/1.5, damage))
		
		# Do damage
		if ray.get_collider() is RigidBody:
			ray.get_collider().apply_central_impulse(-ray.get_collision_normal() * (local_damage * 0.3))
		
		if ray.get_collider().is_in_group("prop"):
			if ray.get_collider().is_in_group("metal"):
				var local_spark = spark.instance()
				
				# Add spark scene in collider
				ray.get_collider().add_child(local_spark)
					
				# Change spark position to collider position
				local_spark.global_transform.origin = ray.get_collision_point()
				
				local_spark.emitting = true
			
		if ray.get_collider().has_method("_damage"):
			ray.get_collider()._damage(local_damage)
		
		# Create a instance of decal scene
		var local_decal = decal.instance()
		
		# Add decal scene in collider
		ray.get_collider().add_child(local_decal)
		
		# Change decal position to collider position
		local_decal.global_transform.origin = ray.get_collision_point()
		
		# decal spins to collider normal
		local_decal.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3(1, 1, 0))
	#ray.cast_to = original_cast_to

func _reload() -> void:
	if not check_relatives():
		return
	if bullets < max_bullets and ammo > 0:
		if animc != "Reload" and animc != "Shoot" and animc != "Draw" and animc != "Hide":
			# Play reload animation
			anim.play("Reload", 0.2, reload_speed)
			
			for b in ammo:
				bullets += 1
				ammo -= 1
				
				if bullets >= max_bullets:
					break
			Gamestate.set_in_all_clients(self, "ammo", ammo)

func _zoom(input, _delta) -> void:
	make_zoom(input, _delta)

func make_zoom(input, _delta) -> void:
	if not check_relatives():
		return
	var lerp_speed : int = 30
	var camera = actor.camera
	
	if input and animc != "Reload" and animc != "Hide" and animc != "Draw":
		camera.fov = lerp(camera.fov, zoom_fov, lerp_speed * _delta)
		mesh.translation.y = lerp(mesh.translation.y, 0.001, lerp_speed * _delta)
		mesh.translation.x = lerp(mesh.translation.x, -0.088, lerp_speed * _delta)
	else:
		camera.fov = lerp(camera.fov, default_fov, lerp_speed * _delta)
		mesh.translation.y = lerp(mesh.translation.y, 0, lerp_speed * _delta)
		mesh.translation.x = lerp(mesh.translation.x, 0, lerp_speed * _delta)
	
func _update(_delta) -> void:
	if not check_relatives():
		return
	if animc != "Shoot":
		if actor.arsenal.values()[actor.current] == self:
			actor.camera.rotation.x = lerp(actor.camera.rotation.x, 0, 10 * _delta)
			actor.camera.rotation.y = lerp(actor.camera.rotation.y, 0, 10 * _delta)
	
	# Get current animation
	animc = anim.current_animation
	
	# Change light energy
	effect.get_node("shoot").light_energy = lerp(effect.get_node("shoot").light_energy, 0, 5 * _delta)
	
	# Remove recoil
	mesh.rotation.x = lerp(mesh.rotation.x, 0, 5 * _delta)
