extends Node3D
class_name Aimer
# aims all child nodes at the current target
# aims the negative z axis towards the target

# rotation speed is in radians per second
@export var rotate_speed_azimuth := 0.0
@export var rotate_speed_elevation := 0.0

# if true, aims at the troop on the ground, instead of the troop at the aim point
@export var aim_ground := false

var animate_azimuth: bool
var animate_elavation: bool

var current_target = null

func _ready():
	animate_azimuth = not is_zero_approx(rotate_speed_azimuth)
	animate_elavation = not is_zero_approx(rotate_speed_elevation)

# returns a vector from the aimer to the target that is normalized
func target_direction() -> Vector3:
	var target_aim_pos: Vector3
	if aim_ground:
		target_aim_pos = Util.vector2_to_vector3(current_target.position())
	else:
		target_aim_pos = current_target.aim_position()
	
	return (target_aim_pos - global_transform.origin).normalized()

# returns the direction of where the aimer is currently aiming
func aim_direction() -> Vector3:
	return global_transform.basis * (Vector3(0.0, 0.0, -1.0)).normalized()

func _physics_process(delta: float):
	if current_target == null:
		return
	
	var target_dir := target_direction()
	var aim_dir := aim_direction()
	
	var azimuth_target_dir := Util.vector3_to_vector2(target_dir)
	var azimuth_aim_dir := Util.vector3_to_vector2(aim_dir)
	
	if animate_azimuth:
		var azimuth_change := delta * rotate_speed_azimuth
		
		var angle_between := Util.signed_angle_between(azimuth_aim_dir, azimuth_target_dir)
		
		if angle_between >= 0.0:
			rotate_y(min(azimuth_change, angle_between))
		else:
			rotate_y(max(-azimuth_change, angle_between))
	
	if animate_elavation:
		var sideways_dir = Vector3(0.0, 1.0, 0.0).cross(aim_dir).normalized()
		
		var elevation_change := delta * rotate_speed_elevation
		
		var elevation_target_dir := Vector2(azimuth_target_dir.length(), target_dir.y)
		var elevation_aim_dir := Vector2(azimuth_aim_dir.length(), aim_dir.y)
		
		var angle_between := Util.signed_angle_between(elevation_aim_dir, elevation_target_dir)
		
		if angle_between >= 0.0:
			rotate(sideways_dir, min(elevation_change, angle_between))
		else:
			rotate(sideways_dir, max(-elevation_change, angle_between))

func set_target(target = null):
	current_target = target
