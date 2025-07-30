extends Resource
class_name DamageEffect

# amount of damage this damage affect does
@export var damage := 0

# area of affect of this damage
# if 0, this is single target damage
@export var area_of_effect := 0.0

func is_aoe():
	return area_of_effect != 0.0

func apply_damage_to_unit(unit: Unit):
	if is_aoe():
		assert(false, "unimplemented")
	else:
		unit.do_damage(damage)

func apply_damage_to_position(position: Vector2):
	if is_aoe():
		assert(false, "unimplemented")
	# non aoe damage does no damage if it doesn't hit unit
