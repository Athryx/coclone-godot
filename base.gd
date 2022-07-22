extends Spatial

const gunner = preload("res://troops/gunner.tscn")

# maximum duration of the attack in seconds
export var attack_time := 180

onready var map = $Map
onready var camera = $Camera
onready var grid = $Grid
onready var battle_info = $BattleInfo
onready var battle_timer = $BattleTimer

enum AttackState {
	SCOUTING,
	ATTACKING,
	DONE,
}
var attack_state: int = AttackState.SCOUTING

var grid_enabled := true

func _unhandled_key_input(event):
	if Input.is_action_just_pressed("togle_grid"):
		grid_enabled = !grid_enabled
		grid.visible = grid_enabled

func _on_GroundArea_input_event(input_camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and attack_state != AttackState.DONE:
		var pos2d := Util.vector3_to_vector2(position)
		
		if map.is_valid_spawn_pos(pos2d):
			var troop := gunner.instance()
			map.spawn_troop(pos2d, troop)
			
			if attack_state == AttackState.SCOUTING:
				attack_state = AttackState.ATTACKING
				battle_timer.start()
		else:
			map.show_valid_spawn_overlay()
		
	elif event is InputEventMouseMotion and grid_enabled:
		var pos2d := Util.vector3_to_vector2(position)
		var tile_pos_center := Util.round_to_tile_pos(pos2d) + Vector2(0.5, 0.5)
		
		if map.is_valid_map_pos(tile_pos_center):
			var tile_pos3d := Util.vector2_to_vector3(tile_pos_center)
			var camera_direction: Vector3 = camera.camera_direction_vec()
			grid.transform.origin = tile_pos3d - 10.0 * camera_direction
			grid.visible = true
		else:
			grid.visible = false

# these are only buildings that count towards destruction percent
var total_building_count := 0
var building_destroyed_count := 0

func _ready():
	battle_timer.wait_time = attack_time
	battle_info.set_time_remaining(attack_time)
	
	var buildings := get_tree().get_nodes_in_group("buildings")
	
	for building in buildings:
		if building.percent_contributor:
			total_building_count += 1
			building.connect("destroyed", self, "_on_building_destroyed", [], CONNECT_ONESHOT)

func _process(delta):
	if attack_state == AttackState.ATTACKING:
		battle_info.set_time_remaining(battle_timer.time_left as int)

func _on_building_destroyed():
	building_destroyed_count += 1
	battle_info.set_percent_destruction(100.0 * building_destroyed_count as float / total_building_count as float)

func _on_BattleTimer_timeout():
	attack_state = AttackState.DONE
	map.disable()
