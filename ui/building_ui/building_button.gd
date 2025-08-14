extends HudPanel
class_name BuildingButton

signal clicked

var label: String
var icon: Image

func update():
	print($Label)
	$Label.text = label
	$TextureRect.texture = ImageTexture.create_from_image(icon)

func _ready():
	super._ready()
	update()

func _on_button_pressed() -> void:
	emit_signal("clicked")
