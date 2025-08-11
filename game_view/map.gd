extends Node3D
# contains info about that active base and troops

@export var map_size := 75

@export var map_edge_width := 3

const Building = preload("res://units/buildings/building.gd")

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
	var buildings := get_buildings()
	
	for x in map_size:
		var building_dist_row := []
		
		for y in map_size:
			var current_tile_array := []
			
			var tile_pos := Vector2(x as float + 0.5, y as float + 0.5)
			
			for building in buildings:
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
	
	for building in get_buildings():
		building.connect("spawn_projectile", Callable(self, "_on_spawn_projectile"))
	
	generate_pathing_nodes()
	#debug_show_pathing_nodes()

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

func get_buildings() -> Array[Building]:
	var buildings: Array[Building]
	buildings.assign(get_tree().get_nodes_in_group("buildings"))
	return buildings

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

func _on_spawn_projectile(projectile):
	if disabled:
		return
	
	add_child(projectile)

enum PathingNodeType {
	BUILDING = 0,
	NEGX_NEGY_CORNER = 1,
	NEGX_POSY_CORNER = 2,
	POSX_NEGY_CORNER = 3,
	POSX_POSY_CORNER = 4,
}

# Unit pathing logic below
class PathingNode:
	extends RefCounted
	
	# the buildings thie pathing node is associated with
	var building: Building
	var node_type: PathingNodeType
	var position: Vector2
	var connections: Array[PathingNodeConnection] = []
	
	func _init(building: Building, node_type: PathingNodeType, position: Vector2) -> void:
		self.building = building
		self.node_type = node_type
		self.position = position
	
	func can_connect_to(other_node_position: Vector2) -> bool:
		var node_direction: Vector2
		match node_type:
			PathingNodeType.BUILDING:
				return true
			PathingNodeType.NEGX_NEGY_CORNER:
				node_direction = Vector2(-1.0, -1.0)
			PathingNodeType.NEGX_POSY_CORNER:
				node_direction = Vector2(-1.0, 1.0)
			PathingNodeType.POSX_NEGY_CORNER:
				node_direction = Vector2(1.0, -1.0)
			PathingNodeType.POSX_POSY_CORNER:
				node_direction = Vector2(1.0, 1.0)
		
		var relative_position := other_node_position - self.position
		return relative_position.x * node_direction.x >= 0.0 or relative_position.y * node_direction.y >= 0.0

class PathingNodeConnection:
	extends RefCounted
	
	var node_index: int
	# buildings obstructing the path from node to target node at node_index
	var intermediate_buildings: Array[Building]
	
	func _init(node_index: int, buildings: Array[Building]):
		self.node_index = node_index
		self.intermediate_buildings = buildings
	
	static func sort_connections(start_position: Vector2, map, connections):
		# sorts based on distance between nodes
		var sort_fn = func (connection1, connection2):
			var pos1: Vector2 = map.pathing_nodes[connection1.node_index].position
			var dist1 := (start_position - pos1).length_squared()
			var pos2: Vector2 = map.pathing_nodes[connection2.node_index].position
			var dist2 := (start_position - pos2).length_squared()
			
			return dist1 < dist2
		
		connections.sort_custom(sort_fn)

var pathing_nodes: Array[PathingNode] = []

# returns a list of buildings between the line segment from start to end
# currently just walks the tiles, but a better approach could be
# a filling in empty tiles with larger regions, so empty squares do not cost as much time to deal with
func buildings_between(buildings: Array[Building], start: Vector2, end: Vector2, ignore_building1: Building, ignore_building2: Building) -> Array[Building]:
	var out: Array[Building] = []
	
	for building in buildings:
		# don't include the building we want to ignore
		if building == ignore_building1 or building == ignore_building2:
			continue
		
		var hitbox := building.hitbox_bounds()
		if Util.segment_intersects_rect(start, end, hitbox):
			out.append(building)
	
	var sort_fn = func (building1, building2):
		var dist1: float = (building1.position() - start).length_squared()
		var dist2: float = (building2.position() - start).length_squared()
		
		return dist1 < dist2
	out.sort_custom(sort_fn)
	
	return out

