extends Reference

# both of these are maps from a Vector2i to a vector of damage ranges
# range_map_edge is all tiles that are on the edge of a range,
# range map full is all tiles that are inside of a range
var range_map_edge := {}
var range_map_full := {}

func _init(ranges: Array):
	for damage_range in ranges:
		var tile_bounds := Util.tile_bounds(damage_range.position(), damage_range.radius)
		
		for x in range(tile_bounds.min_corner.x, tile_bounds.max_corner.x):
			for y in range(tile_bounds.min_corner.y, tile_bounds.max_corner.y):
				var tile := Vector2i.new(x, y).to_vector2()
				
				var xf := x as float
				var yf := y as float
				var corners := [
					Vector2(xf, yf),
					Vector2(xf + 1.0, yf),
					Vector2(xf, yf + 1.0),
					Vector2(xf + 1.0, yf + 1.0),
				]
				
				var num_corners_inside := 0
				for corner in corners:
					if corner.distance_to(damage_range.position()) <= damage_range.radius:
						num_corners_inside += 1
				
				if num_corners_inside == 4:
					# all corners are inside the range, add to range_map_full
					if not tile in range_map_full:
						range_map_full[tile] = []
					range_map_full[tile].push_back(damage_range)
				elif num_corners_inside != 0:
					# some corners inside the range some outside, so it is on the edge
					# add to range_map_edge
					if not tile in range_map_edge:
						range_map_edge[tile] = []
					range_map_edge[tile].push_back(damage_range)

# both new_troop_at and moved will notify buildin ranges about troops entering and exiting their area
# can't type troop because it causes a cyclic dependancy
func new_troop_at(troop, position: Vector2):
	var tile := Util.round_to_tile_pos(position)
	
	for damage_range in range_map_full.get(tile, []):
		damage_range.notify_troop_entered(troop)
	
	for damage_range in range_map_edge.get(tile, []):
		if damage_range.contains_point(troop.position()):
			damage_range.notify_troop_entered(troop)

func moved(troop, start: Vector2, end: Vector2):
	var start_tile := Util.position_to_tile_pos(start)
	var end_tile := Util.position_to_tile_pos(end)
	
	var tiles_to_check = [start]
	if not start_tile.equals(end_tile):
		tiles_to_check.push_back(end)
	
	for position in tiles_to_check:
		var tile := Util.round_to_tile_pos(position)
		
		for damage_range in range_map_edge.get(tile, []):
			var contains_start: bool = damage_range.contains_point(start)
			var contains_end: bool = damage_range.contains_point(end)
			
			if contains_start and not contains_end:
				damage_range.notify_troop_exited(troop)
			elif contains_end and not contains_start:
				damage_range.notify_troop_entered(troop)
