extends Node3D

@export var player: Player

const Attack = preload("res://game_view/attack/attack.tscn")
const BaseEditor = preload("res://game_view/base_editor/base_editor.tscn")

func _ready():
	PlayerData.player = player
	print(player.base_layout.buildings)
	add_child(Attack.instantiate())
