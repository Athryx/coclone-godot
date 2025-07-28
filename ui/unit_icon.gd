@tool
extends Panel
class_name UnitIcon

signal clicked

@export var unit: PackedScene

func set_text(text: String):
	print(text)
	$Label.text = text

func _ready():
	add_theme_stylebox_override("panel", get_theme_stylebox("panel", "UnitIcon"))
	$Button.add_theme_stylebox_override("focus", get_theme_stylebox("panel_selected", "UnitIcon"))
	
	if not Engine.is_editor_hint():
		set_text("")
		UnitPreview.get_preview_texture(unit.resource_path, self, "set_texture")

func set_texture(texture: Texture2D):
	$TextureRect.texture = texture

func _on_Button_pressed():
	emit_signal("clicked")
