extends Node

var projectiles_active = []
var projectiles_waiting = []

var projectiles = {
	1: preload("res://data/weapons/PlasmaBolt.tscn"),
}

var projectiles_root 

func setup_projectile_root(root):
	projectiles_root = root

func add_projectile(projectile_type,translation, direction):
	var found = null
	var projectile_instance = null
	for bullet in projectiles_waiting:
		if bullet.type == projectile_type:
			found = bullet
			break
	if found == null:
		projectile_instance = projectiles[projectile_type].instance()
		projectile_instance.connect("request_destroy", self, "_on_projectile_request_destroy", [projectile_instance])
	else:
		projectiles_waiting.erase(found)
		projectile_instance = found
	projectiles_active.append(projectile_instance)
	projectiles_root.add_child(projectile_instance)
	projectile_instance.move(translation, direction)


func _on_projectile_request_destroy(projectile):
	projectiles_active.erase(projectile)
	if projectile.is_inside_tree():
		projectiles_root.remove_child(projectile)
		projectiles_waiting.append(projectile)

