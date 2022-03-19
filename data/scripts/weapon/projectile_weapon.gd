extends weapon
var projectile 
func _init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed , use_randomness = false, spread_pattern = [], spread_multiplier = 0.0, projectile = null).(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier) -> void:
	._init(actor, gun_name, firerate, bullets, ammo, max_bullets, damage, reload_speed, use_randomness, spread_pattern, spread_multiplier)
	self.projectile = projectile

func _shoot_cast()->void:
	