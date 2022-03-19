extends Node

var projectiles_active = []
var projectiles_waiting = []

var projectiles = {
	1: preload("res://data/weapons/PlasmaBolt.tscn"),
}

var projectiles_root 

func setup_projectile_root(root):
	projectiles_root = root

func add_projectile(projectile_type, translation, direction):
	var projectile_instance = projectiles[projectile_type].instance()
	projectile_instance.translation = translation
	projectiles_root.add_child(projectile_instance)
	projectile_instance.connect("request_destroy", self, "_on_projectile_request_destroy", [projectile_instance])
	projectiles_active.append(projectile_instance)

	if projectile_instance is RigidBody:
		projectile_instance.apply_central_impulse(direction)	

func _on_projectile_request_destroy(projectile):
	projectiles_active.remove(projectile)
	projectiles_root.remove_child(projectile)
	projectiles_waiting.append(projectile)

