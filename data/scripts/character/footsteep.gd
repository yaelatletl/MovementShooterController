extends Node3D

@export var feet_path: NodePath
@export var character_path: NodePath
@export var movement_path: NodePath

@onready var character : Node = get_node(character_path)
@onready var feet : Node = get_node(feet_path)
@onready var movement : Node = get_node(movement_path)

var footsteep_timer : float = 0
var footsteep_speed : float = 0.5
var footsteep_list : Dictionary = {}

var dont_repeat : int = 0

func _ready() -> void:
	randomize()
	
	
	for audio in get_child_count():
		footsteep_list[get_child(audio).name] = get_child(audio)

func _process(_delta) -> void:
	if footsteep_timer <= 0:
		if character.direction:
			if feet.is_colliding():
				var collider = feet.get_collider()
				var groups = collider.get_groups()
				
				for g in groups:
					if footsteep_list.has(g):
						var footsteep_node = footsteep_list[g]
						
						if footsteep_node.get_child_count() > 0:
							var audio = randi() % footsteep_node.get_child_count()
							
							footsteep_node.get_child(audio).play()
							
							footsteep_timer = 1 - (0.06 * movement.n_speed)
							break
	else:
		footsteep_timer -= _delta
