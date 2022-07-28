tool
extends HudPanel
class_name TroopBar

class TroopBarTroop:
	extends Reference
	var troop: PackedScene
	var count: int
	
	# reference to the unit icon
	var icon = null
	
	func _init(troop: PackedScene, count: int):
		self.troop = troop
		self.count = count

# an array of troop bar troops
var troops := []

var selected_troop_index = null

const UnitIcon = preload("res://ui/unit_icon.tscn")

const Gunner = preload("res://troops/gunner.tscn")

onready var troop_container = $ScrollContainer/MarginContainer/HBoxContainer

func _ready():
	if not Engine.editor_hint:
		# temp
		troops.push_back(TroopBarTroop.new(Gunner, 10))
		troops.push_back(TroopBarTroop.new(Gunner, 15))
		
		for i in range(troops.size()):
			var troop = troops[i]
			var icon = UnitIcon.instance()
			troop.icon = icon
			icon.unit = troop.troop
			
			icon.connect("clicked", self, "_on_troop_clicked", [i])
			
			troop_container.add_child(icon)
			icon.set_text(String(troop.count))

func _on_troop_clicked(index: int):
	selected_troop_index = index

func get_current_troop():
	if selected_troop_index == null:
		return null
	
	var current_troop: TroopBarTroop = troops[selected_troop_index]
	if current_troop.count == 0:
		return null
	
	current_troop.count -= 1
	current_troop.icon.set_text(String(current_troop.count))
	return current_troop.troop.instance()
