extends Unit
class_name Troop

# movement speed is in tiles per second
@export var move_speed := 0.0

# how close the troop will approach buildings
# this is the distance from their damage box
@export var approach_distance := 0.0

# how fast the troop will rotate to face its next target
# this is in degrees per second
@export var rotation_speed := 0.0

# position where the troop was spawned in at
var spawn_pos := Vector2(0.0, 0.0)

# signals sent when the unit is within range of the building, not when the ai picks a building to attack
# used to control attacks
signal target_acquired(building)
signal target_lost

enum LastTargetSignal {
	TARGET_ACQUIRED,
	TARGET_LOST,
}

var last_target_signal: int = LastTargetSignal.TARGET_LOST

const BuildingRangeMap = preload("res://units/buildings/building_range_map.gd")

var building_range_map: BuildingRangeMap

# emmited when the troop doesn't have a target
# something else should then call set target on this troop
signal needs_target

var current_target = null

func set_target(building):
	if building == null and current_target != null:
		current_target = null
		emit_signal("target_lost")
		last_target_signal = LastTargetSignal.TARGET_LOST
	elif building != null:
		current_target = building
		current_target.connect("destroyed", Callable(self, "_on_current_target_destroyed").bind(), CONNECT_ONE_SHOT)

func tile() -> Vector2i:
	return Util.position_to_tile_pos(position())

func _ready():
	global_transform.origin = Vector3(spawn_pos.x, 0.0, spawn_pos.y)
	if current_target == null:
		emit_signal("needs_target")

func _physics_process(delta: float):
	if current_target == null:
		return
	
	var move_direction: Vector2 = current_target.position() - position()
	
	# rotation
	# z faces target
	var forward_vec := Vector2(basis.z.x, basis.z.z)
	var angle := forward_vec.angle_to(move_direction)
	var max_rotation_amount := deg_to_rad(delta * rotation_speed)
	
	var rotate_amount = 0.0
	if angle > 0.0:
		rotate_amount = max(-angle, -max_rotation_amount)
	else:
		rotate_amount = min(-angle, max_rotation_amount)
	
	rotate_y(rotate_amount)
	
	if current_target.target_dist(position()) <= approach_distance:
		if last_target_signal == LastTargetSignal.TARGET_LOST:
			emit_signal("target_acquired", current_target)
			last_target_signal = LastTargetSignal.TARGET_ACQUIRED
		return
	
	# translation
	var move_distance := delta * move_speed
	
	var move_vector := move_distance * move_direction.normalized()
	
	var old_position := position()
	#translate(Util.vector2_to_vector3(move_vector))
	self.transform.origin += Util.vector2_to_vector3(move_vector)
	building_range_map.moved(self, old_position, position())

# returns true if destroyed
func do_damage(damage: int):
	# don't emit the destroyed signal multiple times if it is already destroyed
	if health == 0:
		return
		
	super.do_damage(damage)
	
	if health == 0:
		emit_signal("destroyed")
		queue_free()

# stops the unit when the battle time has ended
func disable():
	set_target(null)

func _on_current_target_destroyed():
	set_target(null)
	emit_signal("needs_target")
