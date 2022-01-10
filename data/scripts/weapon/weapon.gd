extends Node
class_name weapon
var firerate : float
var actor : Node
var gun_name : String
remote var bullets : int
remote var ammo : int
var max_bullets : int
var damage : int
var reload_speed : float
var default_fov : int = 100
func _init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed) -> void:
		self.actor = actor
		self.gun_name = gun_name
		self.firerate = firerate
		self.bullets = bullets
		self.ammo = ammo
		self.max_bullets = max_bullets
		self.damage = damage
		self.reload_speed = reload_speed
	
# Get animation node
var anim = actor.get_node("{}/mesh/anim".format([gun_name], "{}"))
	
# Get current animation
var animc = anim.current_animation
	
# Get animation node
var mesh = actor.get_node("{}".format([gun_name], "{}"))

	
func _draw() -> void:
		# Check is visible
		if not mesh.visible:
			# Play draw animaton
			anim.play("Draw")
	
func _hide() -> void:
		# Check is visible
		if mesh.visible:
			# Play hide animaton
			anim.play("Hide")
	
func _sprint(sprint, _delta) -> void:
		if not is_instance_valid(actor):
			return
		if sprint and actor.character.direction:
			mesh.rotation.x = lerp(mesh.rotation.x, -deg2rad(40), 5 * _delta)
		else:
			mesh.rotation.x = lerp(mesh.rotation.x, 0, 5 * _delta)
	
func _shoot(_delta) -> void:
		# Get audio node
		var audio = actor.get_node("{}/audio".format([gun_name], "{}"))
		
		# Get effects node
		var effect = actor.get_node("{}/effect".format([gun_name], "{}"))
		
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
				
				# Get barrel node
				var barrel = actor.get_node("{}/barrel".format([gun_name], "{}"))
				
				# Get main scene
				var main = actor.get_tree().get_root().get_child(0)
				
				# Create a instance of trail scene
				var trail = preload("res://data/scenes/trail.tscn").instance()
				
				# Change trail position to out of barrel position
				trail.translation = barrel.global_transform.origin
				
				# Change trail rotation to camera rotation
				trail.rotation = actor.camera.global_transform.basis.get_euler()
				
				# Add the trail to main scene
				main.add_child(trail)
				
				# Get raycast weapon range
				var ray = actor.get_node("{}/ray".format([gun_name], "{}"))
				
				# Check raycast is colliding
				if ray.is_colliding():
					var local_damage = int(rand_range(damage/1.5, damage))
					
					# Do damage
					if ray.get_collider() is RigidBody:
						ray.get_collider().apply_central_impulse(-ray.get_collision_normal() * (local_damage * 0.3))
					
					if ray.get_collider().is_in_group("prop"):
						if ray.get_collider().is_in_group("metal"):
							var spark = preload("res://data/scenes/spark.tscn").instance()
							
							# Add spark scene in collider
							ray.get_collider().add_child(spark)
								
							# Change spark position to collider position
							spark.global_transform.origin = ray.get_collision_point()
							
							spark.emitting = true
						
					if ray.get_collider().has_method("_damage"):
						ray.get_collider()._damage(local_damage)
					
					# Create a instance of decal scene
					var decal = preload("res://data/scenes/decal.tscn").instance()
					
					# Add decal scene in collider
					ray.get_collider().add_child(decal)
					
					# Change decal position to collider position
					decal.global_transform.origin = ray.get_collision_point()
					
					# decal spins to collider normal
					decal.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3(1, 1, 0))
		else:
			# Play out sound
			if not audio.get_node("out").playing:
				audio.get_node("out").pitch_scale = rand_range(0.9, 1.1)
				audio.get_node("out").play()

func _reload() -> void:
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
		if not is_instance_valid(actor):
			return
		var lerp_speed : int = 30
		var camera = actor.camera
		
		if input and animc != "Reload" and animc != "Hide" and animc != "Draw":
			camera.fov = lerp(camera.fov, default_fov-30, lerp_speed * _delta)
			mesh.translation.y = lerp(mesh.translation.y, 0.001, lerp_speed * _delta)
			mesh.translation.x = lerp(mesh.translation.x, -0.088, lerp_speed * _delta)
		else:
			camera.fov = lerp(camera.fov, default_fov, lerp_speed * _delta)
			mesh.translation.y = lerp(mesh.translation.y, 0, lerp_speed * _delta)
			mesh.translation.x = lerp(mesh.translation.x, 0, lerp_speed * _delta)
	
func _update(_delta) -> void:
		if not is_instance_valid(actor):
			return
		if animc != "Shoot":
			if actor.arsenal.values()[actor.current] == self:
				actor.camera.rotation.x = lerp(actor.camera.rotation.x, 0, 10 * _delta)
				actor.camera.rotation.y = lerp(actor.camera.rotation.y, 0, 10 * _delta)
		
		# Get current animation
		animc = anim.current_animation
		
		# Get effect node
		var effect = actor.get_node("{}/effect".format([gun_name], "{}"))
		
		# Change light energy
		effect.get_node("shoot").light_energy = lerp(effect.get_node("shoot").light_energy, 0, 5 * _delta)
		
		# Remove recoil
		mesh.rotation.x = lerp(mesh.rotation.x, 0, 5 * _delta)
