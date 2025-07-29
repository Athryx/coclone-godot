extends RefCounted

var building_scene: PackedScene
var position: Vector2i

func _init(building_scene: PackedScene, position: Vector2i):
	self.building_scene = building_scene
	self.position = position

func instantiate() -> Building:
	var out: Building = self.building_scene.instantiate()
	out.corner_position = position
	return out
