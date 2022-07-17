extends Spatial
class_name Troop

export var max_health := 0
onready var health := max_health

# movement speed is in tiles per second
export var move_speed := 0.0

# how close the troop will approach buildings
# this is the distance from their damage box
export var approach_distance := 0.0

# how high up on the building projectiles will be aimed
export var aim_pos_height := 0.0

signal destroyed

signal spawn_projectile(projectile)

# signals sent when the unit is within range of the building, not when the ai picks a building to attack
signal target_acquired(building)
signal target_lost

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

var current_target = null

func set_target(building):
	if building == null and current_target != null:
		current_target = null
		emit_signal("target_lost")
		last_target_signal = LastTargetSignal.TARGET_LOST
	elif building != null:
		current_target = building
		current_target.connect("destroyed", self, "_on_current_target_destroyed", [], CONNECT_ONESHOT)

func position() -> Vector2:
	return Vector2(global_transform.origin.x, global_transform.origin.z)

func aim_position() -> Vector3:
	var position := position()
	return Vector3(position.x, aim_pos_height, position.y)

func tile() -> Vector2i:
	return Util.position_to_tile_pos(position())

func _ready():
	building_range_map.new_troop_at(self, position())
	if current_target == null:
		emit_signal("needs_target")

func _physics_process(delta: float):
	if current_target == null:
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

# returns true if destroyed
func do_damage(damage: int) -> bool:
	# don't emit the destroyed signal multiple times if it is already destroyed
	if health == 0:
		return true

	health = max(0, health - damage)
	if health == 0:
		emit_signal("destroyed")
		queue_free()
		return true
	return false

func _on_current_target_destroyed():
	set_target(null)
	emit_signal("needs_target")

# used to propagate spawn projectile from chile nodes within the scene
func emit_spawn_projectile(projectile):
	emit_signal("spawn_projectile", projectile)
