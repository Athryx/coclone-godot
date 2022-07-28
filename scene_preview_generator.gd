extends Node

export(Array, PackedScene) var preview_scenes = []

onready var viewport: Viewport = $Viewport
onready var camera: Camera = $Viewport/Camera

# map from integer ids to textures
var textures = {}

var waiting_callbacks = {}

func generate_textures():
	var base_cam_height: float = camera.transform.origin.y
	
	for scene in preview_scenes:
		var instance = scene.instance()
		camera.transform.origin.y = base_cam_height + instance.aim_pos_height
		camera.size = instance.preview_size
		
		viewport.add_child(instance)
		
		yield(VisualServer, "frame_post_draw")
		
		var image = Image.new()
		image.copy_from(viewport.get_texture().get_data())
		
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		textures[scene.resource_path] = texture
		
		if waiting_callbacks.has(scene.resource_path):
			for callback in waiting_callbacks[scene.resource_path]:
				callback["callback_obj"].call(callback["callback_func"], texture)
			waiting_callbacks.erase(scene.resource_path)
		
		viewport.remove_child(instance)
		instance.queue_free()
	
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED

func _ready():
	generate_textures()

func get_preview_texture(scene_path: String, callback_obj, callback_func: String):
	if textures.has(scene_path):
		callback_obj.call(callback_func, textures[scene_path])
	else:
		var callbacks: Array
		
		if waiting_callbacks.has(scene_path):
			callbacks = waiting_callbacks[scene_path]
		else:
			callbacks = []
			waiting_callbacks[scene_path] = callbacks
		
		callbacks.push_back({
			callback_obj = callback_obj,
			callback_func = callback_func,
		})
