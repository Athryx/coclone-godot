extends Spatial
# game area is used in any scene that needs to view or manipulate the base
# it provides camera controls and the scenery

export var map_size := 75

signal position_clicked(position)

onready var camera = $Camera
onready var grid = $Grid

var grid_enabled := true

func _unhandled_key_input(event):
	if Input.is_action_just_pressed("togle_grid"):
		grid_enabled = !grid_enabled
		grid.visible = grid_enabled

func is_valid_position(position: Vector2) -> bool:
	var tile := Util.position_to_tile_pos(position)
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size and tile.y < map_size

func _on_GroundArea_input_event(input_camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var pos2d := Util.vector3_to_vector2(position)
		var tile := Util.position_to_tile_pos(pos2d)
		
		if is_valid_position(pos2d):
			emit_signal("position_clicked", pos2d)
	elif event is InputEventMouseMotion and grid_enabled:
		var pos2d := Util.vector3_to_vector2(position)
		var tile_pos_center := Util.round_to_tile_pos(pos2d) + Vector2(0.5, 0.5)
		
		if is_valid_position(tile_pos_center):
			var tile_pos3d := Util.vector2_to_vector3(tile_pos_center)
			var camera_direction: Vector3 = camera.camera_direction_vec()
			grid.transform.origin = tile_pos3d - 10.0 * camera_direction
			grid.visible = true
		else:
			grid.visible = false