func connect_pathing_nodes(all_buildings: Array[Building], start_index: int, end_index: int, one_way: bool = false):
	var start_node := pathing_nodes[start_index]
	var end_node := pathing_nodes[end_index]
	
	# ignore building if both nodes are edge nodes on the same bulding
	# these nodes should always be connected
	if start_node.building == end_node.building:
		pass
	else:
		# for connections between different building nodes, ignore connection if it is
		# outside of node 270 degree pov (ie. corner node can't go between its own building
		if not (start_node.can_connect_to(end_node.position) and end_node.can_connect_to(start_node.position)):
			return
	
	var buildings := buildings_between(all_buildings, start_node.position, end_node.position, start_node.building, end_node.building)
	
	start_node.connections.append(PathingNodeConnection.new(end_index, buildings))
	if not one_way:
		end_node.connections.append(PathingNodeConnection.new(start_index, buildings))

func generate_pathing_nodes():
	pathing_nodes = []
	troop_approximation_map = {}
	var buildings := get_buildings()
	
	for building in buildings:
		var base_index := pathing_nodes.size()
		
		var bounds: TileBounds = building.footprint_bounds()
		pathing_nodes.append_array([
			PathingNode.new(building, PathingNodeType.BUILDING, building.position()),
			PathingNode.new(building, PathingNodeType.NEGX_NEGY_CORNER, Vector2(bounds.min_corner)),
			PathingNode.new(building, PathingNodeType.NEGX_POSY_CORNER, Vector2(bounds.min_corner.x, bounds.max_corner.y)),
			PathingNode.new(building, PathingNodeType.POSX_NEGY_CORNER, Vector2(bounds.max_corner.x, bounds.min_corner.y)),
			PathingNode.new(building, PathingNodeType.POSX_POSY_CORNER, Vector2(bounds.max_corner)),
		])
		
		connect_pathing_nodes(buildings, base_index + 1, base_index + 2)
		connect_pathing_nodes(buildings, base_index + 1, base_index + 3)
		connect_pathing_nodes(buildings, base_index + 4, base_index + 2)
		connect_pathing_nodes(buildings, base_index + 4, base_index + 3)
		
		for i in range(0, base_index / 5):
			var other_building: Building = buildings[i]
			var other_base_index := 5 * i
			
			for target_node_type in range(5):
				# TODO: don't connect nodes which are on a corner of a building directly facing src node
				# these nodes would never be pathed to as part of the real shortest path
				# TODO: don't connect nodes if the path passes over another corner node
				
				for src_node_type in range(1, 5):
					connect_pathing_nodes(buildings, base_index + src_node_type, other_base_index + target_node_type, true)
				
				# connect previous corner nodes to building node
				if target_node_type != PathingNodeType.BUILDING:
					connect_pathing_nodes(buildings, other_base_index + target_node_type, base_index + PathingNodeType.BUILDING, true)
	
	for node in pathing_nodes:
		PathingNodeConnection.sort_connections(node.position, self, node.connections)

func create_line_mesh_2d(start_2d: Vector2, end_2d: Vector2, thickness: float = 0.05):
	# Convert Vector2 -> Vector3 (on the XZ plane, y = 0)
	var start = Vector3(start_2d.x, 0.1, start_2d.y)
	var end = Vector3(end_2d.x, 0.1, end_2d.y)

	var mesh_instance = MeshInstance3D.new()
	
	# Create cylinder mesh for the line
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = thickness
	cylinder.bottom_radius = thickness
	cylinder.height = start.distance_to(end)
	cylinder.radial_segments = 8
	mesh_instance.mesh = cylinder

	# Midpoint position
	var midpoint = (start + end) * 0.5
	mesh_instance.translate(midpoint)

	# Rotate cylinder so its local Z-axis points toward the end
	var direction = (end_2d - start_2d).normalized()
	var forward_vec := Vector2(mesh_instance.basis.z.x, mesh_instance.basis.z.z)
	var angle := forward_vec.angle_to(direction)
	mesh_instance.rotate_x(deg_to_rad(90))
	mesh_instance.rotate_y(-angle)
	#var new_basis = Basis()
	#new_basis.z = direction
	#new_basis.x = Vector3.UP.cross(direction).normalized()
	#new_basis.y = direction.cross(basis.x).normalized()
	#mesh_instance.basis = new_basis

	add_child(mesh_instance)

