extends Node3D
# contains info about that active base and troops

@export var map_size := 75

@export var map_edge_width := 3

const Building = preload("res://units/buildings/building.gd")
const TargetMode = Building.TargetMode

const BuildingRangeMap = preload("res://units/buildings/building_range_map.gd")

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
					tile_building_dist.compare
				)
				
				current_tile_array.insert(index, tile_building_dist)
			
			building_dist_row.push_back(current_tile_array)
		
		building_dist_map.push_back(building_dist_row)

var building_range_map: BuildingRangeMap

# a 2d array of numbers for each tile
# a nonzero number means a unit can't be spawned on the tile
var spawn_pos_map := []

# 2d array of booleans for each tile
# true means it is occupied by a building
var footprint_map := []

@onready var spawn_pos_mesh_node = $SpawnZoneMesh
@onready var spawn_pos_mesh = $SpawnZoneMesh.multimesh

func generate_spawn_pos_mesh():
	# generate the outline mesh
	# have to collect them in a separate array before setting the up the multimesh
	var mesh_transforms := []
	
	for x in map_size:
		for y in map_size:
			var tile = Vector2i(x, y)
			
			if not is_valid_spawn_tile(Vector2i(x, y)):
				var tiles = [Vector2i(x - 1, y), Vector2i(x, y - 1)]
				
				if is_valid_spawn_tile(Vector2i(x - 1, y)):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(tile, -PI / 2.0)
					)
				
				if is_valid_spawn_tile(Vector2i(x, y - 1)):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(tile, 0.0)
					)
				
				var pos_x_tile := Vector2i(x + 1, y)
				if is_valid_spawn_tile(pos_x_tile):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(pos_x_tile, -PI / 2.0)
					)
				
				var pos_y_tile := Vector2i(x, y + 1)
				if is_valid_spawn_tile(pos_y_tile):
					mesh_transforms.push_back(
						get_spawn_mesh_transform(pos_y_tile, 0.0)
					)
	
	spawn_pos_mesh.instance_count = mesh_transforms.size()
	for i in mesh_transforms.size():
		spawn_pos_mesh.set_instance_transform(i, mesh_transforms[i])

func get_spawn_mesh_transform(position: Vector2i, rotation: float) -> Transform3D:
	return Transform3D(
		Basis(Vector3(0.0, 1.0, 0.0), rotation),
		Util.vector2_to_vector3(Vector2(position))
	)

func _ready():
	for x in map_size:
		spawn_pos_map.push_back([])
		footprint_map.push_back([])
		for y in map_size:
			spawn_pos_map[x].push_back(0)
			footprint_map[x].push_back(false)

# call this when all buildings have been added to the map to set it up for attack
func finalize():
	generate_building_dist_map()
	building_range_map = BuildingRangeMap.new(get_tree().get_nodes_in_group("building_range"))
	generate_spawn_pos_mesh()
	
	for building in get_tree().get_nodes_in_group("buildings"):
		building.connect("spawn_projectile", Callable(self, "_on_spawn_projectile"))

func add_building(building: Building) -> bool:
	var footprint_bounds := building.footprint_bounds()
	if not is_valid_footprint_tile_bounds(building.footprint_bounds()):
		return false
	
	var spawn_bounds = building.spawn_box_bounds()
	if spawn_bounds != null:
		clamp_tile_bounds(spawn_bounds)
		for x in spawn_bounds.xrange():
			for y in spawn_bounds.yrange():
				spawn_pos_map[x][y] += 1
	
	for x in footprint_bounds.xrange():
		for y in footprint_bounds.yrange():
			footprint_map[x][y] = true
	
	add_child(building)
	
	return true

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

func is_valid_tile_bounds(tile_bounds: TileBounds) -> bool:
	return is_valid_tile_pos(tile_bounds.min_corner) and is_valid_tile_pos(tile_bounds.max_corner - Vector2i(1, 1))

func is_valid_footprint_tile_bounds(tile_bounds: TileBounds) -> bool:
	if not is_valid_tile_bounds(tile_bounds):
		return false
	
	for x in tile_bounds.xrange():
		for y in tile_bounds.yrange():
			if footprint_map[x][y]:
				return false
	
	return true

func clamp_tile_bounds(tile_bounds: TileBounds):
	tile_bounds.min_corner = tile_bounds.min_corner.max(Vector2i(0, 0))
	tile_bounds.max_corner = tile_bounds.max_corner.min(Vector2i(map_size, map_size))

var spawn_mesh_tween: Tween = null

func setup_spawn_overlay_tween():
	var base_color: Color = spawn_pos_mesh_node.material_override.albedo_color
	
	spawn_mesh_tween.tween_interval(3)
	spawn_mesh_tween.tween_property(
		spawn_pos_mesh_node.material_override, "albedo_color",
		Color(base_color.r, base_color.g, base_color.b, 0.0),
		1.5
	)

# shows the valid spawn position overlay for a few seconds, then hides it
# used when a troop is clicked on an invalid position
func show_valid_spawn_overlay():
	if spawn_mesh_tween != null:
		spawn_mesh_tween.stop()
	
	var base_color: Color = spawn_pos_mesh_node.material_override.albedo_color
	
	spawn_pos_mesh_node.material_override.albedo_color = Color(
		base_color.r,
		base_color.g,
		base_color.b,
		0.6
	)
	
	spawn_mesh_tween = spawn_pos_mesh_node.create_tween()
	spawn_mesh_tween.tween_interval(3)
	spawn_mesh_tween.tween_property(
		spawn_pos_mesh_node.material_override, "albedo_color",
		Color(base_color.r, base_color.g, base_color.b, 0.0),
		1.5
	)
	
	spawn_mesh_tween.play()

func enable_valid_spawn_overlay():
	spawn_pos_mesh_node.material_override.albedo_color.a = 0.6

var disabled := false

func spawn_troop(position: Vector2, troop):
	if disabled:
		return
	
	assert(is_valid_map_pos(position))
	troop.spawn_pos = position
	troop.building_range_map = building_range_map
	troop.connect("needs_target", Callable(self, "_on_needs_target").bind(troop))
	troop.connect("spawn_projectile", Callable(self, "_on_spawn_projectile"))
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
			tile_dist_list.remove_at(i)
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
