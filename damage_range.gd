extends Spatial
class_name DamageRange

export var radius := 0.0

signal target_acquired(troop)
signal target_lost

var current_target = null
# this is a set of all the targets in range
# the keys are the tagets, and the value is always null
# we only care about the keys
var targets_in_range := {}

func position() -> Vector2:
	return Vector2(global_transform.origin.x, global_transform.origin.z)

func contains_point(point: Vector2) -> bool:
	return (point - position()).length() <= radius

func set_current_target(target):
	if target == null and current_target != null:
		current_target = null
		emit_signal("target_lost")
	elif target != null:
		current_target = target
		print("acquired target")
		emit_signal("target_acquired", target)

func get_closest_target():
	var closest_target = null
	var closest_target_dist := INF
	
	for target in targets_in_range.keys():
		var target_range: float = (target.position() - position()).length()
		if target_range < closest_target_dist:
			closest_target_dist = target_range
			closest_target = target
	
	return closest_target

func notify_troop_entered(troop):
	targets_in_range[troop] = null
	if current_target == null:
		set_current_target(troop)

func notify_troop_exited(troop):
	targets_in_range.erase(troop)
	
	if current_target == troop:
		var closest_target = get_closest_target()
		if closest_target == null:
			set_current_target(null)
		else:
			set_current_target(closest_target)
