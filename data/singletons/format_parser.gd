# This class provides static methods for creating in-game objects 
# using json descriptions.
extends Node
class_name FormatParser

static func parse_spread_pattern(pattern) -> Array:
	var result = []
	for pair in pattern:
		result.append(Vector2(pair[0], pair[1]))
	return result

static func weapon_from_json( path : String ) -> Weapon: 
	var result = null
	var file : File = File.new()
	var temp = file.open(path, File.READ)
	var json : JSONParseResult= JSON.parse(file.get_as_text())
	file.close()
	var data = json.result
	if data is Dictionary:
		var type = int(data.type) # 0 = melee, 1 = raycast, 2 = projectile 
		match type:
			0:
				pass
			1:
				result = Weapon.new(
					null, 
					data.name, 
					data.fireRate, 
					data.bullets, 
					data.ammo, 
					data.maxBullets, 
					data.damage, 
					data.reloadSpeed, 
					bool(data.randomness), 
					parse_spread_pattern(data.spreadPattern), 
					data.spreadMultiplier) 
			2:
				result = ProjectileWeapon.new(
					null, 
					data.name, 
					data.fireRate, 
					data.bullets, 
					data.ammo, 
					data.maxBullets, 
					data.damage, 
					data.reloadSpeed, 
					bool(data.randomness), 
					parse_spread_pattern(data.spreadPattern), 
					data.spreadMultiplier,
					int(data.projectileIndex)) 
			3:
				result = SpecialWeapon.new(
					null, 
					data.name, 
					data.fireRate, 
					data.bullets, 
					data.ammo, 
					data.maxBullets, 
					data.damage, 
					data.reloadSpeed, 
					bool(data.randomness), 
					parse_spread_pattern(data.spreadPattern), 
					data.spreadMultiplier,
					int(data.projectileIndex))
				result.setup_secondary_fire(
					int(data.secondaryFireMode),
					data.secondaryFireRate, 
					data.secondaryBullets, 
					data.secondaryAmmo, 
					data.secondaryMaxBullets, 
					data.secondaryDamage, 
					data.secondaryReloadSpeed, 
					bool(data.secondaryRandomness), 
					parse_spread_pattern(data.secondarySpreadPattern), 
					data.secondarySpreadMultiplier,
					int(data.secondaryProjectileIndex))
				result.right_click_mode = int(data.specialType)
				result.primary_fire_mode = int(data.primaryFireMode)	
				result.secondary_max_range = int(data.secondaryRange)
		result.zoom_fov = data.defaultZoomFOV
		result.max_range = data.range

	


	return result
