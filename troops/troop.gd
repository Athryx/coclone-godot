extends Spatial
class_name Troop

export var max_health := 0

# movement speed is in tiles per second
export var move_speed := 0.0

# how close the troop will approach buildings
# this is the distance from their damage box
export var approach_distance := 0.0

signal spawn_projectile(projectile)

# signals sent when the unit is within range of the building, not when the ai picks a building to attack
signal target_acquired(building)
signal taget_lost

enum LastTargetSignal {
	TARGET_ACQUIRED,
	TARGET_LOST,
}

var last_target_signal: int = LastTargetSignal.TARGET_LOST

const BuildingRangeMap = preload("res://buildings/building_range_map.gd")

var building_range_map: BuildingRangeMap

# emmited when the troop doesn't have a target
# something else should then call set target on this troop
signal needs_target

var needs_target_emitted := false
var current_target = null

func set_target(building: Building):
	current_target = building
	needs_target_emitted = false

func position() -> Vector2:
	return Vector2(global_transform.origin.x, global_transform.origin.z)

func tile() -> Vector2i:
	return Util.position_to_tile_pos(position())

func _ready():
	building_range_map.new_troop_at(self, position())

func _physics_process(delta: float):
	if current_target == null:
		if !needs_target_emitted:
			emit_signal("needs_target")
			needs_target_emitted = true
		return
	
	if current_target.target_dist(position()) <= approach_distance:
		if last_target_signal == LastTargetSignal.TARGET_LOST:
			emit_signal("target_acquired", current_target)
			last_target_signal = LastTargetSignal.TARGET_ACQUIRED
		return
	
	var move_distance := delta * move_speed
	
	var move_direction: Vector2 = current_target.position() - position()
	var move_vector := move_distance * move_direction.normalized()
	
	var old_position := position()
	translate(Util.vector2_to_vector3(move_vector))
	building_range_map.moved(self, old_position, position())

# used to propagate spawn projectile from chile nodes within the scene
func emit_spawn_projectile(projectile):
	emit_signal("spawn_projectile", projectile)
