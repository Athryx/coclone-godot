extends Node3D
class_name Targeter

# the dalay between acquiring a target and shooting the first shot
@export var initial_wait_time := 0.0
# the subsequent delays between shots
@export var refire_time := 0.0

# damage done by each attack
@export var damage: DamageEffect

var target = null

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)

func set_target(target = null):
	self.target = target
	if target == null:
		timer.stop()
	else:
		timer.start(initial_wait_time)

func _on_timer_timeout():
	timer.start(refire_time)
	attack()

# override in child class to perform attack
func attack():
	pass
