extends Targeter
class_name ProjectileSpawner

# the projectile that will be fired
# the root node should be an instance of Projectile
@export var projectile: PackedScene

signal spawn_projectile(projectile)

func attack():
	var projectile_instance = projectile.instantiate()
	projectile_instance.damage = damage
	projectile_instance.start = self
	projectile_instance.target = target
	emit_signal("spawn_projectile", projectile_instance)
