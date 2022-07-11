extends Spatial
class_name Projectile

# speed is in tiles per second
export var speed := 0.0

# weather or not the projectile follows the target, or just aims for it's initial position
export var seeking := true

# once the projectile is within this distance of the target, it is considered a hit
export var hit_dist := 0.01

# emitted when the projectile hits its target
signal hit

# start is a spatial
var start

# target is either a troop or a building
var target

# only used for non seeking projectiles
# it is a vector3
var target_point = null

func position() -> Vector3:
	return global_transform.origin

func target_position() -> Vector3:
	if seeking:
		return Util.vector2_to_vector3(target.position())
	else:
		return target_point

func target_vec() -> Vector3:
	return target_position() - position()

func _ready():
	global_transform.origin = start.global_transform.origin
	if not seeking:
		target_point = Util.vector2_to_vector3(target.position())

func _physics_process(delta):
	# rotate towards target
	look_at(target_position(), Vector3(0.0, 1.0, 0.0))
	
	# move toward target
	var move_dist = min(delta * speed, target_vec().length())
	var direction = target_vec().normalized()
	global_transform.origin += move_dist * direction
	
	if target_vec().length() <= hit_dist:
		emit_signal("hit")
		queue_free()
