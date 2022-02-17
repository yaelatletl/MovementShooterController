extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

var input_path_mapping := {
	'/root/Main/ServerPlayer': 1,
	'/root/Main/ClientPlayer': 2,
}

enum HeaderFlags {
	HAS_INPUT_VECTOR = 0x01,
}

var input_path_mapping_reverse := {}
func _ready():
	Gamestate.serializer = self
func update_node_mapping(path, add = true):
	if add:
		input_path_mapping[path] = input_path_mapping.size() + 1
		input_path_mapping_reverse[input_path_mapping.size()] = path
	else:
		input_path_mapping_reverse.erase(input_path_mapping[path])
		input_path_mapping.erase(path)

func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key

func serialize_input(all_input: Dictionary) -> PoolByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)
	print(all_input)
	buffer.put_u32(all_input['$'])

	buffer.put_u8(all_input.size() - 1)
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])
		
		var header := 0
		
		var input = all_input[path]
		if input.has('look_flag'):
			header |= HeaderFlags.HAS_INPUT_VECTOR
		
		buffer.put_u8(header)
		
		if input.has('input_vector'):
			var input_vector: Vector2 = input['input_vector']
			buffer.put_float(input_vector.x)
			buffer.put_float(input_vector.y)
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PoolByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input := {}
	
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	if input_count == 0:
		return all_input
	
	var path = input_path_mapping_reverse[buffer.get_u8()]
	var input := {}
	
	var header = buffer.get_u8()
	if header & HeaderFlags.HAS_INPUT_VECTOR:
		input["input_vector"] = Vector2(buffer.get_float(), buffer.get_float())
		input["look_y"] = 0
		input["look_x"] = 0
		input["special"] = 0
		input["left"]   = 0
		input["right"]  = 0
		input["forward"] = 0
		input["back"]   = 0
		input["jump"] = 0
		input["extra_jump"] = 0
		input["crouch"] = 0
		input["sprint"] = 0
		input["next_weapon"] = 0
		input["shoot"] = int(Input.is_action_pressed("mb_left"))
		input["reload"] = int(Input.is_action_pressed("KEY_R"))
		input["zoom"] = int(Input.is_action_pressed("mb_right"))
	all_input[path] = input
	return all_input
