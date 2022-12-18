extends Reference

var min_corner: Vector2i
var max_corner: Vector2i

func _init(min_corner: Vector2i, max_corner: Vector2i):
	assert(min_corner.x <= max_corner.x and min_corner.y <= max_corner.y)
	self.min_corner = Vector2im.clone(min_corner)
	self.max_corner = Vector2im.clone(max_corner)

func offset(size: int):
	min_corner.x -= size
	min_corner.y -= size
	max_corner.x += size
	max_corner.y += size

func xrange() -> Array:
	return range(self.min_corner.x, self.max_corner.x)

func yrange() -> Array:
	return range(self.min_corner.y, self.max_corner.y)
