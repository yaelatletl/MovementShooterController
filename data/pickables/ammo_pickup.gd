extends Node
class_name AmmoPickup

onready var area : Area = $PickupArea
export(String) var weapon_name = ""
export(int) var ammo = 0

func _ready() -> void:
	area.connect("body_entered", self, "_on_area_body_entered")

func _on_area_body_entered(body) -> void:
	if body.has_method("_get_component"):
		var wep = body._get_component("weapons")
		if wep:
			wep.add_ammo(weapon_name, ammo)
			