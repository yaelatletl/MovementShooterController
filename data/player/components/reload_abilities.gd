extends Component

export(Array) var abilities = [] #Add nodes here
export(Array) var charge_meters = [] #Must be equal or lesser than abilites
# We need to get timers for every ultimate, tactical and 
# passive abilities, whether they use them or not

func get_safe(arr : Array, idx : int):
	if idx < arr.size():
		return arr[idx]
	else:
		return ""

func _ready():
	for i in max(abilities.size(), charge_meters.size()):
		var node = get_node(get_safe(abilities, i))
		var bar  = get_node(get_safe(charge_meters, i))
		if node != null:
			register_ability(node, bar)
		else:
			printerr("The element in abilites is not a Node, instead found ", node)

func register_ability(node : Node, bar : Control):
	if node.has_method("setup_charge"):
		node.connect("charging_changed", self, "_on_charging_changed", [node, bar])
	pass

func _on_charging_changed(charge : float, node : Node, bar : Control):
	if bar != null:
		bar.value = charge/node.charging_max * 100
