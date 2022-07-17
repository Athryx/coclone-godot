extends Spatial
class_name Projectile

# speed is in tiles per second
export var speed := 0.0

# weather or not the projectile follows the target, or just aims for it's initial position
export var seeking := true

# once the projectile is within this distance of the target, it is considered a hit
export var hit_dist := 0.01

# if true, will aim at the target at y = 0, which means it will hit the ground
# if false, it will aim at the target's aim point
export var hit_ground := false

# start is a spatial
var start

# target is either a troop or a building
var target

# only used for non seeking projectiles
# it is a vector3
var target_point = null

func position() -> Vector3:
	return global_transform.origin

# returns where we should aim on the given building or troop
func aim_position_of_target(target) -> Vector3:
	if hit_ground:
		return Util.vector2_to_vector3(target.position())
	else:
		return target.aim_position()

func target_position() -> Vector3:
	if seeking:
		return aim_position_of_target(target)
	else:
		return target_point

func target_vec() -> Vector3:
	return target_position() - position()

func _ready():
	global_transform.origin = start.global_transform.origin
	if seeking:
		target.connect("destroyed", self, "_on_target_destroyed", [], CONNECT_ONESHOT)
	else:
		target_point = aim_position_of_target(target)

func _physics_process(delta):
	# rotate towards target
	look_at(target_position(), Vector3(0.0, 1.0, 0.0))
	
	# move toward target
	var move_dist = min(delta * speed, target_vec().length())
	var direction = target_vec().normalized()
	global_transform.origin += move_dist * direction
	
	if target_vec().length() <= hit_dist:
		if seeking:
			_on_hit(target, true)
		else:
			_on_hit(target_point, false)
		queue_free()

# called when projectile strikes the target
# hit target is true if seeking, false if not
func _on_hit(target, hit_target: bool):
	pass

func _on_target_destroyed():
	target_point = Util.vector2_to_vector3(target.position())
	seeking = false
