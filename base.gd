extends Spatial

const gunner = preload("res://troops/gunner.tscn")

onready var map = $Map

func _on_GroundArea_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var pos2d := Util.vector3_to_vector2(position)
		
		if map.is_valid_map_pos(pos2d):
			var troop := gunner.instance()
			map.spawn_troop(pos2d, troop)
