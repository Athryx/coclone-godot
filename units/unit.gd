extends Node3D
class_name Unit

# this class is inherited by both troop and building, and has functionality common to both

@export var unit_name := ""

@export var aim_pos_height := 0.0

@export var preview_size := 5.0

@export var max_health := 0
@onready var health = max_health

signal destroyed

signal spawn_projectile(projectile)

func position() -> Vector2:
	return Vector2(global_transform.origin.x, global_transform.origin.z)

func aim_position() -> Vector3:
	var position := position()
	return Vector3(position.x, aim_pos_height, position.y)

func is_destroyed() -> bool:
	return health == 0

func do_damage(damage: int):
	pass

# used to propagate spawn projectile from chile nodes within the scene
func emit_spawn_projectile(projectile):
	emit_signal("spawn_projectile", projectile)
