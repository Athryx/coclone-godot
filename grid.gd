extends MultiMeshInstance

export var grid_size := 11
export var grid_opacity_fallof := 0.7

func _ready():
	material_override.set_shader_param("opacity_fallof", grid_opacity_fallof)
	
	multimesh.instance_count = grid_size * grid_size
	
	var half_grid_size := grid_size as float / 2.0
	
	for x in grid_size:
		var xpos := x as float - half_grid_size + 0.5
		
		for z in grid_size:
			var zpos := z as float - half_grid_size + 0.5
			var index: int = z + x * grid_size
			
			var pos := Vector3(xpos, 0.0, zpos)
			var instance_transform := Transform(Basis(), pos)
			multimesh.set_instance_transform(index, instance_transform)
