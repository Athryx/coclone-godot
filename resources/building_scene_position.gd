extends Resource
class_name BuildingScenePosition

@export var building_scene: PackedScene
@export var position: Vector2i

static func new(building_scene: PackedScene, position: Vector2i) -> BuildingScenePosition:
	var out := BuildingScenePosition.new()
	out.building_scene = building_scene
	out.position = position
	return out

func instantiate() -> Building:
	var out: Building = self.building_scene.instantiate()
	out.corner_position = position
	return out
