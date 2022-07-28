tool
extends Panel
class_name HudPanel

func _ready():
	var stylebox: StyleBox = get_stylebox("panel", "HudPanel")
	add_stylebox_override("panel", stylebox)
