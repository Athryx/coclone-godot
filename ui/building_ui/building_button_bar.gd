extends HBoxContainer
class_name BuildingButtonBar

var building: Building

func set_building(building: Building, scene_buttons: Array[BuildingButtonDescription] = []):
	for child in get_children():
		child.queue_free()
	
	self.building = building
	
	if building != null:
		for button in scene_buttons:
			add_button(button)
		
		for button in building.get_buttons():
			add_button(button)

func add_button(description: BuildingButtonDescription):
	var button := preload("res://ui/building_ui/building_button.tscn").instantiate()
	button.label = description.label
	button.icon = description.icon
	button.clicked.connect(Callable(self._on_building_button_clicked).bind(description))
	add_child(button)

func _on_building_button_clicked(description: BuildingButtonDescription):
	description.action.call(building)