func create_sphere_at_2d(point_2d: Vector2, radius: float = 0.25):
	# Convert Vector2 -> Vector3 (XZ plane, y = 0)
	var position_3d = Vector3(point_2d.x, 0, point_2d.y)

	var mesh_instance = MeshInstance3D.new()

	# Create sphere mesh
	var sphere = SphereMesh.new()
	sphere.radius = radius
	#sphere.height_segments = 8
	sphere.radial_segments = 16
	mesh_instance.mesh = sphere

	# Place sphere at given point
	mesh_instance.translate(position_3d)

	add_child(mesh_instance)

func debug_show_pathing_nodes():
	create_line_mesh_2d(Vector2(0, 0), Vector2(10, 10))
	for src_node in pathing_nodes:
		create_sphere_at_2d(src_node.position)
		for connection in src_node.connections:
			var dst_node := pathing_nodes[connection.node_index]
			create_line_mesh_2d(src_node.position, dst_node.position)

# keeps track of all pathing nodes that can be moved to from a point close to this pint
# there is a grid of troop approximation points, which are lazily crated when needed by troop close by
# it stores sorted order of buildings in distance order, and the buildings intersected along way to each pathing node
# 2 close pathing nodes on the grid can be used to quickly determine which buildings are in the way of troop pathing
class TroopApproximationPoint:
	extends RefCounted
	
	var position: Vector2
	var connections: Array[PathingNodeConnection]
	# array where index is node index, and value is connection to that node
	var node_index_to_connection: Array[int]
	
	func _init(position: Vector2, map):
		self.position = position
		self.connections = []
		
		var all_buildings = map.get_buildings()
		
		for i in range(map.pathing_nodes.size()):
			var node: PathingNode = map.pathing_nodes[i]
			var buildings: Array[Building] = map.buildings_between(all_buildings, position, node.position, node.building, null)
			
			connections.append(PathingNodeConnection.new(i, buildings))
		
		PathingNodeConnection.sort_connections(position, map, connections)
		
		# use range to make array of given size
		node_index_to_connection.assign(range(connections.size()))
		for i in range(connections.size()):
			node_index_to_connection[connections[i].node_index] = i
	
	func connection_for_node(node_index: int) -> PathingNodeConnection:
		return connections[node_index_to_connection[node_index]]

enum Corner {
	NEGX_NEGY = 0,
	NEGX_POSY = 1,
	POSX_NEGY = 2,
	POSX_POSY = 3,
}

