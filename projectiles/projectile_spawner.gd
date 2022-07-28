extends Spatial
class_name ProjectileSpawner

# the dalay between acquiring a target and shooting the first shot
export var initial_wait_time := 0.0
# the subsequent delays between shots
export var refire_time := 0.0

# the projectile that will be fired
# the root node should be an instance of Projectile
export(PackedScene) var projectile: PackedScene

# damage done by each projectile
export var damage := 0

signal spawn_projectile(projectile)

var target = null

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout", self, "_on_timer_timeout")
	add_child(timer)

func set_target(target = null):
	self.target = target
	if target == null:
		timer.stop()
	else:
		timer.start(initial_wait_time)

func _on_timer_timeout():
	timer.start(refire_time)
	var projectile_instance = projectile.instance()
	projectile_instance.damage = damage
	projectile_instance.start = self
	projectile_instance.target = target
	emit_signal("spawn_projectile", projectile_instance)
