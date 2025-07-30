extends Sprite3D
class_name HealthBar

@export var height := 20
@export var width := 300
@export var start_hidden := true

func _ready():
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	set_filled(1.0)
	if start_hidden:
		hide()

# from 0 - 1 indicating how filled bar should be
func set_filled(amount: float):
	var image := Image.new()
	image.crop(width, height)
	var filled_rect := Rect2i(0, 0, amount * width, height)
	image.fill(Color(0.0, 0.0, 0.0))
	image.fill_rect(filled_rect, Color(0.0, 1.0, 0.0))
	var texture := ImageTexture.create_from_image(image)
	self.texture = texture

func set_health(max_health: int, current_health: int):
	if max_health == current_health or current_health == 0:
		hide()
	else:
		show()
		set_filled(float(current_health) / float(max_health))
