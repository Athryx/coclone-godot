extends Spatial

export var map_size := 75

export var map_edge_width := 3

const Building = preload("res://buildings/building.gd")
const TargetMode = Building.TargetMode

const BuildingRangeMap = preload("res://buildings/building_range_map.gd")

class TileBuildingDist:
	var distance: float
	var building: Building
	
	func _init(distance: float, building: Building):
		self.distance = distance
		self.building = building
	
	# used for binary search ordering
	func compare(a: TileBuildingDist, b: TileBuildingDist) -> bool:
		return a.distance < b.distance

const TileBounds = preload("res://util/tile_bounds.gd")

# a 3d array, with the first 2 dimensions being for each tile
# the 3rd dimension is an array of TileBuildingDists, which say how far the buulding is from the center of that tile
# this is used for determining what buildings a unit will target
var building_dist_map := []

func generate_building_dist_map():
	var buildings := get_tree().get_nodes_in_group("buildings")
	
	for x in map_size:
		var building_dist_row := []
		
		for y in map_size:
			var current_tile_array := []
			
			var tile_pos := Vector2(x as float + 0.5, y as float + 0.5)
			
			for building in buildings:
				if building.target_mode != TargetMode.ALWAYS:
					continue
				
				var tile_building_dist := TileBuildingDist.new(
					building.target_dist(tile_pos),
					building
				)
				
				var index: int = current_tile_array.bsearch_custom(
					tile_building_dist,
					tile_building_dist,
					"compare"
				)
				
				current_tile_array.insert(index, tile_building_dist)
			
			building_dist_row.push_back(current_tile_array)
		
		building_dist_map.push_back(building_dist_row)

var building_range_map: BuildingRangeMap

# a 2d array of numbers for each tile
# a nonzero number means a unit can't be spawned on the tile
var spawn_pos_map := []

onready var spawn_pos_mesh_node = $SpawnZoneMesh
onready var spawn_pos_mesh = $SpawnZoneMesh.multimesh

func generate_spawn_pos_map():
	var buildings := get_tree().get_nodes_in_group("buildings")
	
	for x in map_size:
		spawn_pos_map.push_back([])
		for y in map_size:
			spawn_pos_map[x].push_back(0)
	
	for building in buildings:
		var tile_bounds = building.spawn_box_bounds()
		if tile_bounds == null:
			continue
		
		clamp_tile_bounds(tile_bounds)
		for x in range(tile_bounds.min_corner.x, tile_bounds.max_corner.x):
			for y in range(tile_bounds.min_corner.y, tile_bounds.max_corner.y):
				spawn_pos_map[x][y] += 1
	
	# generate the outline mesh
	# have to collect them in a separate array before setting the up the multimesh
	var mesh_transforms := []
	
	for x in map_size:
		for y in map_size:
			var tile = Vector2i.new(x, y)
			
			if not is_valid_spawn_tile(Vector2i.new(x, y)):
				var tiles = [Vector2i.new(x - 1, y), Vector2i.new(x, y - 1)]
				
				if is_valid_spawn_tile(Vector2i.new(x - 1, y)):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(tile, -PI / 2.0)
					)
				
				if is_valid_spawn_tile(Vector2i.new(x, y - 1)):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(tile, 0.0)
					)
				
				var pos_x_tile := Vector2i.new(x + 1, y)
				if is_valid_spawn_tile(pos_x_tile):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(pos_x_tile, -PI / 2.0)
					)
				
				var pos_y_tile := Vector2i.new(x, y + 1)
				if is_valid_spawn_tile(pos_y_tile):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(pos_y_tile, 0.0)
					)
	
	spawn_pos_mesh.instance_count = mesh_transforms.size()
	for i in mesh_transforms.size():
		spawn_pos_mesh.set_instance_transform(i, mesh_transforms[i])

func get_spawn_mesh_transform(position: Vector2i, rotation: float) -> Transform:
	return Transform(
		Basis(Vector3(0.0, 1.0, 0.0), rotation),
		Util.vector2_to_vector3(position.to_vector2())
	)

func clamp_tile_bounds(tile_bounds: TileBounds):
	tile_bounds.min_corner = Vector2im.max(tile_bounds.min_corner, Vector2i.new(0, 0))
	tile_bounds.max_corner = Vector2im.min(tile_bounds.max_corner, Vector2i.new(map_size, map_size))

func _ready():
	generate_building_dist_map()
	building_range_map = BuildingRangeMap.new(get_tree().get_nodes_in_group("building_range"))
	generate_spawn_pos_map()
	
	for building in get_tree().get_nodes_in_group("buildings"):
		building.connect("spawn_projectile", self, "_on_spawn_projectile")

# returns true if the tile is within the map bounds
func is_valid_tile_pos(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size and tile.y < map_size

# returns true if the position is within tha map bounds
func is_valid_map_pos(position: Vector2) -> bool:
	var tile := Util.position_to_tile_pos(position)
	return is_valid_tile_pos(tile)

func is_valid_spawn_tile(tile: Vector2i) -> bool:
	return is_valid_tile_pos(tile) and spawn_pos_map[tile.x][tile.y] == 0

func is_valid_spawn_pos(position: Vector2) -> bool:
	var tile = Util.position_to_tile_pos(position)
	return is_valid_spawn_tile(tile)

onready var spawn_mesh_tween: Tween = $SpawnZoneMesh/OpacityTween
onready var spawn_mesh_timer: Timer = $SpawnZoneMesh/OpacityTimer

# shows the valid spawn position overlay for a few seconds, then hides it
# used when a troop is clicked on an invalid position
func show_valid_spawn_overlay():
	spawn_mesh_timer.stop()
	spawn_mesh_tween.remove_all()
	spawn_pos_mesh_node.material_override.albedo_color.a = 0.6
	
	spawn_mesh_timer.start(3)
	yield(spawn_mesh_timer, "timeout")
	
	var base_color: Color = spawn_pos_mesh_node.material_override.albedo_color
	
	spawn_mesh_tween.interpolate_property(
		spawn_pos_mesh_node.material_override, "albedo_color",
		Color(base_color.r, base_color.g, base_color.b, 0.6),
		Color(base_color.r, base_color.g, base_color.b, 0.0),
		1.5
	)
	spawn_mesh_tween.start()

var disabled := false

func spawn_troop(position: Vector2, troop):
	if disabled:
		return
	
	assert(is_valid_map_pos(position))
	troop.global_transform.origin = Vector3(position.x, 0.0, position.y)
	troop.building_range_map = building_range_map
	troop.connect("needs_target", self, "_on_needs_target", [troop])
	troop.connect("spawn_projectile", self, "_on_spawn_projectile")
	add_child(troop)
	building_range_map.new_troop_at(troop, troop.position())

# called when the attack has finished to stop troops and buildings from moving or shooting
func disable():
	disabled = true
	get_tree().call_group("needs_disable", "disable")

func _on_needs_target(troop):
	if disabled:
		return
	
	# for now, just look for the closest building, we'll worry about hitboxes and walls later
	var troop_tile: Vector2i = troop.tile()
	var target = null
	var tile_dist_list: Array = building_dist_map[troop_tile.x][troop_tile.y]
	
	var i := 0
	while i < tile_dist_list.size():
		var building_tile: TileBuildingDist = tile_dist_list[i]
		
		if building_tile.building.is_destroyed():
			tile_dist_list.remove(i)
			continue
		
		# for now, just select the first target available
		target = building_tile.building
		break
		i += 1
	
	troop.set_target(target)

func _on_spawn_projectile(projectile):
	if disabled:
		return
	
	add_child(projectile)
