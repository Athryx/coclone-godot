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

func _ready():
	generate_building_dist_map()
	building_range_map = BuildingRangeMap.new(get_tree().get_nodes_in_group("building_range"))
	
	for building in get_tree().get_nodes_in_group("buildings"):
		building.connect("spawn_projectile", self, "_on_spawn_projectile")

# returns true if the tile is within the map bounds
func is_valid_tile_pos(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size and tile.y < map_size

# returns true if the position is within tha map bounds
func is_valid_map_pos(position: Vector2) -> bool:
	var tile := Util.position_to_tile_pos(position)
	return is_valid_tile_pos(tile)

func spawn_troop(position: Vector2, troop):
	assert(is_valid_map_pos(position))
	troop.global_transform.origin = Vector3(position.x, 0.0, position.y)
	troop.building_range_map = building_range_map
	troop.connect("needs_target", self, "_on_needs_target", [troop])
	troop.connect("spawn_projectile", self, "_on_spawn_projectile")
	add_child(troop)

func _on_needs_target(troop):
	# for now, just look for the closest building, we'll worry about hitboxes and walls later
	var troop_tile: Vector2i = troop.tile()
	var target: Building
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
	add_child(projectile)
