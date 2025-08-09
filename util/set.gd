extends RefCounted
class_name Set

var data: Dictionary

func _init():
	data = {}

func add(value: Variant) -> void:
	data[value] = null

func remove(value: Variant) -> bool:
	return data.erase(value)

func contains(value: Variant) -> bool:
	return data.has(value)

func values() -> Array:
	return data.keys()
