extends Node3D

const Map = preload("res://game_view/map.gd")

@onready var building_bar: UnitBar = $BuildingBar
@onready var map: Map = $Map

# currently dragged builging
var selected_building: Building = null
# false if the currnelty dragged building is a placee preview
# or true if it is a building being dragged
var building_placed: bool = false

func _ready():
	for building in PlayerData.player.buildings:
		building_bar.add_unit(building)
	
	map.enable_valid_spawn_overlay()

func _on_GameArea_position_clicked(position: Vector2):
	var tile := Util.position_to_tile_pos(position)
	
	# TODO: handle dragged building
	if selected_building != null:
		selected_building.set_corner_position(tile)
		
		if map.add_building(selected_building):
			# TODO: don't regenerate this every time
			map.generate_spawn_pos_mesh()
			building_bar.dec_current_unit()
			selected_building = null
	else:
		var building: Building = building_bar.get_current_unit()
		if building == null:
			return
		
		building.corner_position = tile
		
		if map.add_building(building):
			# TODO: don't regenerate this every time
			map.generate_spawn_pos_mesh()
			building_bar.dec_current_unit()
		else:
			building.free()

func _on_game_area_position_mouseover(position: Vector2) -> void:
	if not building_bar.is_unit_selected():
		# if building is deselected, remove the placement preview
		deselect_building()
		
		return
	
	var tile := Util.position_to_tile_pos(position)
	if selected_building == null:
		selected_building = building_bar.get_current_unit()
		add_child(selected_building)
	
	selected_building.set_corner_position(tile)

func deselect_building():
	if selected_building != null:
		selected_building.queue_free()
		selected_building = null

func _input(event):
	if event.is_action_pressed("deselect"):
		deselect_building()
		building_bar.deselect_unit()
