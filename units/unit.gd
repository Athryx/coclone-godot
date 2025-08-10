extends Node3D
class_name Unit

# this class is inherited by both troop and building, and has functionality common to both

@export var unit_name := ""

enum UnitGroup {
	NON_WALL = 1,
	DEFENSE = 2,
	WALL = 4,
}
# unit groups this unit is a part of
@export_flags("Non Wall:1", "Defense:2", "Wall:4") var unit_groups := 0
# unit groups this unit will target
@export_flags("Non Wall:1", "Defense:2", "Wall:4") var targeted_unit_groups := 0

# checks if this unit targets the other unit
func targets_unit(other: Unit) -> bool:
	return (other.unit_groups & self.targeted_unit_groups) != 0

@export var aim_pos_height := 0.0

@export var preview_size := 5.0
@export var preview_y_offset := 0.0

@export var max_health := 0
@onready var health = max_health

@export var health_bar: Node = null

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
	health = max(0, health - damage)
	if health_bar != null:
		health_bar.set_health(max_health, health)

# used to propagate spawn projectile from chile nodes within the scene
func emit_spawn_projectile(projectile):
	emit_signal("spawn_projectile", projectile)
