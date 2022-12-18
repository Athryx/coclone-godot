extends Spatial

const Map = preload("res://map.gd")

onready var building_bar: UnitBar = $BuildingBar
onready var map: Map = $Map

func _ready():
	for building in PlayerData.player.buildings:
		building_bar.add_unit(building)
	
	map.enable_valid_spawn_overlay()

func _on_GameArea_position_clicked(position):
	var building = building_bar.get_current_unit()
	if building == null:
		return
	
	var tile = Util.position_to_tile_pos(position)
	
	building.corner_position = tile
	
	if map.add_building(building):
		# TODO: don't regenerate this every time
		map.generate_spawn_pos_mesh()
		building_bar.dec_current_unit()
	else:
		building.free()
