extends Component

const MAX_STEPS = 20000

var move_vec = Vector3()
var y_velo = 0
var needs_reset = false
# RL related variables
onready var end_position = $"../EndPosition"
onready var raycast_sensor = $"RayCastSensor3D"
onready var first_jump_pad = $"../Pads/FirstPad"
onready var second_jump_pad = $"../Pads/SecondPad"
onready var robot = $Robot

var is_trainging : bool = true
var next = 1
var done = false
var just_reached_end = false
var just_reached_next = false
var just_fell_off = false
var best_goal_distance := 10000.0
var grounded := false
var _heuristic := "player"
var move_action := 0.0
var turn_action := 0.0
var jump_action := false
var n_steps = 0
var _goal_vec = null
var reward = 0.0
var initial_snapshot = {}

func record_initial_parameters() -> void:
	initial_snapshot["actor"] = actor
	initial_snapshot["transform"] = actor.transform
	
func reset_initial_parameters() -> void:
	actor = initial_snapshot["actor"] 
	actor.linear_velocity = Vector3.ZERO
	actor.transform = initial_snapshot["transform"]

func toggle_training() -> void:
	is_trainging = not is_trainging

func reset():
	needs_reset = false
	next = 1
	n_steps = 0
	#first_jump_pad.translation = Vector3.ZERO
	#second_jump_pad.translation = Vector3(0,0,-12)
	just_reached_end = false
	just_fell_off = false
	jump_action = false
	# Replace with function body.
	reset_initial_parameters()
	reset_best_goal_distance()
		
func _physics_process(_delta):
		
	#reward = 0.0
	n_steps +=1	
	if n_steps >= MAX_STEPS:
		done = true
		needs_reset = true

	if needs_reset:
		needs_reset = false
		reset()
		return
		
		
	move_vec *= 0
	move_vec = get_move_vec()
	#move_vec = move_vec.normalized()
	move_vec = move_vec.rotated(Vector3(0, 1, 0), actor.rotation.y)
	move_vec.y = y_velo
		
	# turning
		
	var turn_vec = get_turn_vec()
	actor.rotation_degrees.y += turn_vec
 
	grounded = actor.is_on_floor()


	var just_jumped = false
	if grounded and get_jump_action():
		#robot.set_animation("jump-up-cycle")
		just_jumped = true

	#if actor.linear_velocity.y < 0 and !grounded :
	#	robot.set_animation("falling-cycle")
		
	var horizontal_speed = Vector2(move_vec.x, move_vec.z)
	#if horizontal_speed.length() < 0.1 and grounded:
	#	robot.set_animation("idle")
	#elif horizontal_speed.length() < 1.0 and grounded:
	#	robot.set_animation("walk-cycle")	
	#elif horizontal_speed.length() >= 1.0 and grounded:
	#	robot.set_animation("run-cycle")
		
	update_reward()
		
	if actor.input["use"]:
		reset()
		
func get_turn_vec() -> float:
	if _heuristic == "model":
		return turn_action
	var rotation_amount = actor.input["look_x"]

	return rotation_amount

func get_jump_action() -> bool:
	if done:
		jump_action = false
		return jump_action
		
	if _heuristic == "model":
		return jump_action  
	
	return actor.input["jump"]

func set_action(action):
	move_action = action["move"][0]
	turn_action = action["turn"][0]
	jump_action = action["jump"] == 1
		
func reset_if_done():
	if done:
		reset()

func get_obs():
	var goal_distance = 0.0
	var goal_vector = Vector3.ZERO
	#if next == 0:
	#	goal_distance = translation.distance_to(first_jump_pad.translation)
	#	goal_vector = (first_jump_pad.translation - translation).normalized()
		
	#if next == 1:
	#	goal_distance = translation.distance_to(second_jump_pad.translation)
	#	goal_vector = (second_jump_pad.translation - translation).normalized()
		
	goal_vector = goal_vector.rotated(Vector3.UP, -deg2rad(actor.rotation_degrees.y))
		
	goal_distance = clamp(goal_distance, 0.0, 20.0)
	var obs = []
	obs.append_array([move_vec.x,
					  move_vec.y,
					  move_vec.z])
	obs.append_array([goal_distance/20.0,
					  goal_vector.x, 
					  goal_vector.y, 
					  goal_vector.z])
	obs.append(grounded)
	obs.append_array(raycast_sensor.get_observation())
		
	return {
		"obs": obs,
	   }
		
func get_obs_space():
	# typs of obs space: box, discrete, repeated
	return {
		"obs": {
			"size": [len(get_obs()["obs"])],
			"space": "box"
		   }
	   }
		
func update_reward():
	reward -= 0.01 # step penalty
	reward += shaping_reward()
		
func get_reward():
	var current_reward = reward
	reward = 0 # reset the reward to zero on every decision step
	return current_reward
		
func shaping_reward():
	var s_reward = 0.0
	var goal_distance = 0
	#if next == 0:
	#	goal_distance = translation.distance_to(first_jump_pad.translation)
	#if next == 1:
	#	goal_distance = translation.distance_to(second_jump_pad.translation)
	#print(goal_distance)
	if goal_distance < best_goal_distance:
		s_reward += best_goal_distance - goal_distance
		best_goal_distance = goal_distance
		
	s_reward /= 1.0
	return s_reward   

