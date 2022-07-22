extends Reference
class_name Vector2i
# vector2 with integer coordinates
# NOTE: godot 4 has built in Vector2i, so this would not be necessary

var x := 0
var y := 0

func _init(x: int, y: int):
	self.x = x
	self.y = y

func to_string():
	return "(%d, %d)" % [x, y]

func to_vector2() -> Vector2:
	return Vector2(x as float, y as float)

func equals(other) -> bool:
	return x == other.x and y == other.y
