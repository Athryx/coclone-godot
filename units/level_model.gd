extends Node3D
class_name LevelModel

@export_dir var models_folder: String
@export var level: int = 1

func _ready():
	print(level)
	load_model()

func set_level(new_level: int):
	level = level
	load_model()

func load_model():
	var model_path = "%s/lvl%d.glb" % [models_folder, level]
	print(model_path)
	add_child(load(model_path).instantiate())
