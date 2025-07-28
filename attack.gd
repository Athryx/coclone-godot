extends Node3D

# maximum duration of the attack in seconds
@export var attack_time := 180

const Gunner = preload("res://troops/gunner.tscn")

@onready var map = $Map
@onready var battle_timer = $BattleTimer
@onready var battle_info = $BattleInfo
@onready var troop_bar = $TroopBar

enum AttackState {
	SCOUTING,
	ATTACKING,
	DONE,
}
var attack_state: int = AttackState.SCOUTING

func _on_GameArea_position_clicked(position):
	if map.is_valid_spawn_pos(position):
		var troop = troop_bar.get_current_unit()
		
		if troop != null:
			troop_bar.dec_current_unit()
			map.spawn_troop(position, troop)
			
			if attack_state == AttackState.SCOUTING:
				attack_state = AttackState.ATTACKING
				battle_timer.start()
	else:
		map.show_valid_spawn_overlay()

# these are only buildings that count towards destruction percent
var total_building_count := 0
var building_destroyed_count := 0

func _ready():
	battle_timer.wait_time = attack_time
	battle_info.set_time_remaining(attack_time)
	
	for building in PlayerData.player.base_layout.get_buildings():
		map.add_building(building.instantiate())
	
	map.finalize()
	
	# temp
	troop_bar.add_unit(Gunner, 50)
	
	var buildings := get_tree().get_nodes_in_group("buildings")
	
	for building in buildings:
		if building.percent_contributor:
			total_building_count += 1
			building.connect("destroyed", Callable(self, "_on_building_destroyed").bind(), CONNECT_ONE_SHOT)

func _process(delta):
	if attack_state == AttackState.ATTACKING:
		battle_info.set_time_remaining(battle_timer.time_left as int)

func _on_building_destroyed():
	building_destroyed_count += 1
	battle_info.set_percent_destruction(100.0 * building_destroyed_count as float / total_building_count as float)

func _on_BattleTimer_timeout():
	attack_state = AttackState.DONE
	map.disable()
