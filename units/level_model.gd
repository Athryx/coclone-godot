extends Node3D
class_name LevelModel

@export_dir var models_folder: String
@export var level: int = 1
@export var connection: String = NO_CONNECTION

# different names for different connection types
const NO_CONNECTION := ""
const CONNECTION1 := "_1"
const CONNECTION2_STRAIGHT := "_straight2"
const CONNECTION2_CORNER := "_corner2"
const CONNECTION3 := "_3"
const CONNECTION4 := "_4"

var model: Node3D = null

func _ready():
	load_model()

func set_level(new_level: int):
	level = new_level
	load_model()

func set_connection(connection: String):
	self.connection = connection
	load_model()

func load_model():
	# get rid of old model
	if model != null:
		model.queue_free()
	
	var model_path = "%s/lvl%d%s.glb" % [models_folder, level, connection]
	print(model_path)
	model = load(model_path).instantiate()
	add_child(model)
