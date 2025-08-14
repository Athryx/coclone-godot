extends RefCounted
class_name BuildingButtonDescription

var label: String
var icon: Image
var action: Callable

func _init(label: String, icon: Image, action: Callable):
	self.label = label
	self.icon = icon
	self.action = action
