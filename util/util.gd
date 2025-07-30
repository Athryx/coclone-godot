extends Object
class_name Util

const TileBounds = preload("res://util/tile_bounds.gd")

# converts a vector3 to a vector2 by projecting the vector3 to the xz plane
static func vector3_to_vector2(vector: Vector3) -> Vector2:
	return Vector2(vector.x, vector.z)

# converts a vector2 to vector3 by putting the vector2 on the xz plan
static func vector2_to_vector3(vector: Vector2) -> Vector3:
	return Vector3(vector.x, 0.0, vector.y)

static func position_to_tile_pos(position: Vector2) -> Vector2i:
	var x: int
	if position.x < 0.0:
		x = position.x as int - 1
	else:
		x = position.x as int
	
	var y: int
	if position.y < 0.0:
		y = position.y as int - 1
	else:
		y = position.y as int
	
	return Vector2i(x, y)

static func round_to_tile_pos(position: Vector2) -> Vector2:
	return Vector2(position_to_tile_pos(position))

static func tile_bounds(center: Vector2, size: float) -> TileBounds:
	var size_vec := Vector2(size, size)
	return TileBounds.new(
		position_to_tile_pos(center - size_vec),
		position_to_tile_pos(center + size_vec) + Vector2i(1, 1)
	)

static func signed_angle_between(a: Vector2, b: Vector2) -> float:
	return -atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y)

static func is_instance_of_scene(node: Node, packed_scene: PackedScene) -> bool:
	var node_scene_path = node.scene_file_path
	var packed_scene_path = packed_scene.resource_path
	return node_scene_path == packed_scene_path
