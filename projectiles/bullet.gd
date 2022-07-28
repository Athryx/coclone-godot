extends Projectile
class_name Bullet

func _on_hit(target, hit_target: bool):
	if hit_target:
		target.do_damage(damage)
