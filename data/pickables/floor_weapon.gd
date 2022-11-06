extends InteractableGeneric
export(bool) var oneshot = true #Set this to false to achieve an "armory" asset
export(String, FILE, "*.json") var weapon_archetype = ""

func _ready():
	message = "Press E to pick up the " + name

func interaction_triggered(interactor_body : Spatial):
	print("Interacting with " + name)
	if interactor_body.has_method("_get_component"):
		if interactor_body._get_component("weapons"):
			var weapon = interactor_body._get_component("weapons")
			weapon.add_weapon(name, weapon_archetype)
		if oneshot:
			queue_free()
