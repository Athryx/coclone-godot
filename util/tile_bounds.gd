extends Reference

var min_corner: Vector2i
var max_corner: Vector2i

func _init(min_corner: Vector2i, max_corner: Vector2i):
	self.min_corner = min_corner
	self.max_corner = max_corner

func offset(size: int):
	min_corner.x -= size
	min_corner.y -= size
	max_corner.x += size
	max_corner.y += size
