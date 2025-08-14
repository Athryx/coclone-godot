extends Node3D

const Map = preload("res://game_view/map.gd")

@onready var building_bar: UnitBar = $BuildingBar
@onready var map: Map = $Map
@onready var button_bar: BuildingButtonBar = $BuildingButtonBar

# currently dragged builging
var selected_building_ref: Building = null
# true if the currnelty dragged building is a placee preview
# or false if it is a placed building being dragged
var selected_preview: bool = false

func preview_building() -> Building:
	if selected_preview:
		return selected_building_ref
	else:
		return null

func selected_building() -> Building:
	if not selected_preview:
		return selected_building_ref
	else:
		return null

func _ready():
	for building in PlayerData.player.buildings:
		building_bar.add_unit(building)
	
	map.enable_valid_spawn_overlay()

func get_scene_building_butons() -> Array[BuildingButtonDescription]:
	return [
		BuildingButtonDescription.new(
			"remove",
			null,
			self.remove_building
		)
	]

func remove_building(building: Building):
	deselect_building()
	map.remove_building(building)
	building_bar.add_unit(building.get_unit_scene(), 1)
	building.queue_free()
	
	# TODO: don't regenerate this every time
	map.generate_spawn_pos_mesh()

func _on_GameArea_position_clicked(position: Vector2):
	var tile := Util.position_to_tile_pos(position)
	
	# handle case of selected unit changing
	if preview_building() != null:
		if not Util.is_instance_of_scene(preview_building(), building_bar.get_current_unit_scene()):
			deselect_building()
	
	var clicked_building := map.get_building_at(tile)
	if clicked_building != null:
		deselect_building()
		building_bar.deselect_unit()
		selected_building_ref = clicked_building
		selected_preview = false
		button_bar.set_building(selected_building_ref, get_scene_building_butons())
	elif selected_building() != null:
		deselect_building()
	
	# TODO: handle dragged building
	if preview_building() != null:
		preview_building().set_corner_position(tile)
		remove_child(preview_building())
		
		if map.add_building(preview_building()):
			# TODO: don't regenerate this every time
			map.generate_spawn_pos_mesh()
			building_bar.dec_current_unit(true)
			selected_building_ref = null
		else:
			add_child(preview_building())
	else:
		var building: Building = building_bar.get_current_unit()
		if building == null:
			return
		
		building.corner_position = tile
		
		if map.add_building(building):
			# TODO: don't regenerate this every time
			map.generate_spawn_pos_mesh()
			building_bar.dec_current_unit(true)
		else:
			building.free()

func _on_game_area_position_mouseover(position: Vector2) -> void:
	if not building_bar.is_unit_selected() and preview_building() != null:
		# if building is deselected, remove the placement preview
		deselect_building()
		return
	
	# handle case of selected unit changing
	if preview_building() != null:
		if not Util.is_instance_of_scene(preview_building(), building_bar.get_current_unit_scene()):
			deselect_building()
	
	var tile := Util.position_to_tile_pos(position)
	if selected_building_ref == null:
		selected_building_ref = building_bar.get_current_unit()
		
		# no unit in unit bar selected, return
		if selected_building_ref == null:
			return
		
		add_child(selected_building_ref)
		selected_preview = true
	
	# only drag preview buildings
	if preview_building() != null:
		preview_building().set_corner_position(tile)

func deselect_building():
	if selected_building_ref != null:
		if selected_preview:
			selected_building_ref.queue_free()
		else:
			button_bar.set_building(null)
		selected_building_ref = null

func _input(event):
	if event.is_action_pressed("deselect"):
		deselect_building()
		building_bar.deselect_unit()
