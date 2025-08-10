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

static func segment_intersects_rect(start: Vector2, end: Vector2, rect: Rect2) -> bool:
	var segment_dir := end - start
	# position relative to segment
	var rect_min := rect.position - start
	var rect_max := rect_min + rect.size
	
	var min_x_intercept := rect_min.x / segment_dir.x
	var min_x_vec := min_x_intercept * segment_dir
	if min_x_intercept >= 0.0 and min_x_intercept <= 1.0 and min_x_vec.y >= rect_min.y and min_x_vec.y <= rect_max.y:
		return true
	
	var max_x_intercept := rect_max.x / segment_dir.x
	var max_x_vec := max_x_intercept * segment_dir
	if max_x_intercept >= 0.0 and max_x_intercept <= 1.0 and max_x_vec.y >= rect_min.y and max_x_vec.y <= rect_max.y:
		return true
	
	var min_y_intercept := rect_min.y / segment_dir.y
	var min_y_vec := min_y_intercept * segment_dir
	if min_y_intercept >= 0.0 and min_y_intercept <= 1.0 and min_y_vec.x >= rect_min.x and min_y_vec.x <= rect_max.x:
		return true
	
	# must check all 4 sides because start or end can be inside rectangle
	var max_y_intercept := rect_max.y /  segment_dir.y
	var max_y_vec := max_y_intercept * segment_dir
	if max_y_intercept >= 0.0 and max_y_intercept <= 1.0 and max_y_vec.x >= rect_min.x and max_y_vec.x <= rect_max.x:
		return true
	
	# check if both points are inside rectangle, which can be checked if just start is inside rectangle
	# otherwise no intersection
	return rect.has_point(start)
