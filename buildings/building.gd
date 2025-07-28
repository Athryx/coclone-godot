extends "res://unit.gd"
class_name Building

# The size of the building's footprint in tiles
# Only square footprints are supported
@export var footprint_size := 3

# the width of the region that troops can't be placed in
# set to a negative number to allow troops to be placed on this building
# this width is measured from the edge of the footprint
@export var spawn_box_width := 1

# The size of the building's hitbox in tiles (hitbox obstructs units from walking through)
# Only square hitboxes are supported
@export var hitbox_size := 3.0

# The size of the building's damage box in tiles (this is the box that units can target and shoot)
# Only square damage boxes are supported
@export var damagebox_size := 3.0

# Determines when units will target this building
enum TargetMode {
	# Never targeted
	NEVER,
	# Targeted if it is in the way (eg walls)
	OBSTACLE,
	# Always targeted
	ALWAYS,
}
@export var target_mode := TargetMode.ALWAYS

# Weather or not the building contributes to the percent destruction
@export var percent_contributor := true

# position of the building on the map
@export var x_position := 0: set = set_x_position
@export var y_position := 0: set = set_y_position

var corner_position := Vector2i(0, 0)

@export var alive_model_node: NodePath
@onready var alive_model = get_node(alive_model_node)

@export var destroyed_model_node: NodePath
@onready var destroyed_model = get_node(destroyed_model_node)

const TileBounds = preload("res://util/tile_bounds.gd")

func set_x_position(num: int):
	x_position = num
	corner_position.x = num

func set_y_position(num: int):
	y_position = num
	corner_position.y = num

func _ready():
	var half_footprint := footprint_size as float / 2.0
	var x := corner_position.x as float + half_footprint
	var y := corner_position.y as float + half_footprint
	global_transform.origin.x = x
	global_transform.origin.z = y
	
	alive_model.visible = true
	destroyed_model.visible = false

func position() -> Vector2:
	var half_footprint_size := footprint_size as float / 2.0
	return Vector2(corner_position) + Vector2(half_footprint_size, half_footprint_size)

func get_corner_position() -> Vector2i:
	return corner_position

func footprint_bounds() -> TileBounds:
	var min_corner := get_corner_position()
	var max_corner := min_corner + Vector2i(footprint_size, footprint_size)
	return TileBounds.new(min_corner, max_corner)

# returns tile bounds which show the min and max corner of the spawn box,
# otherwise returns null if the building doesn't have a spawn box
func spawn_box_bounds():
	if spawn_box_width < 0:
		return null
	
	var bounds = footprint_bounds()
	bounds.offset(spawn_box_width)
	return bounds

# gets the distance from the given point to the buildings target box
func target_dist(position: Vector2) -> float:
	position = (position - position()).abs()
	
	var half_damagebox_size := damagebox_size / 2.0
	
	if position.x <= half_damagebox_size:
		return max(position.y - half_damagebox_size, 0.0)
	elif position.y <= half_damagebox_size:
		return max(position.x - half_damagebox_size, 0.0)
	else:
		return Vector2(half_damagebox_size, half_damagebox_size).distance_to(position)

# returns true if destroyed
func do_damage(damage: int) -> bool:
	# don't emit destroyed signal multiple times
	if health == 0:
		return true
	
	health = max(0, health - damage)
	if health == 0:
		emit_signal("destroyed")
		alive_model.visible = false
		destroyed_model.visible = true
		return true
	return false
