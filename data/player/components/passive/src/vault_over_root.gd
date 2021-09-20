extends Node3D


@export var movement_path: NodePath
@onready var character: Node3D = get_parent()
@onready var height_cast: RayCast3D = $vault_over
@onready var forward_cast: RayCast3D = $vault_over2
@onready var movement: Node = get_node(movement_path)

var on_ledge = false
var jump_over = false


func _ready():
	height_cast.add_exception(character)
	pass # Replace with function body.


func _physics_process(delta):
	rotation.y = character.head.rotation.y
	if height_cast.is_colliding() and not on_ledge:
		if height_cast.get_collider() is StaticBody3D and character.run_speed < 12:
			on_ledge = true
	if on_ledge and character.is_far_from_floor():
		character.velocity = -character.wall_direction*2
		character.velocity.y += movement.gravity*delta
		if jump_over:
			character.velocity += (-character.wall_direction + Vector3(0,1.5,0)) * 10
	else:
		jump_over = false
		on_ledge = false
	if character.input["crouch"] and on_ledge:
		on_ledge = false
		character.velocity = character.wall_direction*2
	elif character.input["jump"] and on_ledge:
		jump_over = true
