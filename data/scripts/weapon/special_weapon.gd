extends ProjectileWeapon
class_name SpecialWeapon
#Modes for the second click
enum FIRE_MODE{
	AREA, #For meele
	RAYCAST, 
	PROJECTILE
}
enum FUNCTION_MODE{
	ZOOM, 
	SPREAD_TOGGLE,
	SECONDARY_FIRE
}

var right_click_mode = FUNCTION_MODE.ZOOM

var primary_fire_mode = FIRE_MODE.RAYCAST
var secondary_fire_mode = FIRE_MODE.PROJECTILE


var secondary_firerate = 0
remote var secondary_bullets = 0
remote var secondary_ammo = 0
var secondary_max_bullets = 0
var secondary_damage = 0
var secondary_reload_speed = 0
var secondary_use_randomness = false
var secondary_projectile_type = 0
var secondary_spread_pattern = []
var secondary_spread_multiplier = 0
var secondary_max_range = 0

func _init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed , use_randomness = false, spread_pattern = [], spread_multiplier = 0.0, projectile = 0).(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier) -> void:
	._init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier)
	projectile_type = projectile
	
func _ready() -> void:
	._ready()
	setup_secondary_spread(secondary_spread_pattern, secondary_spread_multiplier)

func setup_secondary_fire(mode, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier, projectile) -> void:
	projectile_type = projectile
	secondary_fire_mode = mode
	secondary_projectile_type = int(projectile)
	secondary_spread_pattern = spread_pattern
	secondary_spread_multiplier = spread_multiplier
	secondary_firerate = firerate
	secondary_bullets = bullets
	secondary_ammo = ammo
	secondary_max_bullets = max_bullets
	secondary_damage = damage
	secondary_reload_speed = reload_speed
	secondary_use_randomness = use_randomness


func setup_secondary_spread(spread_pattern, spread_multiplier) -> void:
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
		new_cast.cast_to.z = -secondary_max_range


func _zoom(input, _delta) -> void:
	if input:
		match right_click_mode:
			FUNCTION_MODE.ZOOM:
				make_zoom(input, _delta)
			FUNCTION_MODE.SPREAD_TOGGLE:
				pass
			FUNCTION_MODE.SECONDARY_FIRE:
				_secondary_shoot(_delta,secondary_fire_mode)
			
var secondary_shooting = false
func _secondary_shoot(_delta, mode):
	if not check_relatives():
		return

	if secondary_bullets > 0:
		# Play shoot animation if not reloading
		if secondary_shooting != true and animc != "Reload" and animc != "Draw" and animc != "Hide":
			secondary_bullets -= 1
			Gamestate.set_in_all_clients(self, "secondary_bullets", secondary_bullets)
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
			
			#anim.play("Shoot", 0, secondary_firerate)
	
			# Get raycast weapon range
			match mode:
				FIRE_MODE.AREA:
					#shoot_area()
					pass
				FIRE_MODE.RAYCAST:
					shoot_raycast()
				FIRE_MODE.PROJECTILE:
					shoot_projectile()
			secondary_shooting = true
			# Play shoot animation using firate speed
			yield(get_tree().create_timer(1/secondary_firerate), "timeout")
			secondary_shooting = false
	else:
		# Play out sound
		if not audio.get_node("out").playing:
			audio.get_node("out").pitch_scale = rand_range(0.9, 1.1)
			audio.get_node("out").play()
		_secondary_reload()


func _shoot_cast()-> void:
	match primary_fire_mode:
		FIRE_MODE.RAYCAST:
			shoot_raycast()
		FIRE_MODE.PROJECTILE:
			shoot_projectile()
		FIRE_MODE.AREA:
			pass

func _secondary_reload() -> void:
	if not check_relatives():
		return
	if secondary_bullets < secondary_max_bullets and secondary_ammo > 0:
		if animc != "Reload" and animc != "Shoot" and animc != "Draw" and animc != "Hide":
			# Play reload animation
			anim.play("Reload", 0.2, secondary_reload_speed)
			
			for b in secondary_ammo:
				secondary_bullets += 1
				secondary_ammo -= 1
				
				if secondary_bullets >= secondary_max_bullets:
					break
			Gamestate.set_in_all_clients(self, "secondary_ammo", secondary_ammo)
