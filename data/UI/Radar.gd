tool
extends ColorRect

export(Color) var background = Color.aliceblue
export(Color) var border = Color.black
export(int) var border_resolution = 360
export(int) var border_width = 1

#func _ready():
	#rect_size = get_parent().rect_size
func _process(delta):
	update()

func _draw():
	draw_circle(rect_size/2, min(rect_size.x/3, rect_size.y/3), background)
	draw_arc (rect_size/2, min(rect_size.x/3, rect_size.y/3), 0, 360, border_resolution, border, border_width, true)