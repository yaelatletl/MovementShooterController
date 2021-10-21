extends KinematicBody

const SLIDE_MULT = 3
const WALLRUN_MULT = 1.7

export(NodePath) var head_path = ""
export(NodePath) var feet_path = ""
export(float) var mass = 45

# All vectors
var velocity     : = Vector3(); # Velocity vector
var direction    : = Vector3(); # Direction Vector
var acceleration : = Vector3(); # Acceleration Vector
var head_basis : Basis

# All character inputs
sync var input : Dictionary = {};

#Wall running and shared variables
var wall_direction : Vector3 = Vector3.ZERO
var wall_normal 
var run_speed : float = 0.0
var wall_multiplier : float = 1.5
var multiplier : float = 1.5

var components : Dictionary = {};
var angle 
onready var head = get_node(head_path)
onready var feet = get_node(feet_path)

func _get_component(_name:String) -> Node:
	if components.has(_name):
		return components.get(_name)
	else:
		return null

func _register_component(_name : String, _component_self : Node) -> void:
	if components.has(_name):
		printerr("The Actor ", self, " already has a component ", _name)
	else:
		components[_name] = _component_self

func _physics_process(delta):
	
	head_basis = head.global_transform.basis
	if is_on_wall():
		wall_normal = get_slide_collision(0)
		yield(get_tree().create_timer(0.2), "timeout")
		wall_direction = wall_normal.normal
	run_speed = Vector2(velocity.x, velocity.z).length()

	if get_tree().network_peer != null and is_network_master() and not get_tree().is_network_server(): 
		rset_unreliable_id(1, "input", input)
		
func reset_wall_multi():
	wall_multiplier = WALLRUN_MULT

func reset_slide_multi():
	multiplier = SLIDE_MULT

	
func is_far_from_floor() -> bool:
	if feet.is_colliding():
		return false
	return true
