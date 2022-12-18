extends Resource
class_name BaseLayout

const BuildingScenePosition = preload("res://buildings/building_scene_position.gd")

export(Array, Dictionary) var buildings := []

func add_building(building: BuildingScenePosition):
	buildings.push_back({
		building = building.building_scene,
		x = building.position.x,
		y = building.position.y,
	})

# returns an array of BuildingScenePositions for each building
func get_buildings() -> Array:
	var out := []
	
	for building in buildings:
		out.push_back(BuildingScenePosition.new(
			building["building"],
			Vector2i.new(building["x"], building["y"])
		))
	
	return out