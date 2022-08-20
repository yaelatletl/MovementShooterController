extends Spatial
onready var start = $Start
onready var end = $End

const AREA_RADIUS = 2

var interactable
var zipline_direction = Vector3.ZERO

var current_bodies = []
var linked_bodies = []
var area : Area
#little struct here:
#{
#	body: body,
#	zip_direction: Vector3,

#}

func _ready():
	area = Area.new()
	var collision = CollisionShape.new()
	var distance = start.global_transform.origin.distance_to(end.global_transform.origin)
	var angle = start.global_transform.origin.angle_to(end.global_transform.origin)
	var debug_shape = MeshInstance.new()
	zipline_direction = start.global_transform.origin.direction_to(end.global_transform.origin)
	debug_shape.mesh = CubeMesh.new()
	area.name = "PickArea"
	collision.shape = BoxShape.new()
	collision.shape.extents = Vector3(AREA_RADIUS, AREA_RADIUS, distance)/2
	debug_shape.mesh.size = collision.shape.extents*2
	area.connect("body_exited", self, "_on_body_exited")
	interactable = InteractableInterface.new()
	area.add_child(collision)
	area.add_child(debug_shape)
	interactable.add_child(area)
	add_child(interactable)
	area.global_transform.origin = start.global_transform.origin
	interactable.message = "Press E to use Zipline"
	area.translation += zipline_direction*(distance / 2)
	area.look_at(end.global_transform.origin, Vector3(0, 1, 0))
	interactable.connect("interacted_successfully", self, "_on_interacted_successfully")

func _on_interacted_successfully(body):
	if body.has_method("_get_component"):
		var struct = {}
		struct["body"] = body
		struct["zip_direction"] = body.head_basis.z.dot(zipline_direction)
		linked_bodies.append(body)
		current_bodies.append(struct)

func _on_body_exited(body):
	if not body in linked_bodies:
		return
	for phys_body in current_bodies:
		if phys_body["body"] == body:
			print(phys_body)
			_on_body_deattached(phys_body)
			

func _on_body_deattached(struct):
	for i in current_bodies.size():
		if current_bodies[i]["body"] == struct["body"]:
			if current_bodies[i]["body"] in linked_bodies:
				linked_bodies.erase(current_bodies[i]["body"])
			current_bodies.remove(i)
			break


func _physics_process(delta):
	for struct in current_bodies:
		if not area.overlaps_body(struct["body"]):
				_on_body_deattached(struct)
				return
		if struct["zip_direction"] > 0:
			if struct["body"].global_transform.origin.distance_to(start.global_transform.origin) < 1:
				_on_body_deattached(struct)
			else:
				struct["body"].linear_velocity = zipline_direction * -10 
		else:
			if struct["body"].global_transform.origin.distance_to(end.global_transform.origin) < 1:
				_on_body_deattached(struct)
			else:
				struct["body"].linear_velocity = zipline_direction * 10 
