extends Spatial

const gunner = preload("res://troops/gunner.tscn")

onready var map = $Map
onready var camera = $Camera
onready var grid = $Grid

var grid_enabled := true

func _unhandled_key_input(event):
	if Input.is_action_just_pressed("togle_grid"):
		grid_enabled = !grid_enabled
		grid.visible = grid_enabled

func _on_GroundArea_input_event(input_camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var pos2d := Util.vector3_to_vector2(position)
		
		if map.is_valid_spawn_pos(pos2d):
			var troop := gunner.instance()
			map.spawn_troop(pos2d, troop)
		else:
			map.show_valid_spawn_overlay()
		
	elif event is InputEventMouseMotion and grid_enabled:
		var pos2d := Util.vector3_to_vector2(position)
		var tile_pos_center := Util.round_to_tile_pos(pos2d) + Vector2(0.5, 0.5)
		
		if map.is_valid_map_pos(tile_pos_center):
			var tile_pos3d := Util.vector2_to_vector3(tile_pos_center)
			var camera_direction: Vector3 = camera.camera_direction_vec()
			grid.transform.origin = tile_pos3d - 10.0 * camera_direction
			grid.visible = true
		else:
			grid.visible = false
