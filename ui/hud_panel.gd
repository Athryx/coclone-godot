@tool
extends Panel
class_name HudPanel

func _ready():
	var stylebox: StyleBox = get_theme_stylebox("panel", "HudPanel")
	add_theme_stylebox_override("panel", stylebox)
