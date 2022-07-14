extends Spatial

export var pan_sensitivity := 1.0
export var rotate_sensitivity := 0.03

export var zoom_sensitivity := 1.0

export var min_zoom := 3.0
export var max_zoom := 40.0

onready var camera = $Camera

func _physics_process(delta):
	if Input.is_action_pressed("cam_forward"):
		translate_object_local(Vector3(0.0, 0.0, -pan_sensitivity))

	if Input.is_action_pressed("cam_backward"):
		translate_object_local(Vector3(0.0, 0.0, pan_sensitivity))
	
	if Input.is_action_pressed("cam_left"):
		translate_object_local(Vector3(-pan_sensitivity, 0.0, 0.0))

	if Input.is_action_pressed("cam_right"):
		translate_object_local(Vector3(pan_sensitivity, 0.0, 0.0))
	
	if Input.is_action_pressed("cam_rotate_left"):
		rotate_y(rotate_sensitivity)
	
	if Input.is_action_pressed("cam_rotate_right"):
		rotate_y(-rotate_sensitivity)
	
	if Input.is_action_pressed("cam_zoom_in"):
		camera.size = max(camera.size - zoom_sensitivity, min_zoom)
	
	if Input.is_action_pressed("cam_zoom_out"):
		camera.size = min(camera.size + zoom_sensitivity, max_zoom)

func camera_direction_vec() -> Vector3:
	return camera.project_ray_normal(Vector2(0.0, 0.0))
