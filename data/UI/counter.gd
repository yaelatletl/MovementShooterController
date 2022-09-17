extends Label

@export var counter_node_path: NodePath = ""
@export var counter_signal_name: String = ""

@onready var counter_node = get_node(counter_node_path)

func _ready():
	counter_node.connect(counter_signal_name,Callable(self,"_on_counter_signal"))

func _on_counter_signal(counter_value: float):
	text = str(snapped(counter_value, 0.1))
