extends Object
class_name Vector2im
# various methods for vector2i

static func add(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i.new(a.x + b.x, a.y + b.y)
