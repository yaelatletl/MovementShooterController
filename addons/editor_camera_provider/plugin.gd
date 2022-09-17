@tool
extends EditorPlugin

var _camera: Camera3D


func _enter_tree() -> void:
	var path = self.get_script().get_path()
	add_autoload_singleton("EditorCameraProvider", path)
	set_input_event_forwarding_always_enabled()


# warning-ignore:unused_argument
func handles(obj: Object) -> bool:
    return true


# warning-ignore:unused_argument
func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> bool:
	_camera = camera
	return false


func get_camera_3d() -> Camera3D:
	return _camera
