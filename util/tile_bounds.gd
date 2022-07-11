extends Node

var min_corner: Vector2i
var max_corner: Vector2i

func _init(min_corner: Vector2i, max_corner: Vector2i):
	self.min_corner = min_corner
	self.max_corner = max_corner
