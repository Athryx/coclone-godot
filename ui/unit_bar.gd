tool
extends HudPanel
class_name UnitBar

class UnitBarUnit:
	extends Reference
	var unit: PackedScene
	var count: int
	
	# reference to the unit icon
	var icon = null
	
	func _init(unit: PackedScene, count: int):
		self.unit = unit
		self.count = count

# an dictionary of unit scene paths to UnitBarUnits
var units := {}

var current_unit = null

const UnitIcon = preload("res://ui/unit_icon.tscn")

onready var unit_container = $ScrollContainer/MarginContainer/HBoxContainer

func add_unit(unit: PackedScene, count: int):
	var unit_bar_unit := UnitBarUnit.new(unit, count)
	var icon = UnitIcon.instance()
	
	unit_bar_unit.icon = icon
	icon.unit = unit_bar_unit.unit
	
	icon.connect("clicked", self, "_on_unit_clicked", [unit_bar_unit])
	
	unit_container.add_child(icon)
	icon.set_text(String(unit_bar_unit.count))
	
	units[unit.resource_path] = unit_bar_unit

func _on_unit_clicked(unit: UnitBarUnit):
	current_unit = unit

func get_current_unit():
	if current_unit == null or current_unit.count == 0:
		return null
	
	current_unit.count -= 1
	current_unit.icon.set_text(String(current_unit.count))
	return current_unit.unit.instance()
