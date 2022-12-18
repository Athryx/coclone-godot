extends Spatial

export(Resource) var player

const Attack = preload("res://attack.tscn")
const BaseEditor = preload("res://base_editor/base_editor.tscn")

func _ready():
	PlayerData.player = player
	add_child(Attack.instance())