class TroopApproximationInfo:
	extends RefCounted
	
	var map
	var point: Vector2
	# 4 corners around troop
	var corners: Array[TroopApproximationPoint]
	var closest_point: TroopApproximationPoint
	
	func _init(map, point: Vector2):
		self.point = point
		var base := Vector2i(point)
		
		corners = [
			map.get_troop_approximation_point(base + Vector2i(0, 0)),
			map.get_troop_approximation_point(base + Vector2i(0, 1)),
			map.get_troop_approximation_point(base + Vector2i(1, 0)),
			map.get_troop_approximation_point(base + Vector2i(1, 1)),
		]
		
		var offset := point - Vector2(base)
		var index := 0
		if offset.y > 0.5:
			index += 1
		if offset.x > 0.5:
			index += 2
		
		closest_point = corners[index]
		
		self.map = map
		self.corners = corners
		self.closest_point = closest_point
	
	func buildings_to_node(node_index: int) -> Array[Building]:
		var start_point := point
		var pathing_node: PathingNode = map.pathing_nodes[node_index]
		var node_direction = pathing_node.position - start_point
		
		# Select 2 of the 4 nodes around the start point to use for finding buildings along path
		# these nodes should be the vertexes on the side which the line segment leaves the square from
		# these will intersec all buildings outside of the approximation box
		# ohowever, it is assumed no buulding is in the approximation box
		# this is because either the troop is inside the building, which can't happen if it
		# is alive, or it is destroyed in which case it is irrelevent for pathing
		# or the building hitbox is smaller then the minimum size for approximation to work
		
		var point1: TroopApproximationPoint = null
		var point2: TroopApproximationPoint = null
		
		for segment_indexes in [
			[Corner.NEGX_NEGY, Corner.NEGX_POSY],
			[Corner.POSX_NEGY, Corner.POSX_POSY],
			[Corner.NEGX_NEGY, Corner.POSX_NEGY],
			[Corner.NEGX_POSY, Corner.POSX_POSY],
		]:
			var node1 := corners[segment_indexes[0]]
			var node2 := corners[segment_indexes[1]]
			
			var vec1 := node1.position - start_point
			var vec2 := node2.position - start_point
			
			if node_direction.cross(vec1) * node_direction.cross(vec2) <= 0.0:
				point1 = node1
				point2 = node2
				break
		
		assert(point1 != null and point2 != null)
		
		var connection1 := point1.connection_for_node(node_index)
		var connection2 := point2.connection_for_node(node_index)
		
		var out: Array[Building] = []
		
		var building_set := Set.new()
		# first collect buildings in first node
		for building in connection1.intermediate_buildings:
			building_set.add(building)
		
		for building in connection2.intermediate_buildings:
			if building_set.contains(building):
				out.append(building)
				building_set.remove(building)
			else:
				var hitbox := building.hitbox_bounds()
				if Util.segment_intersects_rect(start_point, pathing_node.position, hitbox):
					out.append(building)
		
		for building in building_set.values():
			var hitbox: Rect2 = building.hitbox_bounds()
			if Util.segment_intersects_rect(start_point, pathing_node.position, hitbox):
				out.append(building)
		
		return out

var troop_approximation_map: Dictionary[Vector2i, TroopApproximationPoint]
func get_troop_approximation_point(pos: Vector2i) -> TroopApproximationPoint:
	if pos in troop_approximation_map:
		return troop_approximation_map[pos]
	else:
		var out := TroopApproximationPoint.new(Vector2(pos), self)
		troop_approximation_map[pos] = out
		return out

func get_troop_approximation_info(pos: Vector2) -> TroopApproximationInfo:
	return TroopApproximationInfo.new(self, pos)

class InitialTargetResult:
	extends RefCounted
	
	var nodes: BinaryHeap
	var closest_building_score: float
	var node_to_path_info_map: Dictionary[PathingNode, NodePathInfo]
	
	func _init(nodes: BinaryHeap, closest_building_score: float, node_to_path_info_map: Dictionary[PathingNode, NodePathInfo]):
		self.nodes = nodes
		self.closest_building_score = closest_building_score
		self.node_to_path_info_map = node_to_path_info_map

# represents a path the troop will take to reach the node
# this is newtype wrapper so we can change connections without chainging
# object address, so it still works in priority queue dictionary of indexes
class NodePathInfo:
	extends RefCounted
	
	var connections: Array[PathingNodeConnection]
	var dst_node: PathingNode
	
	func _init(connections: Array[PathingNodeConnection], dst_node: PathingNode):
		self.connections = connections
		self.dst_node = dst_node

func sorted_intersected_buildings(buildings: Array[Building], start: Vector2, direction: Vector2) -> Array[Building]:
	# binary search could be faster asymtopically, but in most cases 1 or 2 buildings
	# at the end won't be targeted, since approach distance smaller than actual distance most times,
	# so linear scan from back probabls faster
	for i in range(buildings.size() - 1, -1, -1):
		if Util.segment_intersects_rect(start, start + direction, buildings[i].hitbox_bounds()):
			return buildings.slice(0, i + 1)
	
	return []

