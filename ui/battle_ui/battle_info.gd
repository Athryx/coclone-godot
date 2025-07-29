@tool
extends HudPanel
class_name BattleInfo

@onready var percent_destruction_label: Label = $PercentDestruction

@onready var time_remaining_label: Label = $TimeRemaing

func set_percent_destruction(percent: float):
	percent_destruction_label.text = ("%.2f" % percent) + " %"

func set_time_remaining(seconds: int):
	var display_minutes := seconds / 60
	var display_seconds := seconds % 60
	if display_minutes != 0:
		time_remaining_label.text = "%d m %d s" % [display_minutes, display_seconds]
	else:
		time_remaining_label.text = "%d s" % display_seconds

func _ready():
	set_percent_destruction(0.0)
	set_time_remaining(0)
