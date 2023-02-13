extends VehicleBody3D
#Six wheel drive vehicle body
#This is a vehicle body that has six wheels, two checked the front and four checked the back.

@onready var front_left_wheel = $front_left 
@onready var front_right_wheel = $front_right
@onready var back_left_wheel = $back_left
@onready var back_right_wheel = $back_right
@onready var back_left_wheel2 = $middle_left
@onready var back_right_wheel2 = $middle_right


func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