func find_initial_targets(troop: Troop) -> InitialTargetResult:
	var targets := BinaryHeap.new()
	var approximation_info := get_troop_approximation_info(troop.position())
	
	var closest_building_score := INF
	var node_to_path_info_map: Dictionary[PathingNode, NodePathInfo] = {}
	
	for connection in approximation_info.closest_point.connections:
		var pathing_node := pathing_nodes[connection.node_index]
		
		# if building is destroyed, none of the pathing nodes related to the buildings are relevant anymore
		if pathing_node.building.is_destroyed():
			continue
		
		# skip targeting building which this unit doesn't target
		if pathing_node.node_type == PathingNodeType.BUILDING and not troop.targets_unit(pathing_node.building):
			continue
		
		# prevent going through building to backside node, since building itself
		# is not in list of intermediate buildings on corner node of the building
		if not pathing_node.can_connect_to(troop.position()):
			continue
		
		var connection_vector := pathing_node.position - troop.position()
		# if we are targeting a building, we don't need to approach all the way
		# so make the vector shorter by the approach distance
		if pathing_node.node_type == PathingNodeType.BUILDING:
			var vector_len := connection_vector.length()
			var targetbox_dist := vector_len - pathing_node.building.target_dist(troop.position())
			var distance_reduction := targetbox_dist + troop.approach_distance
			
			if vector_len <= distance_reduction + 0.0001:
				print('shrnik')
				# negative vector will mess things up so just make vector close to 0
				connection_vector *= 0.0001
			else:
				print(connection_vector)
				print((vector_len - distance_reduction) / vector_len)
				connection_vector *= (vector_len - distance_reduction) / vector_len
				print(connection_vector.length())
		
		var distance := connection_vector.length()
		
		# if we have a building which is has a cost less then what a building at
		# this distance would have, we can stop looking
		if troop.pathing_cost(distance, []) >= closest_building_score:
			break
		
		var buildings := approximation_info.buildings_to_node(connection.node_index)
		
		# sort buildings by distance to troop, since approximation info does not return buildings in order
		var sort_fn = func (building1, building2):
			var dist1: float = (troop.position() - building1.position()).length_squared()
			var dist2: float = (troop.position() - building2.position()).length_squared()
			
			return dist1 < dist2
		buildings.sort_custom(sort_fn)
		
		var cost_buildings := buildings
		# exclude buildings which we can shoot over
		if pathing_node.node_type == PathingNodeType.BUILDING:
			cost_buildings = sorted_intersected_buildings(cost_buildings, troop.position(), connection_vector)
		
		var cost := troop.pathing_cost(distance, cost_buildings)
		if pathing_node.node_type == PathingNodeType.BUILDING and troop.targets_unit(pathing_node.building) and cost < closest_building_score:
			closest_building_score = cost
		
		var interpolated_connection := PathingNodeConnection.new(connection.node_index, buildings)
		
		var path_info := NodePathInfo.new([interpolated_connection], pathing_node)
		node_to_path_info_map[pathing_node] = path_info
		targets.insert(path_info, cost)
	
	return InitialTargetResult.new(targets, closest_building_score, node_to_path_info_map)

