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

# affects how much time pathing algorithm will consider this troop to take
# to destroy an obstacle in its path, effectively dps pathing algorithm considers
@export var pathing_dps := 0

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

var path = null
var path_index := 0
var final_target: Building = null

func pathing_cost(distance: float, buildings: Array[Building]) -> float:
	var cost := distance / move_speed
	for building in buildings:
		cost += building.health / pathing_dps
	return cost

enum TroopActionType {
	MOVE = 0,
	ATTACK_BUILDING = 1,
}

class TroopAction:
	extends RefCounted
	
	var type: TroopActionType
	
	# vector2
	var position = null
	var building: Building = null
	
	func _init(type: TroopActionType):
		self.type = type
	
	static func move(position: Vector2) -> TroopAction:
		var out := TroopAction.new(TroopActionType.MOVE)
		out.position = position
		return out
	
	static func attack_building(building: Building) -> TroopAction:
		var out := TroopAction.new(TroopActionType.ATTACK_BUILDING)
		out.building = building
		return out

func set_path(path, final_target: Building):
	if path == null and self.path != null:
		self.path = null
		self.final_target = null
		
		emit_signal("target_lost")
		last_target_signal = LastTargetSignal.TARGET_LOST
	elif path != null and final_target != null:
		self.path = path
		self.path_index = 0
		self.final_target = final_target
		final_target.connect("destroyed", self._on_current_target_destroyed, ConnectFlags.CONNECT_ONE_SHOT)

func tile() -> Vector2i:
	return Util.position_to_tile_pos(position())

func _ready():
	global_transform.origin = Vector3(spawn_pos.x, 0.0, spawn_pos.y)
	if path == null:
		emit_signal("needs_target")

func rotate_towards(delta: float, direction: Vector2):
	# rotation
	# z faces target
	var forward_vec := Vector2(basis.z.x, basis.z.z)
	var angle := forward_vec.angle_to(direction)
	var max_rotation_amount := deg_to_rad(delta * rotation_speed)
	
	var rotate_amount = 0.0
	if angle > 0.0:
		rotate_amount = max(-angle, -max_rotation_amount)
	else:
		rotate_amount = min(-angle, max_rotation_amount)
	
	rotate_y(rotate_amount)

# returns true when done
func move_to_point(delta: float, target_position: Vector2) -> bool:
	var move_direction: Vector2 = target_position - position()
	
	# don't move if we have reached target point
	if move_direction.length() < 0.0001:
		return true
	
	rotate_towards(delta, move_direction)
	
	var move_distance := delta * move_speed
	
	var move_vector := move_distance * move_direction.normalized()
	
	var old_position := position()
	self.transform.origin += Util.vector2_to_vector3(move_vector)
	building_range_map.moved(self, old_position, position())
	
	# recheck if we reached target point
	return (target_position - position()).length() < 0.0001

# returns true when done
func attack_building(delta: float, building: Building) -> bool:
	if building.is_destroyed():
		return true
	
	if building.target_dist(position()) <= approach_distance:
		if last_target_signal == LastTargetSignal.TARGET_LOST:
			emit_signal("target_acquired", building)
			last_target_signal = LastTargetSignal.TARGET_ACQUIRED
	else:
		move_to_point(delta, building.position())
	
	return false

# returns true if action complete
func process_action(delta: float, action: TroopAction) -> bool:
	if action.type == TroopActionType.MOVE:
		return move_to_point(delta, action.position)
	elif action.type == TroopActionType.ATTACK_BUILDING:
		return attack_building(delta, action.building)
	else:
		print('warning: unhandled troop action')
		return true

func _physics_process(delta: float):
	if path == null:
		return
	
	if path_index >= path.size():
		# shouldn't normally happend because currently path always ends with final target
		_on_current_target_destroyed()
		return
	
	if process_action(delta, path[path_index]):
		path_index += 1

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
	set_path(null, null)

func _on_current_target_destroyed():
	set_path(null, null)
	emit_signal("needs_target")
