extends Node

enum DAMAGE_TYPE {
	KINECTIC, 
	ENERGY, 
	SLOWING,
	FIRE,
	EXPLOSIVE 
} 

var projectiles_active = []
var projectiles_waiting = []

var projectiles = {
	1: load("res://data/weapons/PlasmaBolt.tscn"),
	2: load("res://data/weapons/Grenade.tscn"),
}

var projectiles_root 

func setup_projectile_root(root):
	projectiles_root = get_tree().get_root()

func add_projectile(projectile_type,position, direction, actor):
#	print("Position passed to add_projectile: " + position)
	var found = null
	var projectile_instance = null
	for bullet in projectiles_waiting:
		if bullet.type == projectile_type:
			found = bullet
			break
	if found == null:
		projectile_instance = projectiles[projectile_type].instantiate()
		projectile_instance.set_as_top_level(true)
		projectile_instance.connect("request_destroy",Callable(self,"_on_projectile_request_destroy").bind(projectile_instance))
	else:
		projectiles_waiting.erase(found)
		projectile_instance = found
		projectile_instance.sleeping = false
	projectile_instance.add_exceptions(actor)
	projectiles_active.append(projectile_instance)
	projectiles_root.add_child(projectile_instance)
	projectile_instance.move(position, direction)


func _on_projectile_request_destroy(projectile):
	projectiles_active.erase(projectile)
	if projectile.is_inside_tree():
		projectile.sleeping = true
		projectile.linear_velocity = Vector3(0,0,0)
		projectiles_root.remove_child(projectile)
		projectiles_waiting.append(projectile)

