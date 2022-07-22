extends Object
class_name Vector2im
# various methods for vector2i

static func add(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i.new(a.x + b.x, a.y + b.y)

static func sub(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i.new(a.x - b.x, a.y - b.y)

static func min(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i.new(min(a.x, b.x), min(a.y, b.y))

static func max(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i.new(max(a.x, b.x), max(a.y, b.y))
