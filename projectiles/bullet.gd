extends Projectile
class_name Bullet

export var damage := 0

func _on_hit(target, hit_target: bool):
	if hit_target:
		target.do_damage(damage)