func reset_best_goal_distance():
	#if next == 0:
	#	best_goal_distance = translation.distance_to(first_jump_pad.translation)
	#if next == 1:
	#	best_goal_distance = translation.distance_to(second_jump_pad.translation)	
	return 0

func set_heuristic(heuristic):
	self._heuristic = heuristic

func get_obs_size():
	return len(get_obs())
		
func zero_reward():
	reward = 0
   
func get_action_space():
	return {
		"move" : {
			"size": 1,
			"action_type": "continuous"
		   },		
		"turn" : {
			"size": 1,
			"action_type": "continuous"
		   },
		"jump": {
			"size": 2,
			"action_type": "discrete"
		   }
	   }

func get_done():
	return done
		
func set_done_false():
	done = false

func calculate_translation(other_pad_translation : Vector3) -> Vector3:
	var new_translation := Vector3.ZERO
	var distance = rand_range(12,16)
	var angle = rand_range(-180,180)
	new_translation.z = other_pad_translation.z + sin(deg2rad(angle))*distance 
	new_translation.x = other_pad_translation.x + cos(deg2rad(angle))*distance
		
	return new_translation


func get_move_vec() -> Vector3:
	if done:
		move_vec = Vector3.ZERO
		return move_vec
	
	if _heuristic == "model":
		return Vector3(
		0,
		0,
		clamp(move_action, -1.0, 0.5)
	)
		
	var move_vec := Vector3(
		clamp(actor.input["left"] - actor.input["right"],-1.0, 0.5),
		clamp(int(actor.input["crouch"]) - int(actor.input["jump"]),-1.0, 0.5),
		clamp(actor.input["back"] - actor.input["forward"],-1.0, 0.5)
		
	)
	return move_vec


func _ready():
	record_initial_parameters()
	#Input.set_use_accumulated_input(false)
	_component_name = "input"
	actor.input["look_y"] = 0
	actor.input["look_x"] = 0
	actor.input["special"] = 0
	actor.input["left"]   = 0
	actor.input["right"]  = 0
	actor.input["forward"] = 0
	actor.input["back"]   = 0
	actor.input["jump"] = 0
	actor.input["extra_jump"] = 0
	actor.input["use"] = 0
	actor.input["crouch"] = 0
	actor.input["sprint"] = 0
	actor.input["next_weapon"] = 0
	actor.input["shoot"] = int(Input.is_action_pressed("mb_left"))
	actor.input["reload"] = int(Input.is_action_pressed("KEY_R"))
	actor.input["zoom"] = int(Input.is_action_pressed("mb_right"))
	get_tree().create_timer(0.01).connect("timeout", self, "functional_routine")


func functional_routine():
	if get_tree().has_network_peer():
		if not is_network_master() or not enabled:
			return
		else:
			get_input()
			get_tree().create_timer(0.01).connect("timeout", self, "functional_routine")
	else:
		get_input()
		get_tree().create_timer(0.01).connect("timeout", self, "functional_routine")

		
func get_input():
	actor.input["left"]   = int(Input.is_action_pressed("KEY_A"))
	actor.input["right"]  = int(Input.is_action_pressed("KEY_D"))
	actor.input["forward"] = int(Input.is_action_pressed("KEY_W"))
	actor.input["back"]   = int(Input.is_action_pressed("KEY_S"))
	actor.input["next_weapon"] = int(Input.is_action_just_pressed("NEXT_GUN"))
	actor.input["crouch"] = int(Input.is_action_pressed("KEY_CTRL"))
	actor.input["sprint"] = int(Input.is_action_pressed("KEY_SHIFT"))
	actor.input["use"] = int(Input.is_action_pressed("USE"))
	actor.input["shoot"] = int(Input.is_action_pressed("mb_left"))
	actor.input["reload"] = int(Input.is_action_pressed("KEY_R"))
	actor.input["zoom"] = int(Input.is_action_pressed("mb_right"))
	actor.input["special"] = int(Input.is_action_just_pressed("SPECIAL"))
	actor.input["extra_jump"] = int(Input.is_action_pressed("KEY_SPACE"))
	actor.input["use"] = int(Input.is_action_pressed("USE"))
	sync_input()
#Let's sync the input each 10 ms, for that, we will create a pseudo-thread


func sync_input():
	if get_tree().has_network_peer():
		if is_network_master() and not get_tree().is_network_server(): 
			actor.rset_unreliable_id(1, "input", actor.input)
			Gamestate.set_in_all_clients(actor, "input", actor.input)



func _jump():
	actor.input["jump"] = true
	yield(get_tree().create_timer(0.01), "timeout")
	actor.input["jump"] = false

func mouse_move(event):
	Input.get_last_mouse_speed()
	if event is InputEventMouseMotion:
		actor.input["look_y"] = event.relative.y 
		actor.input["look_x"] = event.relative.x 
		yield(get_tree().create_timer(0.001), "timeout") # Replace timer with a tenth of a frame quantum (From new singleton)
		actor.input["look_y"] = 0
		actor.input["look_x"] = 0


func _unhandled_input(event):
	if get_tree().has_network_peer():
		if not is_network_master() or not enabled:
			return
		else:
			unhandled(event)
	else:
		unhandled(event)

func unhandled(event):
	# Calls function to switch between locked and unlocked mouse
	
	if int(Input.is_action_just_pressed("KEY_SPACE")):
		_jump()
	mouse_move(event)
	

	
