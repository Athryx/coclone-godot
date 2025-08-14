@tool
extends HudPanel
class_name UnitBar

class UnitBarUnit:
	extends RefCounted
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

@onready var unit_container = $ScrollContainer/MarginContainer/HBoxContainer

func add_unit(unit: PackedScene, count: int = 1):
	if units.has(unit.resource_path):
		var unit_bar_unit = units[unit.resource_path]
		unit_bar_unit.count += count
		unit_bar_unit.icon.set_text(str(unit_bar_unit.count))
	else:
		var unit_bar_unit := UnitBarUnit.new(unit, count)
		var icon = UnitIcon.instantiate()
		
		unit_bar_unit.icon = icon
		icon.unit = unit_bar_unit.unit
		
		icon.connect("clicked", Callable(self, "_on_unit_clicked").bind(unit_bar_unit))
		
		unit_container.add_child(icon)
		icon.set_text(str(unit_bar_unit.count))
		
		units[unit.resource_path] = unit_bar_unit

func _on_unit_clicked(unit: UnitBarUnit):
	current_unit = unit

func is_unit_selected():
	return current_unit != null and current_unit.count > 0

func get_current_unit_scene() -> PackedScene:
	if current_unit == null or current_unit.count == 0:
		return null
	
	return current_unit.unit

func get_current_unit():
	var unit := get_current_unit_scene()
	if unit == null:
		return null
	else:
		return unit.instantiate()

func dec_current_unit(remove_if_empty: bool = false):
	if current_unit != null:
		current_unit.count -= 1
		if current_unit.count == 0 and remove_if_empty:
			current_unit.icon.queue_free()
			units.erase(current_unit.unit.resource_path)
			current_unit = null
		else:
			current_unit.icon.set_text(str(current_unit.count))

func deselect_unit():
	if current_unit != null:
		current_unit.icon.release_button_focus()
		current_unit = null
