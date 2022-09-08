extends Spatial

# Get character's node path
export(NodePath) var character

# Get head's node path
export(NodePath) var head

# Get camera's node path
export(NodePath) var neck

# Get camera's node path
export(NodePath) var camera


# All weapons
var arsenal : Dictionary

# Current weapon
remotesync var current : int = 0


func _ready() -> void:
	set_as_toplevel(true)
	
	# Get camera node from path
	camera = get_node(camera)
	
	# Get neck node from path
	neck = get_node(neck)
	
	# Get head node from path
	head = get_node(head)
	
	# Get head node from path
	character = get_node(character)
	
	# Class reference : 
	# owner, name, firerate, bullets, ammo, max_bullets, damage, reload_speed
	arsenal["ma75b"] = FormatParser.weapon_from_json("res://data/weapons/tags/ma75b.json", self)
	# Create mk 23 using weapon classs
	arsenal["mk_23"] = FormatParser.weapon_from_json("res://data/weapons/tags/mk_23.json", self)
	
	# Create glock 17 using weapon class
	arsenal["glock_17"] = FormatParser.weapon_from_json("res://data/weapons/tags/glock_17.json", self)
	# Create glock 17 using weapon class
	arsenal["shotgun"] = FormatParser.weapon_from_json("res://data/weapons/tags/shotgun.json", self)
	# Create kriss using weapon class
	arsenal["kriss"] = FormatParser.weapon_from_json("res://data/weapons/tags/kriss.json", self)
	
	arsenal["plasma"] = FormatParser.weapon_from_json("res://data/weapons/tags/plasma.json", self)

	#add actors first, then add weapons to tree, otherwise their _ready() code will break
	for w in arsenal:
		add_child(arsenal[w])
		arsenal.values()[current]._hide()

func _physics_process(_delta) -> void:
	# Call weapon function
	_weapon(_delta)
	_handle_guns()
	_change()

func _process(_delta) -> void:
	_rotation(_delta)
	_position(_delta)

remote func _shoot(_delta) -> void:
	# Call weapon function
	arsenal.values()[current]._shoot(_delta)
	Gamestate.call_on_all_clients(self, "_shoot", _delta)

remote func _reload() -> void:
	arsenal.values()[current]._reload()
	Gamestate.call_on_all_clients(self, "_reload", null)

func _weapon(_delta) -> void:
	
	arsenal.values()[current]._sprint(character.input["sprint"] or character.input["jump"], _delta)
	
	if not character.input["sprint"] or not character.direction:
		if character.input["shoot"]:
			_shoot(_delta)

		
		arsenal.values()[current]._zoom(character.input["zoom"], _delta)
	
	if character.input["reload"]:
		_reload()
	
	# Update arsenal
	for w in range(arsenal.size()):
		arsenal.values()[w]._update(_delta)

func _change() -> void:
	# change weapons
	for w in range(arsenal.size()):
		if arsenal.values()[w] != arsenal.values()[current]:
			arsenal.values()[w]._hide()
		else:
			arsenal.values()[w]._draw()

func _position(_delta) -> void:
	global_transform.origin = head.global_transform.origin
	
func  _rotation(_delta) -> void:
	var y_lerp = 40
	var x_lerp = 80
	if not character.input["zoom"]:
		var quat_a = global_transform.basis.get_rotation_quat()
		var quat_b = camera.global_transform.basis.get_rotation_quat()
		var angle_distance = quat_a.angle_to(quat_b)
		#global_transform.basis = global_transform.basis.orthonormalized()
		#global_transform.basis = global_transform.basis.slerp(Basis(quat_b), _delta*x_lerp*angle_distance)
		global_transform.basis = Basis(quat_a.slerp(quat_b, _delta*x_lerp*angle_distance))
				
	else:
		rotation = camera.global_transform.basis.get_euler()

remotesync func _change_weapon(_index) -> void:
	current = _index
	Gamestate.set_in_all_clients(self, "current", _index)

func _handle_guns():
	if character.input["next_weapon"]:
		var anim = arsenal.values()[current].anim
		if not anim.is_playing():
			if current + 1 < arsenal.size():
				_change_weapon(current + 1)
			else:
				_change_weapon(0)
