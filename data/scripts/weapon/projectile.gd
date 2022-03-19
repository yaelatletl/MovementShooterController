extends RigidBody
class_name Projectile

export(float) var type : int = 0
export(float) var damage : int = 0
export(float) var speed : int = 0
export(Vector3) var direction : Vector3 = Vector3(0, 0, 0)

var shooter_id : int = 0

signal request_destroy()

func _init(type: int, damage: int, speed: float, direction: Vector3) -> void:
	self.type = type
	self.damage = damage
	self.speed = speed
	self.direction = direction

func _ready() -> void:
	connect("body_entered", self, "on_body_entered")

func on_body_entered(body) -> void:
	if body.has_method("_damage"):
		body._damage(damage)
		emit_signal("request_destroy")

func network_sync() -> void:
	Gamestate.set_in_all_clients(self, "translation", translation)