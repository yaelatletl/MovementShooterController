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
	var shotgun_spread_pattern = [
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(-1, 0),
		Vector2(0, -1),
		Vector2(-1, -1)
	]
	var mastiff_spread = [
		Vector2(-1, 0),
		Vector2(-0.5, 0),
		Vector2(0, 0),
		Vector2(0.5, 0),
		Vector2(1, 0)
	]
	
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
	
	# Create mk 23 using weapon classs
	arsenal["mk_23"] = Weapon.new(self, "mk_23", 2.0, 12, 999, 12, 40, 1.2)
	
	# Create glock 17 using weapon class
	arsenal["glock_17"] = Weapon.new(self, "glock_17", 3.0, 12, 999, 12, 35, 1.2)
	
	# Create kriss using weapon class
	arsenal["kriss"] = Weapon.new(self, "kriss", 6.0, 32, 999, 33, 25, 1.5)
	
	arsenal["shotgun"] = Weapon.new(self, "shotgun", 0.5, 8, 999, 8, 25, 0.5, true, mastiff_spread, 20)
	
	arsenal["plasma"] = ProjectileWeapon.new(self, "plasma", 2.5, 8, 999, 8, 25, 1.5, false, [], 0, 1)
	arsenal["plasma"].actor_temp = character
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
	var y_lerp = 20
	var x_lerp = 40
	if not character.input["zoom"]:
		var quat_a = global_transform.basis.get_rotation_quat()
		var quat_b = camera.global_transform.basis.get_rotation_quat()
		global_transform.basis = Basis(quat_a.slerp(quat_b, _delta*x_lerp))
#		rotation.x = lerp_angle(rotation.x, camera.global_transform.basis.get_euler().x, y_lerp * _delta)
#		rotation.y = lerp_angle(rotation.y, camera.global_transform.basis.get_euler().y, x_lerp * _delta)
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
