extends Projectile
class_name Bullet

export var damage := 0

func _on_hit(target):
	# make sure we hit the target
	if target is Spatial:
		target.do_damage(damage)
