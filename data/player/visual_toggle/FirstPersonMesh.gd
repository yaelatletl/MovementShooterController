extends MeshInstance3D


func _ready() -> void:
	if get_tree().get_multiplayer().has_multiplayer_peer():
		if not is_multiplayer_authority():
			set_layer_mask(4)
