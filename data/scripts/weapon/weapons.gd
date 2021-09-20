extends Node3D

# Get character's node path
@export var character_path : NodePath;

# Get head's node path
@export var head_path: NodePath;

# Get camera's node path
@export var neck_path: NodePath;

# Get camera's node path
@export var camera_path: NodePath;

# Load weapon class for make weapons
var weapon = preload("res://data/scripts/weapon/weapon.gd");

# All weapons
var arsenal : Dictionary;

# Current weapon
var current : int = 0;

	# Get camera node from path
@onready var camera:Node3D = get_node(camera_path);
	
	# Get neck node from path
@onready var neck:Node3D = get_node(neck_path);
	
	# Get head node from path
@onready var head:Node3D = get_node(head_path);
	
	# Get head node from path
@onready var character:Node3D = get_node(character_path);

func _ready() -> void:
	top_level = true;
	
	
	# Class reference : 
	# owner, name, firerate, bullets, ammo, max_bullets, damage, reload_speed;
	
	# Create mk 23 using weapon classs
	arsenal["mk_23"] = weapon.weapon.new(self, "mk_23", 2.0, 12, 999, 12, 40, 1.2);
	
	# Create glock 17 using weapon class
	arsenal["glock_17"] = weapon.weapon.new(self, "glock_17", 3.0, 12, 999, 12, 35, 1.2);
	
	# Create kriss using weapon class
	arsenal["kriss"] = weapon.weapon.new(self, "kriss", 6.0, 32, 999, 33, 25, 1.5);
	
	for w in arsenal:
		arsenal.values()[current]._hide();

func _physics_process(_delta) -> void:
	# Call weapon function
	_weapon(_delta);
	_change();
func _process(_delta) -> void:
	_rotation(_delta)
	_position(_delta);

func _weapon(_delta) -> void:
	
	arsenal.values()[current]._sprint(character.input["sprint"] or character.input["jump"], _delta);
	
	if not character.input["sprint"] or not character.direction:
		if character.input["shoot"]:
			arsenal.values()[current]._shoot(_delta);
		
		arsenal.values()[current]._zoom(character.input["zoom"], _delta);
	
	if character.input["reload"]:
		arsenal.values()[current]._reload();
	
	# Update arsenal
	for w in range(arsenal.size()):
		arsenal.values()[w]._update(_delta);

func _change() -> void:
	# change weapons
	for w in range(arsenal.size()):
		if arsenal.values()[w] != arsenal.values()[current]:
			arsenal.values()[w]._hide();
		else:
			arsenal.values()[w]._draw();

func _position(_delta) -> void:
	
	global_transform.origin = head.global_transform.origin;
	
func  _rotation(_delta) -> void:
	var y_lerp = 20;
	var x_lerp = 40;
	if not character.input["zoom"]:
		var quat_a = Quaternion(global_transform.basis)
		var quat_b = Quaternion(camera.global_transform.basis)
		global_transform.basis = Basis(quat_a.slerp(quat_b, _delta*x_lerp))
#		rotation.x = lerp_angle(rotation.x, camera.global_transform.basis.get_euler().x, y_lerp * _delta);
#		rotation.y = lerp_angle(rotation.y, camera.global_transform.basis.get_euler().y, x_lerp * _delta);
	else:
		rotation = camera.global_transform.basis.get_euler();

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			var anim = arsenal.values()[current].anim
			
			if not anim.is_playing():
				if event.scancode == KEY_1:
					current = 0;
				if event.scancode == KEY_2:
					current = 1;
				if event.scancode == KEY_3:
					current = 2;
