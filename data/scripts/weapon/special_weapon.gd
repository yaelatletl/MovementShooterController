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
	TOGGLE_SPREAD,
	SECONDARY_FIRE,
	TOGGLE_SETTINGS,
	ZOOM_TOGGLE_SETTINGS
}

var right_click_mode = FUNCTION_MODE.ZOOM

var primary_fire_mode = FIRE_MODE.RAYCAST
var secondary_fire_mode = FIRE_MODE.PROJECTILE

var secondary_firerate = 0
var secondary_bullets = 0
var secondary_ammo = 0
var secondary_max_bullets = 0
var secondary_damage = 0
var secondary_reload_speed = 0
var secondary_use_randomness = false
var secondary_projectile_type = 0
var secondary_spread_pattern = []
var secondary_spread_multiplier = 0
var secondary_max_range = 0
var secondary_max_random_spread_x = 0
var secondary_max_random_spread_y = 0

var uses_separate_ammo = true
var switch = false

func _ready() -> void:
	super._ready()
	setup_spread(secondary_spread_pattern, secondary_spread_multiplier, secondary_max_range, "secondary")
func _physics_process(delta):
	if character == null:
		return
	if character.input["zoom"] and right_click_mode == FUNCTION_MODE.ZOOM_TOGGLE_SETTINGS:
		switch = true
	elif right_click_mode == FUNCTION_MODE.ZOOM_TOGGLE_SETTINGS:
		switch = false

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

func _zoom(input, _delta) -> void:
	if input:
		match right_click_mode:
			FUNCTION_MODE.ZOOM:
				make_zoom(input, _delta)
			FUNCTION_MODE.TOGGLE_SPREAD:
				pass
			FUNCTION_MODE.SECONDARY_FIRE:
				secondary_fire(_delta)
			FUNCTION_MODE.TOGGLE_SETTINGS:
				switch = not switch
			FUNCTION_MODE.ZOOM_TOGGLE_SETTINGS:
				make_zoom(input, _delta)
			FUNCTION_MODE.TOGGLE_SPREAD:
				switch = not switch
				
func secondary_fire(delta) -> void:
	if uses_separate_ammo:
		_shoot(self, delta, secondary_bullets, secondary_max_bullets, secondary_ammo, secondary_reload_speed, secondary_firerate, "secondary", "secondary_ammo", "secondary_bullets", false)
	else:
		_shoot(self, delta, bullets, max_bullets, ammo, secondary_reload_speed, secondary_firerate, "secondary", "ammo", "bullets", false)

func _shoot_cast(relative_node = "")-> void:


	if relative_node == "secondary" or (right_click_mode != FUNCTION_MODE.TOGGLE_SPREAD and switch):
		match secondary_fire_mode:
			FIRE_MODE.RAYCAST:
				shoot_raycast(secondary_use_randomness, secondary_max_random_spread_x, secondary_max_random_spread_y, secondary_max_range, relative_node)
			FIRE_MODE.PROJECTILE:
				shoot_projectile(relative_node)
			FIRE_MODE.AREA:
				pass
	else:
		if right_click_mode == FUNCTION_MODE.TOGGLE_SPREAD and switch:
			relative_node = "secondary"
		match primary_fire_mode:
			FIRE_MODE.RAYCAST:
				shoot_raycast(uses_randomness, max_random_spread_x, max_random_spread_y, max_range, relative_node)
			FIRE_MODE.PROJECTILE:
				shoot_projectile()
			FIRE_MODE.AREA:
				pass

func secondary_reload() -> void:
	if uses_separate_ammo:
		_reload(self, secondary_bullets, secondary_max_bullets, secondary_ammo, "secondary_ammo", "secondary_bullets", secondary_reload_speed) 
	else:
		_reload(self, bullets, max_bullets, ammo, "ammo", "bullets", secondary_reload_speed) 
