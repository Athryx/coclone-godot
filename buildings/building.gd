class_name Building
extends Spatial

# The name of the building in game
export var building_name := ""

# The size of the building's footprint in tiles
# Only square footprints are supported
export var footprint_size := 3

# The size of the building's hitbox in tiles (hitbox obstructs units from walking through)
# Only square hitboxes are supported
export var hitbox_size := 3.0

# The size of the building's damage box in tiles (this is the box that units can target and shoot)
# Only square damage boxes are supported
export var damagebox_size := 3.0

export var max_health := 0

# Determines when units will target this building
enum TargetMode {
	# Never targeted
	NEVER,
	# Targeted if it is in the way (eg walls)
	OBSTACLE,
	# Always targeted
	ALWAYS,
}
export(TargetMode) var target_mode := TargetMode.ALWAYS

# Weather or not the building contributes to the percent destruction
export var percent_contributor := true

# position of the building on the map
export var x_position := 0
export var y_position := 0

func _ready():
	var half_footprint := footprint_size as float / 2.0
	var x := x_position as float + half_footprint
	var y := y_position as float + half_footprint
	global_transform.origin.x = x
	global_transform.origin.z = y

func position() -> Vector2i:
	var half_footprint := footprint_size as float / 2.0
	return Util.position_to_tile_pos(center_position() - Vector2(half_footprint, half_footprint))

func center_position() -> Vector2:
	return Vector2(global_transform.origin.x, global_transform.origin.z)

# gets the distance from the given point to the buildings target box
func target_dist(position: Vector2) -> float:
	position = (position - center_position()).abs()
	
	var half_damagebox_size := damagebox_size / 2.0
	
	if position.x <= half_damagebox_size:
		return max(position.y - half_damagebox_size, 0.0)
	elif position.y <= half_damagebox_size:
		return max(position.x - half_damagebox_size, 0.0)
	else:
		return Vector2(half_damagebox_size, half_damagebox_size).distance_to(position)
