extends Targeter
class_name MeleeTargeter

func attack():
	damage.apply_damage_to_unit(target)
