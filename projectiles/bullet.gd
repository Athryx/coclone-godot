extends Projectile
class_name Bullet

func _on_hit(target, hit_target: bool):
	if hit_target:
		damage.apply_damage_to_unit(target)
