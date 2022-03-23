extends Component

export(bool) var can_self_res = false
export(float) var revive_time = 5.0
var knocked = false

func _ready():
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")
	actor.connect("died", self, "_on_died")

func _on_body_entered(body):
	if (actor == body and not can_self_res) or not knocked:
		return
	else:
		if body.has_method("_get_component"):
			var inter = body._get_component("interactor")
			if inter != null:
				inter.request_interact(self, "Press E to revive", revive_time)

func _on_body_exited(body):
	if body.has_method("_get_component"):
		var inter = body._get_component("interactor")
		if inter != null:
			inter.stop_interact()
	
func _on_died():
	knocked = true
	_on_body_entered(actor)

func interaction_triggered():
	if knocked:
		actor.revive()
		knocked = false
		return true
	else:
		return false