# gets a path to a target for the troop, or null if no more buildings left which troop can target
func get_target_path(troop: Troop) -> NodePathInfo:
	var state := find_initial_targets(troop)
	var visited_nodes := Set.new()
	
	var selected_path: NodePathInfo = null
	
	while true:
		var start_node_cost = state.nodes.lowest_cost()
		if start_node_cost == null:
			break
		
		var path: NodePathInfo = state.nodes.extract()
		var node := path.dst_node
		if node.node_type == PathingNodeType.BUILDING:
			# found building to target, this is minimum cost node which is not yet visited
			# and first minumum cost buiilding we target it
			selected_path = path
			break
		
		visited_nodes.add(node)
		
		for connection in node.connections:
			var connected_node := pathing_nodes[connection.node_index]
			if visited_nodes.contains(connected_node):
				continue
			
			# if building is destroyed, none of the pathing nodes related to the buildings are relevant anymore
			if connected_node.building.is_destroyed():
				continue
			
			# skip targeting building which this unit doesn't target
			if connected_node.node_type == PathingNodeType.BUILDING and not troop.targets_unit(connected_node.building):
				continue
			
			var connection_vector := connected_node.position - node.position
			# if we are targeting a building, we don't need to approach all the way
			# so make the vector shorter by the approach distance
			if connected_node.node_type == PathingNodeType.BUILDING:
				var vector_len := connection_vector.length()
				var targetbox_dist := vector_len - connected_node.building.target_dist(troop.position())
				var distance_reduction := targetbox_dist + troop.approach_distance
				
				if vector_len <= distance_reduction + 0.0001:
					# negative vector will mess things up so just make vector close to 0
					print('shrink')
					connection_vector *= 0.0001
				else:
					print(connection_vector)
					print((vector_len - distance_reduction) / vector_len)
					connection_vector *= (vector_len - distance_reduction) / vector_len
					print(connection_vector.length())
			
			var distance := connection_vector.length()
			
			if troop.pathing_cost(distance, []) + start_node_cost > state.closest_building_score:
				break
			
			var cost_buildings := connection.intermediate_buildings
			# exclude buildings which we can shoot over
			if connected_node.node_type == PathingNodeType.BUILDING:
				cost_buildings = sorted_intersected_buildings(cost_buildings, node.position, connection_vector)
			
			var cost: float = troop.pathing_cost(distance, cost_buildings) + start_node_cost
			if connected_node.node_type == PathingNodeType.BUILDING and troop.targets_unit(connected_node.building):
				state.closest_building_score = cost
			
			var connected_node_path_info = state.node_to_path_info_map.get(connected_node)
			# update cost in priority queue of node if it is less then previously
			var old_cost = state.nodes.get_cost(connected_node_path_info)
			var new_path: Array[PathingNodeConnection]
			new_path.assign(path.connections + [connection])
			
			if old_cost == null:
				connected_node_path_info = NodePathInfo.new(new_path, connected_node)
				state.nodes.insert(connected_node_path_info, cost)
				state.node_to_path_info_map[connected_node] = connected_node_path_info
			elif cost < old_cost:
				# update path and cost
				connected_node_path_info.connections = new_path
				state.nodes.update_cost(connected_node_path_info, cost)
	
	return selected_path

func set_troop_path(troop: Troop):
	var path := get_target_path(troop)
	if path == null:
		troop.set_path(null, null)
		return
	
	var final_target := path.dst_node.building
	
	# convert path to troop actions
	var troop_actions := []
	var old_position := troop.position()
	
	for connection in path.connections:
		var node := pathing_nodes[connection.node_index]
		var connection_vector := node.position - old_position
		
		var buildings := connection.intermediate_buildings
		
		if node.node_type == PathingNodeType.BUILDING:
			var vector_len := connection_vector.length()
			var targetbox_dist := vector_len - node.building.target_dist(troop.position())
			var distance_reduction := targetbox_dist + troop.approach_distance
			
			if vector_len <= distance_reduction + 0.0001:
				# negative vector will mess things up so just make vector close to 0
				print('shrink')
				connection_vector *= 0.0001
			else:
				print(connection_vector)
				print((vector_len - distance_reduction) / vector_len)
				connection_vector *= (vector_len - distance_reduction) / vector_len
				print(connection_vector.length())
			
			buildings = sorted_intersected_buildings(buildings, old_position, connection_vector)
		
		for building in buildings:
			troop_actions.append(Troop.TroopAction.attack_building(building))
		
		if node.node_type == PathingNodeType.BUILDING:
			troop_actions.append(Troop.TroopAction.attack_building(node.building))
		else:
			troop_actions.append(Troop.TroopAction.move(node.position))
		
		old_position = node.position
	
	troop.set_path(troop_actions, final_target)

func _on_needs_target(troop):
	if disabled:
		return
	
	set_troop_path(troop)
