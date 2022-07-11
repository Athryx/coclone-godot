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
	return Vector2i.new(position.x as float, position.y as float)

static func round_to_tile_pos(position: Vector2) -> Vector2:
	return position_to_tile_pos(position).to_vector2()

static func tile_bounds(center: Vector2, size: float) -> TileBounds:
	var size_vec := Vector2(size, size)
	return TileBounds.new(
		position_to_tile_pos(center - size_vec),
		Vector2im.add(position_to_tile_pos(center + size_vec), Vector2i.new(1, 1))
	)
